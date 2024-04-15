import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _database;
  static final DBHelper instance = DBHelper._();

  DBHelper._();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'health_device.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE readings(id INTEGER PRIMARY KEY, temperature REAL, bpm INTEGER, spo2 INTEGER, timestamp INTEGER)',
        );
      },
    );
  }

  Future<void> insertReading(double temperature, int bpm, int spo2) async {
    final db = await database;
    await db.insert(
      'readings',
      {
        'temperature': temperature,
        'bpm': bpm,
        'spo2': spo2,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getReadings() async {
    final db = await database;
    return db.query('readings', orderBy: 'timestamp DESC');
  }
}
