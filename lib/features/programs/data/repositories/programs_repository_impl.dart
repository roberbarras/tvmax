import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';

import '../../domain/entities/program.dart';
import '../../domain/repositories/programs_repository.dart';
import '../datasources/programs_remote_data_source.dart';
import '../datasources/programs_local_data_source.dart';

class ProgramsRepositoryImpl implements ProgramsRepository {
  final ProgramsRemoteDataSource remoteDataSource;

  final ProgramsLocalDataSource localDataSource;

  ProgramsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<Program>>> getPrograms({
    int page = 0,
    String? mainChannelId,
    String? categoryId,
  }) async {
    try {
      final remotePrograms = await remoteDataSource.getPrograms(
        page: page,
        mainChannelId: mainChannelId,
        categoryId: categoryId,
      );
      await localDataSource.cachePrograms(remotePrograms);
      return Right(remotePrograms);
    } catch (e) {
      print('DEBUG ERROR FETCHING PROGRAMS: $e');
      if (e is Error) {
          print('STACK TRACE: ${e.stackTrace}');
      }
      // Fallback to cache
      try {
        final localPrograms = await localDataSource.getLastPrograms();
        return Right(localPrograms);
      } catch (cacheError) {
        return const Left(NetworkFailure('Could not fetch programs and no offline data'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Program>>> searchPrograms(String query) async {
    // Implement search logic later or reuse getPrograms with filter if API supports it
    // For now, return empty or implement basic client-side filter if needed
    // But since the task requires browsing, checking endpoints...
    // The script script uses "row/search" which implies search capability.
    return const Left(ServerFailure('Search not implemented yet'));
  }
}
