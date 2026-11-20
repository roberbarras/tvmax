import 'package:dartz/dartz.dart';
import '../../../../core/entities/content_source.dart';
import '../../../../core/error/failures.dart';
import '../entities/episode.dart';

abstract class EpisodesRepository {
  Future<Either<Failure, List<Episode>>> getEpisodes(
    String formatId, {
    int page = 0,
    ContentSource source = ContentSource.atresplayer,
  });
  Future<Either<Failure, String>> getStreamingUrl(
    String contentId, {
    ContentSource source = ContentSource.atresplayer,
  });
}
