import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/services/history_service.dart';

void main() {
  group('HistoryService', () {
    late HistoryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = await HistoryService.create();
    });

    test('starts with empty shown countries', () {
      expect(service.getShownCountryCodes(), isEmpty);
      expect(service.shownCount, 0);
    });

    test('markCountryShown adds code to set', () async {
      await service.markCountryShown('US');
      expect(service.getShownCountryCodes(), contains('US'));
      expect(service.shownCount, 1);
    });

    test('markCountryShown does not duplicate', () async {
      await service.markCountryShown('US');
      await service.markCountryShown('US');
      expect(service.shownCount, 1);
    });

    test('hasBeenShown returns correct value', () async {
      await service.markCountryShown('DE');
      expect(service.hasBeenShown('DE'), isTrue);
      expect(service.hasBeenShown('FR'), isFalse);
    });

    test('resetHistory clears all shown countries', () async {
      await service.markCountryShown('US');
      await service.markCountryShown('DE');
      await service.markCountryShown('FR');
      expect(service.shownCount, 3);

      await service.resetHistory();
      expect(service.shownCount, 0);
      expect(service.getShownCountryCodes(), isEmpty);
    });

    test('highScore starts at 0', () {
      expect(service.highScore, 0);
    });

    test('saveHighScore saves when score is higher', () async {
      await service.saveHighScore(50);
      expect(service.highScore, 50);

      await service.saveHighScore(30);
      expect(service.highScore, 50);
    });

    test('totalGamesPlayed starts at 0', () {
      expect(service.totalGamesPlayed, 0);
    });

    test('incrementGamesPlayed increments counter', () async {
      await service.incrementGamesPlayed();
      expect(service.totalGamesPlayed, 1);

      await service.incrementGamesPlayed();
      expect(service.totalGamesPlayed, 2);
    });
  });
}
