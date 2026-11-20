import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/entities/content_source.dart';
import '../../../../core/error/exceptions.dart';
import '../models/program_model.dart';

/// Interface for local storage of programs.
///
/// Because nobody likes a blank screen when the WiFi dies.
abstract class ProgramsLocalDataSource {
  /// Saves a fresh batch of programs to the database.
  Future<void> cachePrograms(List<ProgramModel> programs);

  /// Retrieves the last known list of programs of [source].
  /// Throws a [CacheException] if the cupboard is bare.
  Future<List<ProgramModel>> getLastPrograms({ContentSource source = ContentSource.atresplayer});
}

class ProgramsLocalDataSourceImpl implements ProgramsLocalDataSource {
  final DatabaseHelper databaseHelper;

  ProgramsLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<void> cachePrograms(List<ProgramModel> programs) async {
    final db = await databaseHelper.database;
    final batch = db.batch();
    
    // Simple strategy: Clear and Insert All for "Last Cache"
    // Or Insert/Replace
    for (var program in programs) {
      batch.insert(
        'programs',
        program.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ProgramModel>> getLastPrograms({ContentSource source = ContentSource.atresplayer}) async {
    final db = await databaseHelper.database;
    // Rows cached before sources existed have no source: they are Atresplayer.
    final result = source == ContentSource.atresplayer
        ? await db.query('programs', where: 'source IS NULL OR source = ?', whereArgs: [source.name])
        : await db.query('programs', where: 'source = ?', whereArgs: [source.name]);

    if (result.isNotEmpty) {
      return result.map((json) => ProgramModel.fromDb(json)).toList();
    } else {
      throw CacheException();
    }
  }
}
