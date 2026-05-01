import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weight_measurement.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'balanca.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE measurements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          weight_kg REAL NOT NULL,
          impedance_ohm INTEGER,
          body_fat_pct REAL,
          muscle_pct REAL,
          bone_kg REAL,
          water_pct REAL,
          bmi REAL,
          bmr REAL,
          visceral_fat REAL
        )
      '''),
    );
  }

  static Future<void> insert(WeightMeasurement m) async {
    final d = await db;
    await d.insert('measurements', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<WeightMeasurement>> getAll({int limit = 100}) async {
    final d = await db;
    final rows = await d.query(
      'measurements',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(WeightMeasurement.fromMap).toList();
  }

  static Future<void> delete(int id) async {
    final d = await db;
    await d.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }
}
