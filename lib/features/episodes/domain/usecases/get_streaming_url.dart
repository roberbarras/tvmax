import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/episodes_repository.dart';

class GetStreamingUrl implements UseCase<String, GetStreamingUrlParams> {
  final EpisodesRepository repository;

  GetStreamingUrl(this.repository);

  @override
  Future<Either<Failure, String>> call(GetStreamingUrlParams params) async {
    return await repository.getStreamingUrl(params.contentId);
  }
}

class GetStreamingUrlParams extends Equatable {
  final String contentId;

  const GetStreamingUrlParams({required this.contentId});

  @override
  List<Object> get props => [contentId];
}
