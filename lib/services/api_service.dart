import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Exception thrown when the API request fails.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client for the REST Countries v5 API.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${AppConstants.apiKey}',
      };

  /// Fetch all countries with pagination support.
  Future<List<Map<String, dynamic>>> fetchAllCountries() async {
    final List<Map<String, dynamic>> allCountries = [];
    int offset = 0;
    const int limit = 100;
    bool hasMore = true;

    while (hasMore) {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}?response_fields=names.common,codes.alpha_2&limit=$limit&offset=$offset',
      );

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final objects = body['data']['objects'] as List<dynamic>;
        allCountries.addAll(objects.cast<Map<String, dynamic>>());
        hasMore = body['data']['meta']['more'] as bool;
        offset += limit;
      } else {
        throw ApiException(
          'Failed to fetch countries: ${response.statusCode}',
          response.statusCode,
        );
      }
    }

    return allCountries;
  }
}
