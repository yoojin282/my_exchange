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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

const String lastDataKey = "last_exchange_data";
const String apiKey = 'F4FQRaV47zxbP6l86JiOXnV0HYT5PVAB';
final Uri apiUrl = Uri.parse(
    'https://www.koreaexim.go.kr/site/program/financial/exchangeJSON');
const List<String> units = ['USD', 'THB'];

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
  DateTime? _date;
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
    final String? lastDataString = prefs.getString(lastDataKey);
    _ExchangeData data;
    if (lastDataString != null && lastDataString.isNotEmpty) {
      data = _ExchangeData.fromJsonString(lastDataString);
      DateTime now = DateTime.now();
      DateTime fetchDate = data.fetchDate;
      if (fetchDate.year == now.year &&
          fetchDate.month == now.month &&
          fetchDate.day == now.day) {
        setState(() {
          _date = data.date;
          _rate = data.rate;
          _ready = true;
        });
        return;
      }
    }
    DateTime date = _getAvailableDate();
    data = await _loadExchangeRate(_currentUnit, date);
    setState(() {
      _date = data.date;
      _rate = data.rate;
      _ready = true;
    });
    prefs.setString(lastDataKey, data.toJsonString());
  }

  void _changeUnit(String unit) {
    setState(() {
      _ready = false;
    });
    _loadExchangeRate(unit, _date!).then((data) {
      setState(() {
        _date = data.date;
        _rate = data.rate;
        _currentUnit = data.unit;
        _ready = true;
      });
      Navigator.pop(context);
    });
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

  Future<_ExchangeData> _loadExchangeRate(String unit, DateTime date) async {
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
      return _loadExchangeRate(unit, date.add(const Duration(days: -1)));
    }
    for (var item in result) {
      if (item['result'] == 1 && item['cur_unit'] == unit) {
        _animationController.stop();
        return _ExchangeData(
            date: date,
            rate: item['tts'],
            unit: unit,
            fetchDate: DateTime.now());
      }
    }
    throw Exception("해당 환율이 존재하지 않습니다.");
  }

  void _calculate() {
    double rate = double.parse(_rate.replaceAll(",", ""));
    final strInput = _controller.text;
    int input = 0;
    if (strInput.isNotEmpty) {
      input = int.parse(_controller.text);
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
                onTap: _currentUnit == unit ? null : () => _changeUnit(unit),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_date != null)
                    Text(
                      '환율발표: ${DateFormat('MM월 dd일').format(_date!)}',
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
              const SizedBox(
                height: 8,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _reverse ? "KRW" : _currentUnit,
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
                        _reverse ? _currentUnit : "KRW",
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
                        _currentUnit,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                      ),
                    ]),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                          hintText: "원하시는 금액을 입력하세요.",
                          suffix: Text(_reverse ? 'KRW' : _currentUnit),
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
              Expanded(
                child: Center(
                  child: Text(
                    '$_amount ${_reverse ? _currentUnit : '원'}',
                    style: const TextStyle(fontSize: 48),
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
  final String rate;
  final String unit;
  final DateTime fetchDate;

  _ExchangeData({
    required this.date,
    required this.rate,
    required this.unit,
    required this.fetchDate,
  });

  String toJsonString() {
    return convert.jsonEncode({
      'date': DateFormat("yyyy-MM-dd").format(date),
      'rate': rate,
      'unit': unit,
      'fetch_date': DateFormat("yyyy-MM-dd").format(fetchDate)
    });
  }

  factory _ExchangeData.fromJsonString(String jsonString) {
    Map<String, dynamic> json = convert.jsonDecode(jsonString);
    return _ExchangeData(
      date: DateTime.parse(json['date']),
      rate: json['rate'],
      unit: json['unit'],
      fetchDate: DateTime.parse(json['fetch_date']),
    );
  }
}
