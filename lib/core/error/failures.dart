import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Server Error', this.statusCode]);
  
  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

class PremiumContentFailure extends Failure {
  final int? statusCode;
  const PremiumContentFailure([super.message = 'Contenido Premium o No Disponible', this.statusCode]);

  @override
  List<Object> get props => [message, if (statusCode != null) statusCode!];
}
