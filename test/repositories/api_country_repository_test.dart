import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/repositories/api_country_repository.dart';
import 'package:country_trivia/services/api_service.dart';
import 'package:country_trivia/services/history_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('ApiCountryRepository', () {
    late ApiCountryRepository repository;
    late HistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      historyService = await HistoryService.create();

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'data': {
              'objects': [
                {'names': {'common': 'Germany'}, 'codes': {'alpha_2': 'DE'}},
                {'names': {'common': 'France'}, 'codes': {'alpha_2': 'FR'}},
                {'names': {'common': 'Japan'}, 'codes': {'alpha_2': 'JP'}},
                {'names': {'common': 'Brazil'}, 'codes': {'alpha_2': 'BR'}},
                {'names': {'common': 'Canada'}, 'codes': {'alpha_2': 'CA'}},
              ],
              'meta': {'total': 5, 'count': 5, 'limit': 100, 'offset': 0, 'more': false},
            },
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      repository = ApiCountryRepository(apiService, historyService);
    });

    test('fetchAllCountries returns parsed countries', () async {
      final countries = await repository.fetchAllCountries();
      expect(countries.length, 5);
      expect(countries[0].name, 'Germany');
      expect(countries[0].isoCode, 'DE');
    });

    test('generateQuestion returns question with 4 options', () async {
      final question = await repository.generateQuestion();
      expect(question.options.length, 4);
      expect(question.correctCountry, isA<Country>());
    });

    test('generateQuestion marks country as shown', () async {
      await repository.generateQuestion();
      expect(historyService.shownCount, 1);
    });

    test('fetchUnshownCountries excludes shown countries', () async {
      await repository.generateQuestion();
      final unshown = await repository.fetchUnshownCountries();
      final shownCodes = historyService.getShownCountryCodes();
      for (final country in unshown) {
        expect(shownCodes.contains(country.isoCode), isFalse);
      }
    });

    test('resets history when fewer than 4 unshown remain', () async {
      // Show all but 3 countries
      final countries = await repository.fetchAllCountries();
      for (int i = 0; i < countries.length - 3; i++) {
        await historyService.markCountryShown(countries[i].isoCode);
      }

      final unshown = await repository.fetchUnshownCountries();
      // Should have reset and returned all countries
      expect(unshown.length, greaterThanOrEqualTo(4));
    });
  });
}
