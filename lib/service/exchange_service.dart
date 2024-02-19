import 'dart:developer';
import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/model/db_models.dart';
import 'package:my_exchange/repository/exchange_repository.dart';

const maxRetryCount = 5;

class ExchangeService {
  final _repository = getIt<ExchangeRepository>();

  Future<CurrencyDB?> getCurrency(String unit) async {
    DateTime date = _getAvailableDate();
    for (int i = 0; i < maxRetryCount; i++) {
      final currentDate = date.add(Duration(days: -i));
      log("[환율] 로딩.. (${i + 1}차: ${DateFormat("yyyy-MM-dd").format(currentDate)})");
      final currency = await _getCurrency(
        currentDate,
        unit,
      );
      if (currency != null) return currency;
    }
    return Future.value(null);
  }

  Future<CurrencyDB?> _getCurrency(DateTime date, String unit) async {
    if (await _repository.isExistsByDate(date)) {
      log("[DB] DB에서 환율정보 가져오기. date: $date, unit: $unit");
      return _repository.selectByDateAndUnit(date, unit);
    }
    log('[API] API 환율정보 불러오기');
    final result = await _repository.getExchangeRateByDateFromApi(date);
    if (result != null) {
      await _repository.save(result);
      return await _repository.selectByDateAndUnit(date, unit);
    }
    return null;
  }

  Future<List<CurrencyDB>> getCurrenciesByUnit(String unit) {
    log('[DB] 일주일간 데이터 가져오기. unit: $unit');

    if (kDebugMode) {
      final DateTime now = DateTime.now();
      final random = math.Random();
      final margin = unit == "THB"
          ? 2
          : unit == "USD"
              ? 100
              : 50;
      final base = unit == "THB"
          ? 36
          : unit == "USD"
              ? 1300
              : 950;
      return Future.delayed(
        const Duration(seconds: 1),
        () => [
          for (int i = 0; i < 7; i++)
            CurrencyDB(
              date: now.add(Duration(days: (i - 7))),
              rate: Decimal.parse(
                  (base + (random.nextDouble() * margin)).toStringAsFixed(2)),
              unit: unit,
            )
        ],
      );
    }
    return _repository.selectListByUnitLimit(unit, limit: 7);
  }

  DateTime _getAvailableDate() {
    DateTime now = DateTime.now();
    int day = now.weekday;
    if (day == DateTime.sunday) {
      return now.add(const Duration(days: -2));
    } else if (day == DateTime.saturday) {
      return now.add(const Duration(days: -1));
    }
    return now;
  }
}
