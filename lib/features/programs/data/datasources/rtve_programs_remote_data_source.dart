import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/logger_service.dart';
import '../models/program_model.dart';
import 'programs_remote_data_source.dart';

/// Lists RTVE television programs from the public RTVE API (no account needed).
///
/// [mainChannelId] and [categoryId] are Atresplayer filters and are ignored.
class RtveProgramsRemoteDataSource implements ProgramsRemoteDataSource {
  final http.Client client;

  RtveProgramsRemoteDataSource({required this.client});

  static const pageSize = 100;

  @override
  Future<List<ProgramModel>> getPrograms({
    int page = 0,
    String? mainChannelId,
    String? categoryId,
  }) async {
    // RTVE pages start at 1. Past the last page it answers with an empty item list.
    final uri = Uri.parse(
      '${AppConstants.rtveApiBaseUrl}/medios/${AppConstants.rtveTvMedioId}/programas.json?size=$pageSize&page=${page + 1}',
    );
    LoggerService().debug('[RtveProgramsRemoteDataSource] Fetching: $uri');
    final response = await client.get(uri, headers: AppConstants.rtveHeaders);

    if (response.statusCode != 200) {
      LoggerService().debug('[RtveProgramsRemoteDataSource] Error: ${response.statusCode}');
      throw ServerException(statusCode: response.statusCode);
    }
    return parsePrograms(utf8.decode(response.bodyBytes));
  }

  static List<ProgramModel> parsePrograms(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final items = (json['page']?['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ProgramModel.fromRtveJson)
        .where((p) => p.id.isNotEmpty)
        .toList();
  }
}
