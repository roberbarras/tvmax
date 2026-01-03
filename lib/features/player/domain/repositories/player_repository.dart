import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class PlayerRepository {
  Future<Either<Failure, void>> playVideo(String url);
  
  /// Downloads a video from [url] with the specified [fileName].
  /// [customPath] allows overriding the default download location.
  /// [onStart] callback provides the session/process ID for cancellation.
  Future<Either<Failure, void>> downloadVideo(
    String url, 
    String fileName, {
    String? customPath, 
    Function(int)? onStart,
  });
}
