import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/country.dart';
import '../models/question.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';
import 'country_repository.dart';

/// Loads countries from a bundled JSON asset (offline fallback).
class LocalCountryRepository implements CountryRepository {
  final HistoryService _historyService;
  List<Country>? _cachedCountries;

  LocalCountryRepository(this._historyService);

  @override
  Future<List<Country>> fetchAllCountries() async {
    if (_cachedCountries != null) return _cachedCountries!;
    final jsonString =
        await rootBundle.loadString('assets/data/countries.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _cachedCountries = jsonList
        .map((json) => Country.fromJsonV3(json as Map<String, dynamic>))
        .toList();
    return _cachedCountries!;
  }

  @override
  Future<List<Country>> fetchUnshownCountries() async {
    final all = await fetchAllCountries();
    final shownCodes = _historyService.getShownCountryCodes();
    final unshown =
        all.where((c) => !shownCodes.contains(c.isoCode)).toList();

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

    await _historyService.markCountryShown(correct.isoCode);

    return Question(correctCountry: correct, options: options);
  }
}
