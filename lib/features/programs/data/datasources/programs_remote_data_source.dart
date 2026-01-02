import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/utils/constants.dart';
import '../models/program_model.dart';
import '../../../../core/error/exceptions.dart';

import 'package:shared_preferences/shared_preferences.dart';

abstract class ProgramsRemoteDataSource {
  Future<List<ProgramModel>> getPrograms({
    int page = 0,
    String? mainChannelId,
    String? categoryId,
  });
}

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
    // Note: Pagination in this specific endpoint might be handled differently 
    // or loaded all at once. The initial URL fetches a list.
    // We will use the URL from the prompt.
    // If page > 0 is needed, we'll need to investigate pagination params.
    // For now we assume page 0 fetches the main list.
    
    // Use provided IDs or fallback to defaults (Programas)
    final channel = mainChannelId ?? AppConstants.mainChannelId;
    final category = categoryId ?? AppConstants.categoryId;

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
