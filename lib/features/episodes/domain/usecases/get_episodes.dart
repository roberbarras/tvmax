import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/entities/content_source.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/episode.dart';
import '../repositories/episodes_repository.dart';

class GetEpisodes implements UseCase<List<Episode>, GetEpisodesParams> {
  final EpisodesRepository repository;

  GetEpisodes(this.repository);

  @override
  Future<Either<Failure, List<Episode>>> call(GetEpisodesParams params) async {
    return await repository.getEpisodes(params.formatId, page: params.page, source: params.source);
  }
}

class GetEpisodesParams extends Equatable {
  final String formatId;
  final int page;
  final ContentSource source;

  const GetEpisodesParams({required this.formatId, this.page = 0, this.source = ContentSource.atresplayer});

  @override
  List<Object> get props => [formatId, page, source];
}
