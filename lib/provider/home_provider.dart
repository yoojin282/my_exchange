import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/service/exchange_service.dart';

class HomeProvider with ChangeNotifier {
  HomeProvider() {
    _textController = TextEditingController();
    _load();
  }
  final _service = getIt<ExchangeService>();

  late TextEditingController _textController;
  String _currentUnit = 'THB';
  double _rate = 0;
  DateTime _date = DateTime.now();
  int _totalAmount = 0;
  bool _loading = true;
  bool _reverse = false;
  bool _error = false;

  TextEditingController get textController => _textController;
  String get currentUnit => _currentUnit;
  double get rate => _rate;
  int get totalAmount => _totalAmount;
  DateTime get date => _date;

  bool get isLoading => _loading;
  bool get isReverse => _reverse;
  bool get hasError => _error;

  void _load() {
    _loading = false;
    notifyListeners();
    setCurrentUnit(_currentUnit);
  }

  void onInputChanged() {
    final inputText = _textController.text.replaceAll(",", "");
    if (inputText.isNotEmpty) {
      _textController.text =
          NumberFormat("###,###,###").format(int.parse(inputText));
    }
    _calculate();
  }

  void setCurrentUnit(String unit) {
    _service.getCurrency(unit).then((value) {
      _loading = false;
      if (value == null) {
        _error = true;
        notifyListeners();
        return;
      }
      _date = value.date;
      _currentUnit = value.unit;
      _rate = value.rate;
      _calculate();
    });
  }

  void toggleReverse() {
    _reverse = !_reverse;
    _textController.text = "0";
    _calculate();
  }

  void clearInput() {
    _textController.clear();
    _totalAmount = 0;
    notifyListeners();
  }

  void addPrice(int amount) {
    int sum = _getInputPrice() + amount;
    _textController.text = NumberFormat("###,###,###").format(sum);
    _calculate();
  }

  void _calculate() {
    double realRate = _rate * (_currentUnit.endsWith("(100)") ? 0.01 : 1);
    int input = _getInputPrice();
    double result = _reverse ? input / realRate : input * realRate;
    _totalAmount = result.toInt();
    notifyListeners();
  }

  int _getInputPrice() {
    final strInput = _textController.text.replaceAll(",", "");
    int input = 0;
    if (strInput.isNotEmpty) {
      input = int.parse(strInput);
    }
    return input;
  }
}
