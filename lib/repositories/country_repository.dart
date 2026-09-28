import '../models/country.dart';
import '../models/question.dart';

/// Abstract repository interface for country data.
abstract class CountryRepository {
  /// Fetch all available countries.
  Future<List<Country>> fetchAllCountries();

  /// Fetch only countries that haven't been shown yet.
  Future<List<Country>> fetchUnshownCountries();

  /// Generate a quiz question with one correct answer and distractors.
  Future<Question> generateQuestion();
}
