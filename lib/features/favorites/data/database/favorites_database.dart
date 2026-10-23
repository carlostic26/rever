import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/favorite_audio.dart';

class FavoritesDatabase {
  static const String _databaseName = 'retrovoz.db';
  static const int _databaseVersion = 1;
  static const String tableName = 'favorites';

  static FavoritesDatabase? _instance;
  static Database? _database;

  FavoritesDatabase._();

  factory FavoritesDatabase() {
    _instance ??= FavoritesDatabase._();
    return _instance!;
  }

  /// Permite inyectar una instancia de Database (útil para pruebas unitarias con sqflite_common_ffi)
  FavoritesDatabase.withDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        duration_ms INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertFavorite(FavoriteAudio favorite) async {
    final db = await database;
    return await db.insert(
      tableName,
      favorite.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FavoriteAudio>> getAllFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'datetime(created_at) DESC, id DESC',
    );
    return maps.map((map) => FavoriteAudio.fromMap(map)).toList();
  }

  Future<int> deleteFavorite(int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllFavorites() async {
    final db = await database;
    return await db.delete(tableName);
  }

  Future<bool> isFavoriteSaved({String? name, String? filePath}) async {
    final db = await database;
    if (filePath != null) {
      final res = await db.query(
        tableName,
        where: 'file_path = ?',
        whereArgs: [filePath],
        limit: 1,
      );
      if (res.isNotEmpty) return true;
    }
    if (name != null) {
      final res = await db.query(
        tableName,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );
      if (res.isNotEmpty) return true;
    }
    return false;
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}

