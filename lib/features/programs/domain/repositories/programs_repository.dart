import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/program.dart';

abstract class ProgramsRepository {
  Future<Either<Failure, List<Program>>> getPrograms({
    int page = 0,
    String? mainChannelId,
    String? categoryId,
  });
  Future<Either<Failure, List<Program>>> searchPrograms(String query);
}
