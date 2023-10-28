import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

const String apiKey = 'F4FQRaV47zxbP6l86JiOXnV0HYT5PVAB';
final Uri apiUrl = Uri.parse(
    'https://www.koreaexim.go.kr/site/program/financial/exchangeJSON');
const List<String> units = ['USD', 'THB'];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final TextEditingController _controller;

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
    _initData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initData() async {
    _ExchangeData data =
        await _loadExchangeRate(_currentUnit, _getAvailableDate());
    setState(() {
      _date = data.date;
      _rate = data.rate;
      _ready = true;
    });
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
    final result = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    if (result.isEmpty) {
      return _loadExchangeRate(unit, date.add(const Duration(days: -1)));
    }
    for (var item in result) {
      if (item['result'] == 1 && item['cur_unit'] == unit) {
        return _ExchangeData(date: date, rate: item['tts'], unit: unit);
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
    _calculate();
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
        title: const Text("환전정보"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                      const Icon(Icons.chevron_right),
                      Text(
                        _reverse ? _currentUnit : "KRW",
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horizontal_circle),
                        onPressed: () => _toggleReverse(),
                      )
                    ],
                  ),
                  TextButton(
                    onPressed: () => _showUnitDialog(context),
                    child: Text(
                      _currentUnit,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
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
                          hintText:
                              "원하시는 금액을 입력하세요. (${_reverse ? 'KRW' : _currentUnit})",
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
              style: const TextStyle(fontSize: 24),
            ),
            if (selected) ...[
              const SizedBox(
                width: 24,
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

  _ExchangeData({required this.date, required this.rate, required this.unit});
}

// class _ExchangeRate {
//   final int result;
//   final String unitCode;
//   final String unitName;
//   final String rate;

//   _ExchangeRate({
//     required this.result,
//     required this.unitCode,
//     required this.unitName,
//     required this.rate,
//   });

//   factory _ExchangeRate.fromJson(Map<String, dynamic> json) {
//     return _ExchangeRate(
//       result: json['result'],
//       unitCode: json['cur_unit'],
//       unitName: json['cur_nm'],
//       rate: json['ttb'],
//     );
//   }
// }
