import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/models/question.dart';

void main() {
  group('Question', () {
    const correctCountry = Country(name: 'Japan', isoCode: 'JP');
    const options = [
      Country(name: 'Japan', isoCode: 'JP'),
      Country(name: 'Germany', isoCode: 'DE'),
      Country(name: 'Brazil', isoCode: 'BR'),
      Country(name: 'Australia', isoCode: 'AU'),
    ];

    test('isCorrect returns true for correct answer', () {
      const question = Question(
        correctCountry: correctCountry,
        options: options,
      );

      expect(question.isCorrect(correctCountry), isTrue);
    });

    test('isCorrect returns false for incorrect answer', () {
      const question = Question(
        correctCountry: correctCountry,
        options: options,
      );

      const wrongAnswer = Country(name: 'Germany', isoCode: 'DE');
      expect(question.isCorrect(wrongAnswer), isFalse);
    });

    test('flagImageUrl returns correct country flag URL', () {
      const question = Question(
        correctCountry: correctCountry,
        options: options,
      );

      expect(question.flagImageUrl, 'http://flagcdn.com/w320/jp.png');
    });

    test('options contains 4 countries', () {
      const question = Question(
        correctCountry: correctCountry,
        options: options,
      );

      expect(question.options.length, 4);
    });
  });
}
