import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/weight_measurement.dart';
import '../models/user_profile.dart';

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
      version: 2,
      onCreate: (db, _) async {
        await _createMeasurements(db);
        await _createProfile(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) await _createProfile(db);
      },
    );
  }

  static Future<void> _createMeasurements(Database db) => db.execute('''
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
  ''');

  static Future<void> _createProfile(Database db) => db.execute('''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY,
      height_cm INTEGER NOT NULL,
      age_years INTEGER NOT NULL,
      gender TEXT NOT NULL,
      weight_unit TEXT NOT NULL,
      target_weight_kg REAL
    )
  ''');

  // ── Measurements ──────────────────────────────────────────────────────────

  static Future<int> insert(WeightMeasurement m) async {
    final d = await db;
    return d.insert('measurements', m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<WeightMeasurement>> getAll({int limit = 200}) async {
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

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<void> saveProfile(UserProfile profile) async {
    final d = await db;
    await d.insert('profile', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<UserProfile?> getProfile() async {
    final d = await db;
    final rows = await d.query('profile', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }
}
