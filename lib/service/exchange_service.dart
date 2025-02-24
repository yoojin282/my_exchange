import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/model/db_models.dart';
import 'package:my_exchange/repository/exchange_repository.dart';

const maxRetryCount = 5;

class ExchangeService {
  final _repository = getIt<ExchangeRepository>();

  Future<CurrencyDB?> getCurrency(String unit) async {
    DateTime date = DateTime.now();
    for (int i = 0; i < maxRetryCount; i++) {
      final currentDate = date.add(Duration(days: -i));
      log(
        "[환율] 로딩.. (${i + 1}차: ${DateFormat("yyyy-MM-dd").format(currentDate)})",
      );
      final currency = await _getCurrency(currentDate, unit);
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
      log("[DB] 불러온 API 환율 저장");
      await _repository.save(result);
      return await _repository.selectByDateAndUnit(date, unit);
    } else {
      // DB 에서 마지막 날짜 환율 가져오기
      log("[DB] DB 에서 마지막 날짜 환율 가져오기. unit: $unit");
      final result = await _repository.selectLastByUnit(unit);
      return result;
    }
  }

  Future<List<CurrencyDB>> getCurrenciesByUnit(String unit) {
    log('[DB] 일주일간 데이터 가져오기. unit: $unit');
    return _repository.selectListByUnitLimit(unit, limit: 7);
  }
}
