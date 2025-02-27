import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class ExchangeDB {
  final DateTime date;
  final DateTime createdAt;
  List<CurrencyDB>? currencies;

  ExchangeDB({required this.date, required this.createdAt, this.currencies});

  Map<String, dynamic> toJson() {
    return {
      "date": DateFormat("yyyy-MM-dd").format(date),
      "created_at": createdAt.toString(),
    };
  }

  factory ExchangeDB.fromMap(Map<String, dynamic> json) {
    return ExchangeDB(
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static const tableName = "exchange";
  static const sqlCreate = '''
    CREATE TABLE $tableName (
      date DATE PRIMARY KEY,
      created_at DATETIME NOT NULL
    );
  ''';
}

class CurrencyDB {
  final DateTime date;
  final String unit;
  final Decimal rate;

  CurrencyDB({required this.date, required this.rate, required this.unit});

  factory CurrencyDB.fromJson(Map<String, dynamic> json) {
    return CurrencyDB(
      date: DateTime.parse(json['date']),
      unit: json['unit'],
      rate: Decimal.parse(json['rate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "date": DateFormat("yyyy-MM-dd").format(date),
      "unit": unit,
      "rate": rate.toStringAsFixed(2),
    };
  }

  static const tableName = "currency";
  static const sqlCreate = '''
    CREATE TABLE $tableName (
      date DATE NOT NULL,
      unit VARCHAR(10) NOT NULL,
      rate VARCHAR(10) NOT NULL,
      PRIMARY KEY (date, unit),
      CONSTRAINT fk_date FOREIGN KEY(date) REFERENCES ${ExchangeDB.tableName}(date)
    );
    CREATE UNIQUE INDEX idx_date_unit ON $tableName(date, unit);
  ''';
}

class CurrentWrapper {
  final CurrencyDB? currency;
  final bool hasApiError;

  CurrentWrapper({this.currency, this.hasApiError = false});
}
