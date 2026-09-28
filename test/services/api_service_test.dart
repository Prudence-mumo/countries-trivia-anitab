import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:country_trivia/services/api_service.dart';

void main() {
  group('ApiService', () {
    test('fetchAllCountries returns parsed country data on success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/countries/v5'));
        expect(request.headers['Authorization'], 'Bearer YOUR_API_KEY');
        return http.Response(
          json.encode({
            'data': {
              'objects': [
                {
                  'names': {'common': 'Germany'},
                  'codes': {'alpha_2': 'DE'},
                },
                {
                  'names': {'common': 'France'},
                  'codes': {'alpha_2': 'FR'},
                },
              ],
              'meta': {'total': 249, 'count': 2, 'limit': 100, 'offset': 0, 'more': false},
            },
          }),
          200,
        );
      });

      final service = ApiService(client: mockClient);
      final countries = await service.fetchAllCountries();

      expect(countries.length, 2);
      expect(countries[0]['names']['common'], 'Germany');
      expect(countries[1]['codes']['alpha_2'], 'FR');
    });

    test('fetchAllCountries follows pagination', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            json.encode({
              'data': {
                'objects': [
                  {
                    'names': {'common': 'Germany'},
                    'codes': {'alpha_2': 'DE'},
                  },
                ],
                'meta': {'total': 2, 'count': 1, 'limit': 1, 'offset': 0, 'more': true},
              },
            }),
            200,
          );
        } else {
          return http.Response(
            json.encode({
              'data': {
                'objects': [
                  {
                    'names': {'common': 'France'},
                    'codes': {'alpha_2': 'FR'},
                  },
                ],
                'meta': {'total': 2, 'count': 1, 'limit': 1, 'offset': 1, 'more': false},
              },
            }),
            200,
          );
        }
      });

      final service = ApiService(client: mockClient);
      final countries = await service.fetchAllCountries();

      expect(countries.length, 2);
      expect(callCount, 2);
    });

    test('fetchAllCountries throws ApiException on error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = ApiService(client: mockClient);

      expect(
        () => service.fetchAllCountries(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
