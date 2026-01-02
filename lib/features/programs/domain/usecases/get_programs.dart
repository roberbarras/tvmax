import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
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
    );
  }
}

class GetProgramsParams extends Equatable {
  final int page;
  final String? mainChannelId;
  final String? categoryId;

  const GetProgramsParams({
    this.page = 0,
    this.mainChannelId,
    this.categoryId,
  });

  @override
  List<Object?> get props => [page, mainChannelId, categoryId];
}
