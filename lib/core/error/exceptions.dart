class ServerException implements Exception {
  final int? statusCode;
  ServerException({this.statusCode});
}
class CacheException implements Exception {}
class PremiumContentException implements Exception {
  final int? statusCode;
  PremiumContentException({this.statusCode});
}
