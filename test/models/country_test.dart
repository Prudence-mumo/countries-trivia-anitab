import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/country.dart';

void main() {
  group('Country', () {
    test('creates from v5 JSON correctly', () {
      final json = {
        'names': {'common': 'United States'},
        'codes': {'alpha_2': 'US'},
      };

      final country = Country.fromJsonV5(json);

      expect(country.name, 'United States');
      expect(country.isoCode, 'US');
    });

    test('creates from v3 JSON correctly', () {
      final json = {
        'name': 'Germany',
        'cca2': 'DE',
      };

      final country = Country.fromJsonV3(json);

      expect(country.name, 'Germany');
      expect(country.isoCode, 'DE');
    });

    test('flagUrl returns correct URL', () {
      const country = Country(name: 'Japan', isoCode: 'JP');

      expect(country.flagUrl, 'http://flagcdn.com/w320/jp.png');
    });

    test('flagUrl lowercases isoCode', () {
      const country = Country(name: 'United Kingdom', isoCode: 'GB');

      expect(country.flagUrl, 'http://flagcdn.com/w320/gb.png');
    });

    test('equality is based on isoCode', () {
      const country1 = Country(name: 'United States', isoCode: 'US');
      const country2 = Country(name: 'United States', isoCode: 'US');
      const country3 = Country(name: 'Canada', isoCode: 'CA');

      expect(country1, equals(country2));
      expect(country1, isNot(equals(country3)));
    });

    test('hashCode is based on isoCode', () {
      const country1 = Country(name: 'France', isoCode: 'FR');
      const country2 = Country(name: 'France', isoCode: 'FR');

      expect(country1.hashCode, country2.hashCode);
    });
  });
}
