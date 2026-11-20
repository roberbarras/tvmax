import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/entities/content_source.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/program.dart';
import '../repositories/programs_repository.dart';

class GetPrograms implements UseCase<List<Program>, GetProgramsParams> {
  final ProgramsRepository repository;

  GetPrograms(this.repository);

  @override
  Future<Either<Failure, List<Program>>> call(GetProgramsParams params) async {
    return await repository.getPrograms(
      page: params.page,
      mainChannelId: params.mainChannelId,
      categoryId: params.categoryId,
      source: params.source,
    );
  }
}

class GetProgramsParams extends Equatable {
  final int page;
  final String? mainChannelId;
  final String? categoryId;
  final ContentSource source;

  const GetProgramsParams({
    this.page = 0,
    this.mainChannelId,
    this.categoryId,
    this.source = ContentSource.atresplayer,
  });

  @override
  List<Object?> get props => [page, mainChannelId, categoryId, source];
}
