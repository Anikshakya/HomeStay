import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DB {
  static Database? _db;
  static Future<void> init() async {
    if (_db != null) return;
    Directory d = await getApplicationDocumentsDirectory();
    String path = p.join(d.path, 'hotel_mgmnt.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  static Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL,
        type TEXT,
        price REAL DEFAULT 0,
        beds INTEGER DEFAULT 1,
        ac INTEGER DEFAULT 0,
        active INTEGER DEFAULT 1,
        description TEXT,
        amenities TEXT,
        images TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE services(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL DEFAULT 0,
        active INTEGER DEFAULT 1,
        description TEXT,
        category TEXT,
        schedule TEXT,
        images TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        idImagePath TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE bookings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        roomId INTEGER,
        checkIn TEXT,
        checkOut TEXT,
        services TEXT,
        total REAL,
        status TEXT DEFAULT 'booked',
        createdAt TEXT
      )
    ''');
  }

  static Future<int> insert(String table, Map<String, dynamic> data) async =>
      await _db!.insert(table, data);
  static Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List whereArgs,
  }) async =>
      await _db!.update(table, data, where: where, whereArgs: whereArgs);
  static Future<int> delete(
    String table, {
    required String where,
    required List whereArgs,
  }) async => await _db!.delete(table, where: where, whereArgs: whereArgs);
  static Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?>? args,
  ]) async => await _db!.rawQuery(sql, args);
}
