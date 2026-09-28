import 'country.dart';

/// Represents a quiz question with a correct answer and multiple options.
class Question {
  /// The correct country for this question.
  final Country correctCountry;

  /// List of answer options (includes the correct country).
  final List<Country> options;

  const Question({
    required this.correctCountry,
    required this.options,
  });

  /// Flag image URL for the correct country.
  String get flagImageUrl => correctCountry.flagUrl;

  /// Check if the selected country is the correct answer.
  bool isCorrect(Country answer) => answer.isoCode == correctCountry.isoCode;
}
