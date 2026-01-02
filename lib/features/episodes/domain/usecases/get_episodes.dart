import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/episode.dart';
import '../repositories/episodes_repository.dart';

class GetEpisodes implements UseCase<List<Episode>, GetEpisodesParams> {
  final EpisodesRepository repository;

  GetEpisodes(this.repository);

  @override
  Future<Either<Failure, List<Episode>>> call(GetEpisodesParams params) async {
    return await repository.getEpisodes(params.formatId, page: params.page);
  }
}

class GetEpisodesParams extends Equatable {
  final String formatId;
  final int page;

  const GetEpisodesParams({required this.formatId, this.page = 0});

  @override
  List<Object> get props => [formatId, page];
}
