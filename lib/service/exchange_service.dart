import 'dart:io';

import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/model/db_models.dart';
import 'package:my_exchange/repository/exchange_repository.dart';

const maxRetryCount = 5;

class ExchangeService {
  final _repository = getIt<ExchangeRepository>();

  Future<CurrencyDB?> getCurrency(String unit) async {
    DateTime date = _getAvailableDate();
    for (int i = 0; i < maxRetryCount; i++) {
      final currency = await _getCurrency(
        date.add(Duration(days: i)),
        unit,
      );
      if (currency != null) return currency;
    }
    return Future.value(null);
  }

  Future<CurrencyDB?> _getCurrency(DateTime date, String unit) async {
    if (await _repository.isFetchedByDate(date)) {
      return _repository.selectByDateAndUnit(date, unit);
    }
    final result = await _getExchangeDataFromApi(date);
    if (result != null) {
      await _repository.save(result);
      return await _repository.selectByDateAndUnit(date, unit);
    }
    return null;
  }

  Future<ExchangeDB?> _getExchangeDataFromApi(DateTime date) async {
    ExchangeDB? result;
    for (var i = 0; i < maxRetryCount; i++) {
      result = await _repository.getExchangeRateByDateFromApi(date);
      if (result != null) return result;
      sleep(const Duration(milliseconds: 500));
    }
    return null;
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
}
