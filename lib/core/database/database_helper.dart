import 'dart:io';
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
      version: 3, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
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
  channel $textType
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
  formatId $textType
  )
''');

    await _createFavoritesTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFavoritesTable(db);
    }
    if (oldVersion < 3) {
      // Add categoryId column to favorites table
      // Check if column exists first? standard add column
      await db.execute('ALTER TABLE favorites ADD COLUMN categoryId TEXT');
    }
  }

  Future _createFavoritesTable(Database db) async {
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
  categoryId $textNullable
  )
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
