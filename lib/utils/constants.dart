/// App-wide constants.
class AppConstants {
  AppConstants._();

  // --- API ---
  static const String apiBaseUrl = 'https://api.restcountries.com/countries/v5';
  static const String apiKey = 'YOUR_API_KEY'; // TODO: Load from config

  // --- Flag CDN ---
  static const String flagCdnBaseUrl = 'http://flagcdn.com/w320';

  // --- SharedPreferences Keys ---
  static const String keyShownCountries = 'shown_country_codes';
  static const String keyHighScore = 'high_score';
  static const String keyTotalGamesPlayed = 'total_games_played';

  // --- Game Config ---
  static const int maxAttempts = 3;
  static const int optionsPerQuestion = 4;
  static const int totalQuestionsPerRound = 10;
  static const List<int> pointsTable = [10, 8, 5];
}
