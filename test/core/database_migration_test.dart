import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tvflix/core/database/database_helper.dart';

Future<Set<String>> columns(Database db, String table) async =>
    (await db.rawQuery('PRAGMA table_info($table)')).map((c) => c['name'] as String).toSet();

void main() {
  sqfliteFfiInit();

  test('v3 -> v4 adds the source columns and keeps existing favorites', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        singleInstance: false,
        onCreate: (db, _) async {
          // Schema as shipped in 1.1.0 (database version 3)
          await db.execute('CREATE TABLE programs (id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL, '
              'imageUrlHorizontal TEXT, imageUrlVertical TEXT, channel TEXT NOT NULL)');
          await db.execute('CREATE TABLE episodes (id TEXT PRIMARY KEY, contentId TEXT NOT NULL, title TEXT NOT NULL, '
              'description TEXT NOT NULL, imageUrl TEXT, duration TEXT, publishDate INTEGER, formatId TEXT NOT NULL)');
          await db.execute('CREATE TABLE favorites (id TEXT PRIMARY KEY, title TEXT NOT NULL, imageUrl TEXT, '
              'channel TEXT NOT NULL, addedAt INTEGER, categoryId TEXT)');
          await db.insert('favorites', {'id': 'fmt1', 'title': 'El Hormiguero', 'channel': 'Antena 3', 'addedAt': 1});
        },
      ),
    );

    await DatabaseHelper.onUpgrade(db, 3, 4);

    expect(await columns(db, 'programs'), contains('source'));
    expect(await columns(db, 'episodes'), containsAll(['source', 'drmProtected']));
    expect(await columns(db, 'favorites'), contains('source'));
    final favorite = (await db.query('favorites')).single;
    expect(favorite['title'], 'El Hormiguero');
    expect(favorite['source'], isNull); // read back as Atresplayer
    await db.close();
  });

  test('a fresh v4 database matches an upgraded one', () async {
    final fresh = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 4, onCreate: DatabaseHelper.createDB, singleInstance: false));
    final upgraded = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(version: 1, singleInstance: false, onCreate: (db, _) async {
      await db.execute('CREATE TABLE programs (id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL, '
          'imageUrlHorizontal TEXT, imageUrlVertical TEXT, channel TEXT NOT NULL)');
      await db.execute('CREATE TABLE episodes (id TEXT PRIMARY KEY, contentId TEXT NOT NULL, title TEXT NOT NULL, '
          'description TEXT NOT NULL, imageUrl TEXT, duration TEXT, publishDate INTEGER, formatId TEXT NOT NULL)');
    }));
    await DatabaseHelper.onUpgrade(upgraded, 1, 4);

    for (final table in ['programs', 'episodes', 'favorites']) {
      expect(await columns(upgraded, table), await columns(fresh, table), reason: table);
    }
    await fresh.close();
    await upgraded.close();
  });
}
