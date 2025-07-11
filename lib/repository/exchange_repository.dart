import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:my_exchange/constants.dart';
import 'package:my_exchange/model/db_models.dart';
import 'package:my_exchange/service/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class ExchangeRepository {
  final dbProvider = DatabaseService.provider;
  final currencyTableName = CurrencyDB.tableName;
  final exchangeTableName = ExchangeDB.tableName;

  Future<bool> isExistsByDate(DateTime date) async {
    final db = await dbProvider.database;
    final result = await db.query(
      exchangeTableName,
      columns: ['count(*)'],
      where: "date = ?",
      whereArgs: [dateFormat.format(date)],
    );
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<CurrencyDB> selectByDateAndUnit(DateTime date, String unit) async {
    final db = await dbProvider.database;
    final result = await db.query(
      currencyTableName,
      columns: ["date", "unit", "rate"],
      where: "date = ? and unit = ?",
      whereArgs: [dateFormat.format(date), unit],
    );
    return CurrencyDB.fromJson(result[0]);
  }

  Future<void> save(ExchangeDB exchange) async {
    final db = await dbProvider.database;
    return db.transaction((txn) async {
      logger.d("[DB] 베이스 데이터 저장");
      await txn.insert(exchangeTableName, exchange.toJson());
      if (exchange.currencies?.isNotEmpty ?? false) {
        logger.d('[DB] 나라별 환율정보 저장');
        for (final currency in exchange.currencies!) {
          await txn.insert(currencyTableName, currency.toJson());
        }
      }
    });
  }

  Future<List<CurrencyDB>> selectListByUnitLimit(
    String unit, {
    required int limit,
  }) async {
    final db = await dbProvider.database;
    final result = await db.query(
      currencyTableName,
      columns: ["date", "rate", "unit"],
      where: "unit = ?",
      whereArgs: [unit],
      orderBy: "date desc",
      limit: limit,
    );
    if (result.isEmpty) return [];
    final list = result.map((e) => CurrencyDB.fromJson(e)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<ExchangeDB?> getExchangeRateByDateFromApi(DateTime date) async {
    late final Map<String, dynamic> result;
    final paramDate = dateFormat.format(date);
    final queryParams = {'symbols': availableUnits.join(','), 'base': baseUnit};
    final uri = Uri.https(
      apiHost,
      '/exchangerates_data/$paramDate',
      queryParams,
    );

    logger.d("[API] 요청: $uri");
    try {
      final res = await http
          .get(uri, headers: {'apikey': Constants.apiKey})
          .timeout(Duration(seconds: 5));
      if (res.statusCode != 200) {
        logger.e("[API] 에러: $uri ${res.statusCode}\n${res.body}");
        return null;
      }
      result = convert.jsonDecode(convert.utf8.decode(res.bodyBytes));
      logger.d("[API] 응답: $result");
    } catch (e) {
      logger.e("[API] 에러: ${e.toString()}");
      rethrow;
    }

    if (!(result['success'] ?? false)) return null;

    List<CurrencyDB> currencies = [];
    for (var item in (result['rates'] as Map<String, dynamic>).entries) {
      final rate = 1 / item.value;
      currencies.add(
        CurrencyDB(
          date: date,
          rate: Decimal.parse(
            rate > 99 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2),
          ),
          unit: item.key,
        ),
      );
    }
    return ExchangeDB(
      date: date,
      currencies: currencies,
      createdAt: DateTime.now(),
    );
  }

  Future<CurrencyDB?> selectLastByUnit(String unit) async {
    final db = await dbProvider.database;
    final result = await db.query(
      currencyTableName,
      columns: ["date", "unit", "rate"],
      where: "unit = ?",
      whereArgs: [unit],
      orderBy: "date desc",
      limit: 1,
    );
    if (result.isEmpty) return null;
    return CurrencyDB.fromJson(result[0]);
  }
}
