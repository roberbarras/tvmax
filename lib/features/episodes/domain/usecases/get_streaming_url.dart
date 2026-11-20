import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/entities/content_source.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/episodes_repository.dart';

class GetStreamingUrl implements UseCase<String, GetStreamingUrlParams> {
  final EpisodesRepository repository;

  GetStreamingUrl(this.repository);

  @override
  Future<Either<Failure, String>> call(GetStreamingUrlParams params) async {
    return await repository.getStreamingUrl(params.contentId, source: params.source);
  }
}

class GetStreamingUrlParams extends Equatable {
  final String contentId;
  final ContentSource source;

  const GetStreamingUrlParams({required this.contentId, this.source = ContentSource.atresplayer});

  @override
  List<Object> get props => [contentId, source];
}
