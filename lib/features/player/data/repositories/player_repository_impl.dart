import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_local_data_source.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerLocalDataSource localDataSource;

  PlayerRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> playVideo(String url) async {
    try {
      await localDataSource.playVideo(url);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Could not launch player'));
    }
  }

  @override
  Future<Either<Failure, void>> downloadVideo(String url, String fileName) async {
    try {
      await localDataSource.downloadVideo(url, fileName);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Could not start download'));
    }
  }
}
