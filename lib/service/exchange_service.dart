import 'package:my_exchange/constants.dart';
import 'package:my_exchange/get_it.dart';
import 'package:my_exchange/model/db_models.dart';
import 'package:my_exchange/repository/exchange_repository.dart';

const maxRetryCount = 2;

class ExchangeService {
  final _repository = getIt<ExchangeRepository>();

  Future<CurrentWrapper?> getCurrency(String unit) async {
    DateTime date = DateTime.now().add(Duration(hours: -9));
    for (int i = 0; i < maxRetryCount; i++) {
      final currentDate = date.add(Duration(days: -i));
      logger.d("[환율] 로딩 (${i + 1}차: ${dateFormat.format(currentDate)})");
      final result = await _getCurrency(currentDate, unit);
      if (result.currency != null) return result;
    }
    return Future.value(null);
  }

  Future<CurrentWrapper> _getCurrency(DateTime date, String unit) async {
    if (await _repository.isExistsByDate(date)) {
      logger.d(
        "[DB] DB에서 환율정보 가져오기. date: ${dateFormat.format(date)}, unit: $unit",
      );
      return _repository
          .selectByDateAndUnit(date, unit)
          .then((value) => CurrentWrapper(currency: value));
    }
    logger.d('[API] API 환율정보 불러오기');
    try {
      final result = await _repository.getExchangeRateByDateFromApi(date);
      if (result != null) {
        logger.d("[DB] 불러온 API 환율 저장");
        await _repository.save(result);
        return _repository
            .selectByDateAndUnit(date, unit)
            .then((value) => CurrentWrapper(currency: value));
      } else {
        // DB 에서 마지막 날짜 환율 가져오기
        logger.d("[DB] DB 에서 마지막 날짜 환율 가져오기. unit: $unit");
        return _repository
            .selectLastByUnit(unit)
            .then(
              (value) => CurrentWrapper(currency: value, hasApiError: true),
            );
      }
    } catch (e) {
      logger.e("[API] 환율정보 불러오기 실패: $e");
      return CurrentWrapper(hasApiError: true);
    }
  }

  Future<List<CurrencyDB>> getCurrenciesByUnit(String unit) {
    logger.d('[DB] 일주일간 데이터 가져오기. unit: $unit');
    return _repository.selectListByUnitLimit(unit, limit: 7);
  }
}
