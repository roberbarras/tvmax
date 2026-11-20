import 'package:dartz/dartz.dart';
import '../../../../core/entities/content_source.dart';
import '../../../../core/error/failures.dart';
import '../entities/program.dart';

abstract class ProgramsRepository {
  Future<Either<Failure, List<Program>>> getPrograms({
    int page = 0,
    String? mainChannelId,
    String? categoryId,
    ContentSource source = ContentSource.atresplayer,
  });
  Future<Either<Failure, List<Program>>> searchPrograms(String query);
}
