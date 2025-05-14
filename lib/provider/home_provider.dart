import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
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
  Decimal _rate = Decimal.parse('0');
  DateTime _date = DateTime.now();
  int _totalAmount = 0;
  bool _loading = true;
  bool _reverse = false;
  bool _error = false;

  TextEditingController get textController => _textController;
  String get currentUnit => _currentUnit;
  Decimal get rate => _rate;
  int get totalAmount => _totalAmount;
  DateTime get date => _date;

  bool get isLoading => _loading;
  bool get isReverse => _reverse;
  bool get hasError => _error;

  void _load() {
    _loading = true;
    setCurrentUnit(_currentUnit).then((_) {
      _loading = false;
    });
  }

  void reload() {
    _error = false;
    _load();
  }

  void onInputChanged() {
    final inputText = _textController.text.replaceAll(",", "");
    if (inputText.isNotEmpty) {
      _textController.text = NumberFormat(
        "###,###,###",
      ).format(int.parse(inputText));
    }
    _calculate();
  }

  Future<void> setCurrentUnit(String unit) async {
    return _service.getCurrency(unit).then((value) {
      _loading = false;
      if (value == null || value.currency == null || value.hasApiError) {
        _error = true;
        notifyListeners();
        return;
      }

      final currency = value.currency!;
      _date = currency.date;
      _currentUnit = currency.unit;
      _rate = currency.rate;
      _textController.text = "0";
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
    Decimal sum = _getInputPrice() + Decimal.fromInt(amount);
    _textController.text = DecimalFormatter(
      NumberFormat("###,###,###"),
    ).format(sum);
    _calculate();
  }

  void _calculate() {
    Decimal realRate =
        _rate * Decimal.parse(_currentUnit.endsWith("(100)") ? "0.01" : "1");
    Decimal input = _getInputPrice();

    Decimal result =
        _reverse
            ? (input / realRate).toDecimal(scaleOnInfinitePrecision: 0)
            : input * realRate;
    _totalAmount = result.toBigInt().toInt();
    notifyListeners();
  }

  Decimal _getInputPrice() {
    final strInput = _textController.text.replaceAll(",", "");
    Decimal input = Decimal.zero;
    if (strInput.isNotEmpty) {
      input = Decimal.parse(strInput);
    }
    return input;
  }
}
