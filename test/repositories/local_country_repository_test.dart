import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/repositories/local_country_repository.dart';
import 'package:country_trivia/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalCountryRepository', () {
    late LocalCountryRepository repository;
    late HistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      historyService = await HistoryService.create();
      repository = LocalCountryRepository(historyService);
    });

    test('fetchAllCountries loads from JSON asset', () async {
      final countries = await repository.fetchAllCountries();
      expect(countries.length, greaterThan(0));
      expect(countries.first.name, isA<String>());
      expect(countries.first.isoCode, isA<String>());
    });

    test('fetchAllCountries caches results', () async {
      final first = await repository.fetchAllCountries();
      final second = await repository.fetchAllCountries();
      expect(identical(first, second), isTrue);
    });

    test('generateQuestion returns question with 4 options', () async {
      final question = await repository.generateQuestion();
      expect(question.options.length, 4);
    });

    test('generateQuestion marks country as shown', () async {
      await repository.generateQuestion();
      expect(historyService.shownCount, 1);
    });
  });
}
