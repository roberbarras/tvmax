import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../models/episode_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

abstract class EpisodesRemoteDataSource {
  Future<List<EpisodeModel>> getEpisodes(String formatId, {int page = 0});
  Future<String> getStreamingUrl(String contentId);
}

class EpisodesRemoteDataSourceImpl implements EpisodesRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  EpisodesRemoteDataSourceImpl({
    required this.client,
    required this.sharedPreferences,
  });

  @override
  Future<List<EpisodeModel>> getEpisodes(String formatId, {int page = 0}) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/client/v1/row/search?entityType=ATPEpisode&formatId=$formatId&size=100&page=$page'
    );

    // Cookie not needed for browsing episodes list
    // final cookie = sharedPreferences.getString('auth_cookie');
    // final headers = AppConstants.getHeaders(cookie);

    print('[EpisodesRemoteDataSource] getEpisodes Fetching: $uri');
    final response = await client.get(
      uri,
      // headers: headers,
    );
    print('[EpisodesRemoteDataSource] getEpisodes Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> rows = jsonResponse['itemRows'] ?? [];
      
      return rows.map((e) => EpisodeModel.fromJson(e)).toList();
    } else if (response.statusCode == 403 || response.statusCode == 404) {
      throw PremiumContentException(statusCode: response.statusCode);
    } else {
      throw ServerException(statusCode: response.statusCode);
    }
  }

  @override
  Future<String> getStreamingUrl(String contentId) async {
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/player/v1/episode/$contentId'
    );

    final cookie = sharedPreferences.getString('auth_cookie');
    final headers = AppConstants.getHeaders(cookie);

    print('[EpisodesRemoteDataSource] getStreamingUrl Fetching: $uri');
    final response = await client.get(
      uri,
      headers: headers,
    );
    print('[EpisodesRemoteDataSource] getStreamingUrl Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // Logic from script: .sources or similar.
      // We need to parse sources.
      // sources is usually a list. We look for type "application/dash+xml" or "application/x-mpegURL"
      
      final sources = jsonResponse['sources'] as List<dynamic>?;
      if (sources != null && sources.isNotEmpty) {
        // Try to find src. Script takes sources[1].src.
        // We'll try to find the best one.
        for (var source in sources) {
            // Check type if needed, or just return first valid src
            if (source['src'] != null) {
                return source['src'];
            }
        }
        if (sources.length > 1 && sources[1]['src'] != null) {
             return sources[1]['src'];
        }
        return sources[0]['src'] ?? '';
      }
      throw ServerException(statusCode: response.statusCode);
    } else if (response.statusCode == 403 || response.statusCode == 404) {
      throw PremiumContentException(statusCode: response.statusCode);
    } else {
      throw ServerException(statusCode: response.statusCode);
    }
  }
}
