import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/episode_model.dart';

abstract class EpisodesLocalDataSource {
  Future<void> cacheEpisodes(List<EpisodeModel> episodes, String formatId);
  Future<List<EpisodeModel>> getLastEpisodes(String formatId);
}

class EpisodesLocalDataSourceImpl implements EpisodesLocalDataSource {
  final DatabaseHelper databaseHelper;

  EpisodesLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<void> cacheEpisodes(List<EpisodeModel> episodes, String formatId) async {
    final db = await databaseHelper.database;
    final batch = db.batch();
    
    for (var episode in episodes) {
      final json = episode.toJson();
      json['formatId'] = formatId; // Add foreign key logic
      
      batch.insert(
        'episodes',
        json,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<EpisodeModel>> getLastEpisodes(String formatId) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'episodes',
      where: 'formatId = ?',
      whereArgs: [formatId],
    );
    
    if (result.isNotEmpty) {
      return result.map((json) => EpisodeModel.fromJson(json)).toList();
    } else {
      throw CacheException();
    }
  }
}
