import '../models/country.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import 'country_repository.dart';

/// Fetches countries from the REST API and generates questions.
class ApiCountryRepository implements CountryRepository {
  final ApiService _apiService;
  final HistoryService _historyService;

  ApiCountryRepository(this._apiService, this._historyService);

  @override
  Future<List<Country>> fetchAllCountries() async {
    final response = await _apiService.fetchAllCountries();
    return response.map((json) => Country.fromJsonV5(json)).toList();
  }

  @override
  Future<List<Country>> fetchUnshownCountries() async {
    final all = await fetchAllCountries();
    final shownCodes = _historyService.getShownCountryCodes();
    final unshown =
        all.where((c) => !shownCodes.contains(c.isoCode)).toList();

    // If all countries have been shown, reset and start fresh
    if (unshown.length < AppConstants.optionsPerQuestion) {
      await _historyService.resetHistory();
      all.shuffle();
      return all;
    }

    return unshown;
  }

  @override
  Future<Question> generateQuestion() async {
    final unshown = await fetchUnshownCountries();
    unshown.shuffle();

    final correct = unshown.first;
    final distractors = unshown.skip(1).take(3).toList();
    final options = [correct, ...distractors]..shuffle();

    // Mark the correct country as shown
    await _historyService.markCountryShown(correct.isoCode);

    return Question(correctCountry: correct, options: options);
  }
}
