import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age INTEGER,
        height REAL,
        weight REAL,
        gender TEXT,
        fitness_goal TEXT,
        dietary_restrictions TEXT,
        fitness_level TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE progress_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        weight REAL,
        notes TEXT
      )
    ''');
  }

  Future<int> insertUserProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    return await db.insert('user_profile', profile);
  }

  Future<int> updateUserProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    return await db.update('user_profile', profile, where: 'id = ?', whereArgs: [profile['id']]);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await instance.database;
    final results = await db.query('user_profile', limit: 1);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> insertProgressEntry(Map<String, dynamic> entry) async {
    final db = await instance.database;
    return await db.insert('progress_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getProgressEntries() async {
    final db = await instance.database;
    return await db.query('progress_entries', orderBy: 'date DESC');
  }
}