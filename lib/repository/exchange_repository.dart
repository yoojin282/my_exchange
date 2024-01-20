import 'dart:developer';

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

  Future<bool> isFetchedByDate(DateTime date) async {
    final db = await dbProvider.database;
    final result = await db.query(
      exchangeTableName,
      columns: ['count(*)'],
      where: "date = ?",
      whereArgs: [DateFormat("yyyy-MM-dd").format(date)],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<CurrencyDB> selectByDateAndUnit(DateTime date, String unit) async {
    final db = await dbProvider.database;
    final result = await db.query(
      currencyTableName,
      where: "date = ? and unit = ?",
      whereArgs: [DateFormat("yyyy-MM-dd").format(date), unit],
    );
    return CurrencyDB.fromJson(result[0]);
  }

  Future<void> save(ExchangeDB exchange) async {
    final db = await dbProvider.database;
    db.transaction((txn) async {
      await txn.insert(exchangeTableName, exchange.toJson());
      if (exchange.currencies?.isNotEmpty ?? false) {
        for (final currency in exchange.currencies!) {
          await txn.insert(currencyTableName, currency.toJson());
        }
      }
    });
  }

  Future<ExchangeDB?> getExchangeRateByDateFromApi(DateTime date) async {
    late final List<dynamic> result;
    try {
      final res = await http.get(
        apiUrl.replace(
          queryParameters: {
            'authkey': apiKey,
            'searchdate': DateFormat('yyyyMMdd').format(date),
            'data': 'AP01',
          },
        ),
      );
      result = convert.jsonDecode(convert.utf8.decode(res.bodyBytes))
          as List<dynamic>;
    } catch (e) {
      log("[에러] ${e.toString()}");
      return null;
    }
    List<CurrencyDB> currencies = [];
    for (var item in result) {
      currencies.add(
          CurrencyDB(date: date, rate: item['tts'], unit: item['cur_unit']));
    }
    return ExchangeDB(
      date: date,
      currencies: currencies,
      createdAt: DateTime.now(),
    );
  }
}
