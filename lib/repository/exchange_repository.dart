import 'dart:developer';

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
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
      whereArgs: [DateFormat("yyyy-MM-dd").format(date)],
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
      whereArgs: [DateFormat("yyyy-MM-dd").format(date), unit],
    );
    return CurrencyDB.fromJson(result[0]);
  }

  Future<void> save(ExchangeDB exchange) async {
    final db = await dbProvider.database;
    return db.transaction((txn) async {
      log("[DB] 베이스 데이터 저장");
      await txn.insert(exchangeTableName, exchange.toJson());
      if (exchange.currencies?.isNotEmpty ?? false) {
        log('[DB] 나라별 환율정보 저장');
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
    final result = await db.query(currencyTableName,
        columns: ["date", "rate", "unit"], orderBy: "date desc", limit: limit);
    if (result.isEmpty) return [];
    return result.map((e) => CurrencyDB.fromJson(e)).toList();
  }

  Future<ExchangeDB?> getExchangeRateByDateFromApi(DateTime date) async {
    late final List<dynamic> result;
    final url =
        '$apiUrl?authkey=$apiKey&searchdate=${DateFormat('yyyyMMdd').format(date)}&data=AP01';
    try {
      final res = await http.get(
        Uri.parse(url),
      );
      result = convert.jsonDecode(convert.utf8.decode(res.bodyBytes))
          as List<dynamic>;
    } catch (e) {
      log("[에러] ${e.toString()}");
      return null;
    }
    if (result.isEmpty) return null;

    List<CurrencyDB> currencies = [];
    for (var item in result) {
      currencies.add(
        CurrencyDB(
          date: date,
          rate: Decimal.parse((item['tts'] as String).replaceAll(",", "")),
          unit: item['cur_unit'],
        ),
      );
    }
    return ExchangeDB(
      date: date,
      currencies: currencies,
      createdAt: DateTime.now(),
    );
  }
}
