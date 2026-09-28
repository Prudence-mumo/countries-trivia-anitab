import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/models/question.dart';
import 'package:country_trivia/repositories/country_repository.dart';
import 'package:country_trivia/repositories/fallback_country_repository.dart';

class _FailingRepository implements CountryRepository {
  @override
  Future<List<Country>> fetchAllCountries() async => throw Exception('API down');

  @override
  Future<List<Country>> fetchUnshownCountries() async => throw Exception('API down');

  @override
  Future<Question> generateQuestion() async => throw Exception('API down');
}

class _WorkingRepository implements CountryRepository {
  @override
  Future<List<Country>> fetchAllCountries() async => const [
        Country(name: 'Germany', isoCode: 'DE'),
        Country(name: 'France', isoCode: 'FR'),
      ];

  @override
  Future<List<Country>> fetchUnshownCountries() async => const [
        Country(name: 'Germany', isoCode: 'DE'),
        Country(name: 'France', isoCode: 'FR'),
      ];

  @override
  Future<Question> generateQuestion() async => const Question(
        correctCountry: Country(name: 'Germany', isoCode: 'DE'),
        options: [
          Country(name: 'Germany', isoCode: 'DE'),
          Country(name: 'France', isoCode: 'FR'),
        ],
      );
}

void main() {
  group('FallbackCountryRepository', () {
    test('returns from primary when it works', () async {
      final repo = FallbackCountryRepository(
        primary: _WorkingRepository(),
        fallback: _FailingRepository(),
      );

      final countries = await repo.fetchAllCountries();
      expect(countries.length, 2);
    });

    test('falls back when primary fails', () async {
      final repo = FallbackCountryRepository(
        primary: _FailingRepository(),
        fallback: _WorkingRepository(),
      );

      final countries = await repo.fetchAllCountries();
      expect(countries.length, 2);
    });

    test('generateQuestion falls back on failure', () async {
      final repo = FallbackCountryRepository(
        primary: _FailingRepository(),
        fallback: _WorkingRepository(),
      );

      final question = await repo.generateQuestion();
      expect(question.options.length, 2);
    });
  });
}
