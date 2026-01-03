import 'package:equatable/equatable.dart';

/// Base failure class for error handling.
///
/// Extends [Equatable] to facilitate value comparisons in test environments.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Represents a failure coming from the remote server.
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Server Error', this.statusCode]);
  
  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}

/// Represents a failure when loading data from local cache/database.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error']);
}

/// Represents a failure due to lack of network connectivity.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

/// Represents a failure when accessing restricted/premium content without authorization.
class PremiumContentFailure extends Failure {
  final int? statusCode;
  const PremiumContentFailure([super.message = 'Contenido Premium o No Disponible', this.statusCode]);

  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}
