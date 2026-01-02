import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/program_model.dart';

abstract class ProgramsLocalDataSource {
  Future<void> cachePrograms(List<ProgramModel> programs);
  Future<List<ProgramModel>> getLastPrograms();
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
  Future<List<ProgramModel>> getLastPrograms() async {
    final db = await databaseHelper.database;
    final result = await db.query('programs');
    
    if (result.isNotEmpty) {
      return result.map((json) => ProgramModel.fromJson(json)).toList();
    } else {
      throw CacheException();
    }
  }
}
