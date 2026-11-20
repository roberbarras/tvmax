import 'package:dartz/dartz.dart';
import '../../../../core/entities/content_source.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/episodes_repository.dart';
import '../datasources/episodes_remote_data_source.dart';
import '../datasources/episodes_local_data_source.dart';

class EpisodesRepositoryImpl implements EpisodesRepository {
  final EpisodesRemoteDataSource remoteDataSource;
  final EpisodesRemoteDataSource rtveRemoteDataSource;
  final EpisodesLocalDataSource localDataSource;

  EpisodesRepositoryImpl({
    required this.remoteDataSource,
    required this.rtveRemoteDataSource,
    required this.localDataSource,
  });

  EpisodesRemoteDataSource _remoteFor(ContentSource source) {
    switch (source) {
      case ContentSource.atresplayer:
        return remoteDataSource;
      case ContentSource.rtve:
        return rtveRemoteDataSource;
    }
  }

  @override
  Future<Either<Failure, List<Episode>>> getEpisodes(
    String formatId, {
    int page = 0,
    ContentSource source = ContentSource.atresplayer,
  }) async {
    try {
      final remoteEpisodes = await _remoteFor(source).getEpisodes(formatId, page: page);
      await localDataSource.cacheEpisodes(remoteEpisodes, formatId);
      return Right(remoteEpisodes);
    } catch (e) {
      try {
         final localEpisodes = await localDataSource.getLastEpisodes(formatId);
         return Right(localEpisodes);
      } catch (cacheError) {
         return const Left(NetworkFailure('Could not fetch episodes and no offline data'));
      }
    }
  }

  @override
  Future<Either<Failure, String>> getStreamingUrl(
    String contentId, {
    ContentSource source = ContentSource.atresplayer,
  }) async {
    try {
      final url = await _remoteFor(source).getStreamingUrl(contentId);
      return Right(url);
    } on DrmProtectedException {
      return const Left(DrmProtectedFailure());
    } on PremiumContentException catch (e) {
      return Left(PremiumContentFailure('Contenido Premium o No Disponible', e.statusCode));
    } on ServerException catch (e) {
      if (e.statusCode == 404) return const Left(ServerFailure('Este vídeo ya no está disponible', 404));
      return Left(ServerFailure('Server Error', e.statusCode));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
