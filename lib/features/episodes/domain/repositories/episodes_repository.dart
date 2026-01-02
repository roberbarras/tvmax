import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/episode.dart';

abstract class EpisodesRepository {
  Future<Either<Failure, List<Episode>>> getEpisodes(String formatId, {int page = 0});
  Future<Either<Failure, String>> getStreamingUrl(String contentId);
}
