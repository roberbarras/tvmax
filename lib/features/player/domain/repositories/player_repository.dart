import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class PlayerRepository {
  Future<Either<Failure, void>> playVideo(String url);
  Future<Either<Failure, void>> downloadVideo(String url, String fileName);
}
