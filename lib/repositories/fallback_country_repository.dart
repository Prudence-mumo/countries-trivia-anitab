import '../models/country.dart';
import '../models/question.dart';
import 'country_repository.dart';

/// Tries the primary repository first, falls back to secondary on failure.
class FallbackCountryRepository implements CountryRepository {
  final CountryRepository _primary;
  final CountryRepository _fallback;

  FallbackCountryRepository({
    required CountryRepository primary,
    required CountryRepository fallback,
  })  : _primary = primary,
        _fallback = fallback;

  @override
  Future<List<Country>> fetchAllCountries() async {
    try {
      return await _primary.fetchAllCountries();
    } catch (_) {
      return await _fallback.fetchAllCountries();
    }
  }

  @override
  Future<List<Country>> fetchUnshownCountries() async {
    try {
      return await _primary.fetchUnshownCountries();
    } catch (_) {
      return await _fallback.fetchUnshownCountries();
    }
  }

  @override
  Future<Question> generateQuestion() async {
    try {
      return await _primary.generateQuestion();
    } catch (_) {
      return await _fallback.generateQuestion();
    }
  }
}
