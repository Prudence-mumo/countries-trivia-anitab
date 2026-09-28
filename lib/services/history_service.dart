import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Persists shown country codes, high score, and games played across sessions.
class HistoryService {
  final SharedPreferences _prefs;

  HistoryService(this._prefs);

  /// Factory that creates and initializes the service.
  static Future<HistoryService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return HistoryService(prefs);
  }

  // --- Shown Countries ---

  /// Get all previously shown country ISO codes.
  Set<String> getShownCountryCodes() {
    final jsonString = _prefs.getString(AppConstants.keyShownCountries);
    if (jsonString == null) return {};
    final List<dynamic> list = json.decode(jsonString);
    return list.cast<String>().toSet();
  }

  /// Mark a country as shown (call when a question is displayed).
  Future<void> markCountryShown(String isoCode) async {
    final codes = getShownCountryCodes();
    codes.add(isoCode);
    await _prefs.setString(
      AppConstants.keyShownCountries,
      json.encode(codes.toList()),
    );
  }

  /// Get the count of unique countries shown.
  int get shownCount => getShownCountryCodes().length;

  /// Check if a specific country has been shown before.
  bool hasBeenShown(String isoCode) =>
      getShownCountryCodes().contains(isoCode);

  /// Reset all history (when all countries exhausted or user requests).
  Future<void> resetHistory() async {
    await _prefs.remove(AppConstants.keyShownCountries);
  }

  // --- High Score ---

  int get highScore => _prefs.getInt(AppConstants.keyHighScore) ?? 0;

  Future<void> saveHighScore(int score) async {
    if (score > highScore) {
      await _prefs.setInt(AppConstants.keyHighScore, score);
    }
  }

  // --- Games Played ---

  int get totalGamesPlayed =>
      _prefs.getInt(AppConstants.keyTotalGamesPlayed) ?? 0;

  Future<void> incrementGamesPlayed() async {
    await _prefs.setInt(
      AppConstants.keyTotalGamesPlayed,
      totalGamesPlayed + 1,
    );
  }
}
