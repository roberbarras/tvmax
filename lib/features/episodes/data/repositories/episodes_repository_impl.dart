import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/episodes_repository.dart';
import '../datasources/episodes_remote_data_source.dart';
import '../datasources/episodes_local_data_source.dart';

class EpisodesRepositoryImpl implements EpisodesRepository {
  final EpisodesRemoteDataSource remoteDataSource;
  final EpisodesLocalDataSource localDataSource;

  EpisodesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Episode>>> getEpisodes(String formatId, {int page = 0}) async {
    try {
      final remoteEpisodes = await remoteDataSource.getEpisodes(formatId, page: page);
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
  Future<Either<Failure, String>> getStreamingUrl(String contentId) async {
    try {
      final url = await remoteDataSource.getStreamingUrl(contentId);
      return Right(url);
    } on PremiumContentException catch (e) {
      return Left(PremiumContentFailure('Contenido Premium o No Disponible', e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure('Server Error', e.statusCode));
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
