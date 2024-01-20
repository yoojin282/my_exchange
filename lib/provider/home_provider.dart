import 'package:flutter/material.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/service/exchange_service.dart';

class HomeProvider with ChangeNotifier {
  HomeProvider() {
    _textController = TextEditingController(text: "0");
    _load();
  }
  final _service = getIt<ExchangeService>();

  late TextEditingController _textController;
  String _currentUnit = 'THB';
  double _rate = 0;
  int _totalAmount = 0;
  bool _loading = true;
  bool _reverse = false;
  bool _error = false;

  TextEditingController get textController => _textController;
  String get currentUnit => _currentUnit;
  double get rate => _rate;
  int get totalAmount => _totalAmount;

  bool get isLoading => _loading;
  bool get isReverse => _reverse;
  bool get hasError => _error;

  void _load() {
    _loading = false;
    notifyListeners();
    setCurrentUnit(_currentUnit);
  }

  void onInputChanged() {
    _calculate();
  }

  void setCurrentUnit(String unit) {
    _service.getCurrency(_currentUnit).then((value) {
      _loading = false;
      if (value == null) {
        _error = true;
        notifyListeners();
        return;
      }
      _currentUnit = value.unit;
      _rate = value.rate;
      _calculate();
    });
  }

  void toggleReverse() {
    _reverse = !_reverse;
    _calculate();
  }

  void _calculate() {
    double realRate = _rate * (_currentUnit.endsWith("(100)") ? 0.01 : 1);
    final strInput = _textController.text.replaceAll(",", "");
    int input = 0;
    if (strInput.isNotEmpty) {
      input = int.parse(strInput);
    }
    double result = _reverse ? input / realRate : input * realRate;
    _totalAmount = result.toInt();
    notifyListeners();
  }
}
