import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/utils/constants.dart';
import '../models/program_model.dart';
import '../../../../core/error/exceptions.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// The gateway to the external world.
///
/// This abstract class defines the contract for fetching program data from the API.
/// It doesn't care *how* you get it, just that you get it.
abstract class ProgramsRemoteDataSource {
  /// Fetches a list of programs based on the provided filters.
  ///
  /// [page] - Pagination index (starts at 0).
  /// [mainChannelId] - Filter by specific channel (e.g., 'antena3').
  /// [categoryId] - Filter by category (e.g., 'Series', 'Documentaries').
  Future<List<ProgramModel>> getPrograms({
    int page = 0,
    String? mainChannelId,
    String? categoryId,
  });
}

/// Implementation of the remote data source using strictly HTTP.
///
/// We're using [http.Client] to make requests to the 'client/v1/row/search' endpoint.
/// This is where the magic happens—turning JSON into Dart objects.
class ProgramsRemoteDataSourceImpl implements ProgramsRemoteDataSource {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  ProgramsRemoteDataSourceImpl({
    required this.client,
    required this.sharedPreferences,
  });

  @override
  Future<List<ProgramModel>> getPrograms({
    int page = 0,
    String? mainChannelId,
    String? categoryId,
  }) async {
    // We decided to paginate, but honestly, we might just fetch the first 100 items for now.
    // The API seems to support 'size' and 'page' params, so let's use them.
    
    // Default to 'Programas' if no specific filter is given.
    final channel = mainChannelId ?? AppConstants.mainChannelId;
    final category = categoryId ?? AppConstants.categoryId;

    // Constructing the massive query URL.
    // EntityType 'ATPFormat' seems to correspond to "Shows" or "Series".
    final uri = Uri.parse(
      '${AppConstants.apiBaseUrl}/client/v1/row/search?entityType=ATPFormat&sectionCategory=true&mainChannelId=$channel&categoryId=$category&size=100&sortType=THE_MOST&page=$page'
    );

    // Cookie not needed for browsing programs/news
    // final cookie = sharedPreferences.getString('auth_cookie');
    // final headers = AppConstants.getHeaders(cookie);

    print('[ProgramsRemoteDataSource] Fetching: $uri');
    // print('[ProgramsRemoteDataSource] Headers len: ${headers.length}, Cookie present: ${headers.containsKey("Cookie")}');

    final response = await client.get(
      uri,
      // headers: headers,
    );

    print('[ProgramsRemoteDataSource] Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> rows = jsonResponse['itemRows'] ?? [];
      
      return rows.map((e) => ProgramModel.fromJson(e, categoryId: category)).toList();
    } else {
      print('[ProgramsRemoteDataSource] Error: ${response.statusCode} - ${response.body}');
      throw ServerException();
    }
  }
}
