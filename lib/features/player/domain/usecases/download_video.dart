import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/player_repository.dart';

class DownloadVideo implements UseCase<void, DownloadVideoParams> {
  final PlayerRepository repository;

  DownloadVideo(this.repository);

  @override
  Future<Either<Failure, void>> call(DownloadVideoParams params) async {
    return await repository.downloadVideo(params.url, params.fileName);
  }
}

class DownloadVideoParams extends Equatable {
  final String url;
  final String fileName;

  const DownloadVideoParams({required this.url, required this.fileName});

  @override
  List<Object> get props => [url, fileName];
}
