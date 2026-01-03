import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Abstract class representing a Use Case in the Clean Architecture.
///
/// [Type] represents the return type of the success case.
/// [Params] represents the parameters required by the use case.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Helper class for UseCases that do not require any parameters.
class NoParams {}
