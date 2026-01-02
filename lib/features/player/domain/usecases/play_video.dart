import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/player_repository.dart';

class PlayVideo implements UseCase<void, PlayVideoParams> {
  final PlayerRepository repository;

  PlayVideo(this.repository);

  @override
  Future<Either<Failure, void>> call(PlayVideoParams params) async {
    return await repository.playVideo(params.url);
  }
}

class PlayVideoParams extends Equatable {
  final String url;

  const PlayVideoParams({required this.url});

  @override
  List<Object> get props => [url];
}
