import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('atresplayer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path, 
      version: 4,
      onCreate: createDB,
      onUpgrade: onUpgrade,
    );
  }

  @visibleForTesting
  static Future createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intNullable = 'INTEGER';

    await db.execute('''
CREATE TABLE programs ( 
  id $idType, 
  title $textType,
  description $textType,
  imageUrlHorizontal $textNullable,
  imageUrlVertical $textNullable,
  channel $textType,
  source $textNullable
  )
''');

    await db.execute('''
CREATE TABLE episodes ( 
  id $idType, 
  contentId $textType,
  title $textType,
  description $textType,
  imageUrl $textNullable,
  duration $textNullable,
  publishDate $intNullable,
  formatId $textType,
  source $textNullable,
  drmProtected $intNullable
  )
''');

    await _createFavoritesTable(db);
  }

  @visibleForTesting
  static Future onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFavoritesTable(db);
    }
    if (oldVersion < 3) {
      // Add categoryId column to favorites table. Databases created at v2
      // already have it (the table is created with that column), so check first.
      final columns = await db.rawQuery('PRAGMA table_info(favorites)');
      final hasCategoryId = columns.any((c) => c['name'] == 'categoryId');
      if (!hasCategoryId) {
        await db.execute('ALTER TABLE favorites ADD COLUMN categoryId TEXT');
      }
    }
    if (oldVersion < 4) {
      // Content source (atresplayer/rtve). Old rows keep NULL, read as Atresplayer.
      // Favorites created by the v1 -> v2 step above already have the column.
      await _addColumnIfMissing(db, 'programs', 'source', 'TEXT');
      await _addColumnIfMissing(db, 'episodes', 'source', 'TEXT');
      await _addColumnIfMissing(db, 'episodes', 'drmProtected', 'INTEGER');
      await _addColumnIfMissing(db, 'favorites', 'source', 'TEXT');
    }
  }

  static Future<void> _addColumnIfMissing(Database db, String table, String column, String type) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (!columns.any((c) => c['name'] == column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  static Future _createFavoritesTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intNullable = 'INTEGER';

    await db.execute('''
CREATE TABLE favorites ( 
  id $idType, 
  title $textType,
  imageUrl $textNullable,
  channel $textType,
  addedAt $intNullable,
  categoryId $textNullable,
  source $textNullable
  )
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
