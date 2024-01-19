import 'dart:developer';

import 'package:my_exchange/model/db_models.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  final version = 1;
  final String _dbName = "exchange.db";
  static final DatabaseService provider = DatabaseService();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _createDatabase();
    return _database!;
  }

  Future<void> reset() async {
    log('[DB] 로컬 DB 삭제');
    await deleteDatabaseFile();
  }

  Future<void> deleteDatabaseFile() async {
    String path = join(await getDatabasesPath(), _dbName);
    final exists = await databaseExists(path);
    if (exists) {
      deleteDatabase(path);
    }
  }

  Future<Database> _createDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _onCreate(Database database, int version) async {
    log("[DB] Scheme 생성");
    await database.execute(ExchangeDB.sqlCreate);
    await database.execute(CurrencyDB.sqlCreate);
  }

  void _onUpgrade(Database database, int oldVersion, int newVersion) {
    if (newVersion > oldVersion) {
      // migration here
    }
  }
}
