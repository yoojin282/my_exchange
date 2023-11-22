import 'dart:convert' as convert;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Exchange',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.noScaling,
        ),
        child: child!,
      ),
      home: const MainScreen(),
    );
  }
}

const String lastDataKey = "last_exchange_data";
const String apiKey = 'F4FQRaV47zxbP6l86JiOXnV0HYT5PVAB';
final Uri apiUrl = Uri.parse(
    'https://www.koreaexim.go.kr/site/program/financial/exchangeJSON');
const List<String> units = ['USD', 'THB', "JPY(100)"];
const shortcuts = [20, 100, 500, 1000, 5000];
const reverseShortcuts = [1000, 5000, 10000, 50000, 100000];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _animationController;

  String _currentUnit = 'THB';
  String _amount = '0';
  String _rate = '0';
  bool _ready = false;
  bool _reverse = false;
  // DateTime? _date;
  _ExchangeData? _data;
  // final DateTime _date = DateTime.now().subtract(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _initData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initData() async {
    if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastDataString = prefs.getString(lastDataKey);

    try {
      if (lastDataString?.isNotEmpty ?? false) {
        _data = _ExchangeData.fromJsonString(lastDataString!);
        DateTime now = DateTime.now();
        DateTime fetchDate = _data!.fetchDate;
        if (fetchDate.year == now.year &&
            fetchDate.month == now.month &&
            fetchDate.day == now.day) {
          setState(() {
            // _date = _data.date;
            _ready = true;
          });
          _changeUnit(_currentUnit);
          return;
        }
      }
    } catch (e) {
      prefs.remove(lastDataKey);
    }
    DateTime date = _getAvailableDate();
    _data = await _loadExchangeRate(date);
    _changeUnit(_currentUnit);
    prefs.setString(lastDataKey, _data!.toJsonString());
  }

  void _changeUnit(String unit) {
    for (var item in _data!.currencies) {
      if (item.unit == unit) {
        setState(() {
          _ready = true;
          _rate = item.rate;
          _currentUnit = item.unit;
          _amount = "0";
          _controller.clear();
        });
      }
    }
  }

  DateTime _getAvailableDate() {
    DateTime now = DateTime.now();
    int day = now.day;
    if (day == DateTime.sunday) {
      return now.add(const Duration(days: -2));
    } else if (day == DateTime.saturday) {
      return now.add(const Duration(days: -1));
    }
    return now;
  }

  Future<_ExchangeData> _loadExchangeRate(DateTime date) async {
    final res = await http.get(
      apiUrl.replace(
        queryParameters: {
          'authkey': apiKey,
          'searchdate': DateFormat('yyyyMMdd').format(date),
          'data': 'AP01',
        },
      ),
    );
    final result =
        convert.jsonDecode(convert.utf8.decode(res.bodyBytes)) as List;
    if (result.isEmpty) {
      return _loadExchangeRate(date.add(const Duration(days: -1)));
    }
    List<_Currency> currencies = [];
    for (var item in result) {
      currencies.add(_Currency(rate: item['tts'], unit: item['cur_unit']));
    }
    return _ExchangeData(
      date: date,
      currencies: currencies,
      fetchDate: date,
    );
  }

  void _calculate() {
    double rate = double.parse(_rate.replaceAll(",", "")) *
        (_currentUnit.endsWith("(100)") ? 0.01 : 1);
    final strInput = _controller.text.replaceAll(",", "");
    int input = 0;
    if (strInput.isNotEmpty) {
      input = int.parse(strInput);
    }
    double result = _reverse ? input / rate : input * rate;
    setState(() {
      _amount = NumberFormat("###,###,###").format(result);
    });
  }

  void _toggleReverse() {
    setState(() {
      _reverse = !_reverse;
    });
    _controller.clear();
    _amount = '0';
  }

  void _showUnitDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var unit in units)
              InkWell(
                onTap: _currentUnit == unit
                    ? null
                    : () {
                        _changeUnit(unit);
                        Navigator.pop(context);
                      },
                child: _UnitItem(
                  unit: unit,
                  selected: _currentUnit == unit,
                ),
              ),
          ],
        );
      },
    );
  }

  void _onInputChange(String? value) {
    if (value == null) return;
    _calculate();
  }

  void _clearInput() {
    _controller.clear();
    _calculate();
  }

  void _onTabPrice(int price) {
    final strInput = _controller.text.replaceAll(",", "");
    int input = 0;
    if (strInput.isNotEmpty) {
      input = int.parse(strInput);
    }
    input += price;
    _controller.text = NumberFormat("###,###,###").format(input);
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("환율여행"),
        centerTitle: true,
        actions: [
          if (!_ready) ...[
            RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
              child: const Icon(Icons.loop),
            ),
            const SizedBox(
              width: 16,
            ),
          ]
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_data != null)
                      Text(
                        '환율발표: ${DateFormat('MM월 dd일').format(_data!.date)}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    Text(
                      '환율: $_rate 원',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _reverse
                              ? "KRW"
                              : _currentUnit.replaceAll("(100)", ""),
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_horizontal_circle),
                          onPressed: () => _toggleReverse(),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          _reverse
                              ? _currentUnit.replaceAll("(100)", "")
                              : "KRW",
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => _showUnitDialog(context),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        padding: const EdgeInsets.only(right: 5, left: 16),
                      ),
                      child: Row(children: [
                        Text(
                          _currentUnit.replaceAll("(100)", ""),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                        ),
                      ]),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    int amount =
                        _reverse ? reverseShortcuts[index] : shortcuts[index];
                    return _ShortcutPrice(
                      amount: amount,
                      onTab: () => _onTabPrice(amount),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemCount:
                      _reverse ? reverseShortcuts.length : shortcuts.length,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CommaSeparatorInputFormatter(),
                        ],
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                            hintText: "원하시는 금액을 입력하세요.",
                            suffix: Text(_reverse
                                ? 'KRW'
                                : _currentUnit.replaceAll("(100)", "")),
                            suffixIcon: _controller.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: _clearInput,
                                    icon: const Icon(
                                      Icons.cancel,
                                    ),
                                  )),
                        textInputAction: TextInputAction.done,
                        onChanged: _ready ? _onInputChange : null,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      '$_amount ${_reverse ? _currentUnit.replaceAll("(100)", "") : '원'}',
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutPrice extends StatelessWidget {
  const _ShortcutPrice({
    required this.amount,
    required this.onTab,
  });

  final int amount;
  final void Function() onTab;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 10,
        ),
        side: const BorderSide(
          color: Colors.blueAccent,
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          color: Colors.blueAccent,
        ),
      ),
      onPressed: onTab,
      child: Text(
        "+ ${NumberFormat("###,###,###").format(amount)}",
      ),
    );
  }
}

class _UnitItem extends StatelessWidget {
  const _UnitItem({required this.unit, required this.selected});

  final String unit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        child: Row(
          children: [
            Text(
              unit,
              style: const TextStyle(fontSize: 20),
            ),
            if (selected) ...[
              const SizedBox(
                width: 20,
              ),
              const Icon(
                Icons.done,
              ),
            ]
          ],
        ));
  }
}

class _ExchangeData {
  final DateTime date;
  final List<_Currency> currencies;
  final DateTime fetchDate;

  _ExchangeData({
    required this.date,
    required this.currencies,
    required this.fetchDate,
  });

  String toJsonString() {
    return convert.jsonEncode({
      'date': DateFormat("yyyy-MM-dd").format(date),
      'currencies':
          convert.jsonEncode(currencies.map((e) => e.toJsonString()).toList()),
      'fetch_date': DateFormat("yyyy-MM-dd").format(fetchDate)
    });
  }

  factory _ExchangeData.fromJsonString(String jsonString) {
    Map<String, dynamic> json = convert.jsonDecode(jsonString);
    final currencies = convert.jsonDecode(json['currencies']) as List;
    return _ExchangeData(
      date: DateTime.parse(json['date']),
      currencies: currencies.map((e) => _Currency.fromJsonString(e)).toList(),
      fetchDate: DateTime.parse(json['fetch_date']),
    );
  }
}

class _Currency {
  final String rate;
  final String unit;

  _Currency({required this.rate, required this.unit});

  String toJsonString() {
    return convert.jsonEncode({
      'rate': rate,
      'unit': unit,
    });
  }

  factory _Currency.fromJsonString(String jsonString) {
    Map<String, dynamic> json = convert.jsonDecode(jsonString);
    return _Currency(
      rate: json['rate'],
      unit: json['unit'],
    );
  }
}

class CommaSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ",";

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: "");
    }

    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');
    if (oldValue.text.endsWith(separator) &&
        oldValue.text.length == newValue.text.length + 1) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    // Only process if the old value and new value are different
    if (oldValueText != newValueText) {
      int selectionIndex =
          newValue.text.length - newValue.selection.extentOffset;
      final chars = newValueText.split('');

      String newString = '';
      for (int i = chars.length - 1; i >= 0; i--) {
        if ((chars.length - 1 - i) % 3 == 0 && i != chars.length - 1) {
          newString = separator + newString;
        }
        newString = chars[i] + newString;
      }

      return TextEditingValue(
        text: newString.toString(),
        selection: TextSelection.collapsed(
          offset: newString.length - selectionIndex,
        ),
      );
    }
    return newValue;
  }
}
