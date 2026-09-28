# Country Trivia — Master Plan & Architecture

## 1. Project Overview

A Flutter mobile application that quizzes users on country identification. Each round displays a flag image and four country-name options. The user has three attempts to identify the correct country, with points awarded based on speed of correct identification.

### Core Gameplay Loop

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  App Start  │────▶│  Load Flags  │────▶│  Generate Quiz  │
└─────────────┘     └──────────────┘     └────────┬────────┘
                                                   │
                   ┌───────────────────────────────▼──────────┐
                   │           Display Flag + 4 Options        │
                   └───────────────────────────────┬──────────┘
                                                   │
                          ┌────────────────────────▼──────────┐
                          │        User Taps an Option         │
                          └────────────────────────┬──────────┘
                                                   │
              ┌────────────────────────────────────▼──────────────┐
              │              Evaluate Answer                       │
              └──────────┬───────────────────────────┬────────────┘
                         │                           │
                    Correct                      Incorrect
                         │                           │
              ┌──────────▼──────────┐    ┌───────────▼───────────┐
              │ Award Points        │    │ Decrement Attempts     │
              │ (10 / 8 / 5)        │    │ Show Correct if 0 left │
              │ Next Question       │    │ Next Question         │
              └─────────────────────┘    └───────────────────────┘
```

### Scoring System

| Attempt | Points |
|---------|--------|
| 1st (correct on first try) | 10 |
| 2nd (correct on second try) | 8 |
| 3rd (correct on third try) | 5 |
| Failed (all 3 attempts used) | 0 |

---

## 2. API Integration

### 2.1 Data Source — REST Countries API

> **Important Note:** The original v3.1 API (`https://restcountries.com/v3.1/all`) referenced in the Postman documentation has been **deprecated**. The API now requires migration to **v5** with an API key.

**New API Endpoint:**
```
GET https://api.restcountries.com/countries/v5?response_fields=names.common,codes.alpha_2&limit=100
Authorization: Bearer YOUR_API_KEY
```

**Response Structure (v5):**
```json
{
  "data": {
    "objects": [
      {
        "names": { "common": "United States" },
        "codes": { "alpha_2": "US" }
      }
    ],
    "meta": { "total": 249, "count": 100, "limit": 100, "offset": 0, "more": true }
  }
}
```

**Migration Strategy:**
- The app will use the v5 API with an API key stored in a configuration file
- A local fallback dataset (JSON asset) will be bundled with the app so it works offline and during development without an API key
- The repository layer will attempt the API first, then fall back to the bundled dataset

### 2.2 Flag Images — flagcdn.com

Flag images are loaded from the free Flag CDN:

```
http://flagcdn.com/w320/{iso_alpha_2_lowercase}.png
```

Example: `http://flagcdn.com/w320/us.png` for the United States.

The `{iso}` placeholder is the lowercase 2-letter ISO country code (e.g., `us`, `gb`, `jp`).

---

## 3. Architecture — MVVM with Provider

### 3.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         PRESENTATION LAYER                       │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  GamePage    │  │  GamePage    │  │  ResultDialog        │  │
│  │  (Stateless) │  │  Widgets     │  │  (Stateless)         │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
│         │                 │                      │               │
│         └────────┬────────┴──────────────────────┘               │
│                  │  Consumer / context.watch                     │
│                  ▼                                                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    VIEWMODEL LAYER                          │  │
│  │                                                            │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              GameViewModel (ChangeNotifier)           │  │  │
│  │  │                                                      │  │  │
│  │  │  - score: int                                        │  │  │
│  │  │  - currentQuestion: Question                         │  │  │
│  │  │  - attemptsRemaining: int                            │  │  │
│  │  │  - gameState: GameState                              │  │  │
│  │  │  - answerOption(String): void                        │  │  │
│  │  │  - nextQuestion(): void                              │  │  │
│  │  │  - resetGame(): void                                 │  │  │
│  │  └──────────────────────┬──────────────────────────────┘  │  │
│  └─────────────────────────┼─────────────────────────────────┘  │
│                            │                                     │
│                            │ uses                                 │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     DOMAIN LAYER                           │  │
│  │                                                            │  │
│  │  ┌─────────────────┐  ┌────────────────────────────────┐  │  │
│  │  │  Country Model  │  │  Question Model                │  │  │
│  │  │  - name: String │  │  - correctCountry: Country     │  │  │
│  │  │  - isoCode: Str │  │  - options: List<Country>      │  │  │
│  │  │  - flagUrl: Str │  │  - flagImageUrl: String        │  │  │
│  │  └────────┬────────┘  └──────────────┬─────────────────┘  │  │
│  │           │                          │                     │  │
│  │           └──────────┬───────────────┘                     │  │
│  │                      │ uses                                 │  │
│  │                      ▼                                     │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │           CountryRepository (Abstract)               │  │  │
│  │  │  + fetchAllCountries(): Future<List<Country>>        │  │  │
│  │  │  + generateQuestion(): Question                      │  │  │
│  │  └──────────────────────┬──────────────────────────────┘  │  │
│  └─────────────────────────┼─────────────────────────────────┘  │
│                            │                                     │
│                            │ implements                           │
│                            ▼                                     │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                      DATA LAYER                            │  │
│  │                                                            │  │
│  │  ┌──────────────────────┐  ┌───────────────────────────┐  │  │
│  │  │  ApiCountryRepository│  │  LocalCountryRepository   │  │  │
│  │  │  (REST API v5)       │  │  (Bundled JSON asset)     │  │  │
│  │  └──────────────────────┘  └───────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Layer Responsibilities

| Layer | Responsibility | Key Classes |
|-------|---------------|-------------|
| **Presentation** | Render UI, capture user input, display state | `GamePage`, `FlagImage`, `AnswerButton`, `ScoreBar`, `AttemptsIndicator` |
| **ViewModel** | Hold game state, orchestrate business logic, expose data to UI | `GameViewModel` |
| **Domain** | Define core business models and repository contracts | `Country`, `Question`, `CountryRepository` (abstract) |
| **Data** | Fetch data from API or local assets, map JSON to models | `ApiCountryRepository`, `LocalCountryRepository`, `ApiService` |

---

## 4. Directory Structure

```
lib/
├── main.dart                          # App entry point, Provider setup
├── app.dart                           # MaterialApp configuration
│
├── models/
│   ├── country.dart                   # Country data model
│   ├── question.dart                  # Question data model
│   └── game_state.dart                # GameState enum
│
├── services/
│   ├── api_service.dart               # HTTP client for REST Countries v5
│   ├── flag_service.dart              # Flag CDN URL builder
│   └── history_service.dart           # Persistence: tracks shown countries across sessions
│
├── repositories/
│   ├── country_repository.dart        # Abstract repository interface
│   ├── api_country_repository.dart    # API-backed implementation
│   └── local_country_repository.dart  # Local JSON asset implementation
│
├── viewmodels/
│   └── game_viewmodel.dart            # Main game logic & state
│
├── views/
│   ├── game_page.dart                 # Main game screen
│   └── widgets/
│       ├── flag_display.dart          # Flag image with loading/error states
│       ├── answer_button.dart         # Tappable answer option
│       ├── score_display.dart         # Current score widget
│       ├── attempts_indicator.dart    # Visual attempts remaining
│       ├── feedback_overlay.dart      # Correct/incorrect feedback
│       └── game_over_dialog.dart      # End-of-round summary
│
├── utils/
│   ├── constants.dart                 # App constants (API URL, CDN URL, etc.)
│   ├── theme.dart                     # ThemeData configuration
│   └── extensions.dart                # Useful extension methods
│
└── data/
    └── countries_fallback.json        # Bundled fallback dataset

assets/
└── data/
    └── countries.json                 # Full country dataset (fallback)

docs/
└── master_plan.md                     # This document

test/
├── models/
│   ├── country_test.dart
│   └── question_test.dart
├── repositories/
│   └── country_repository_test.dart
├── viewmodels/
│   └── game_viewmodel_test.dart
└── widgets/
    └── game_page_test.dart
```

---

## 5. Data Models

### 5.1 Country Model

```dart
class Country {
  final String name;       // Common name (e.g., "United States")
  final String isoCode;    // ISO 3166-1 alpha-2 (e.g., "US")

  const Country({required this.name, required this.isoCode});

  /// Flag image URL from flagcdn.com
  String get flagUrl => 'http://flagcdn.com/w320/${isoCode.toLowerCase()}.png';

  factory Country.fromJsonV5(Map<String, dynamic> json) {
    return Country(
      name: json['names']['common'] as String,
      isoCode: json['codes']['alpha_2'] as String,
    );
  }

  factory Country.fromJsonV3(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String,
      isoCode: json['cca2'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;
}
```

### 5.2 Question Model

```dart
class Question {
  final Country correctCountry;
  final List<Country> options;  // 4 options including the correct one

  const Question({
    required this.correctCountry,
    required this.options,
  });

  String get flagImageUrl => correctCountry.flagUrl;

  bool isCorrect(Country answer) => answer.isoCode == correctCountry.isoCode;
}
```

### 5.3 GameState Enum

```dart
enum GameState {
  loading,      // Fetching countries / generating question
  ready,       // Question displayed, awaiting user input
  answered,    // User just answered (showing feedback)
  gameOver,    // All questions exhausted (optional future feature)
}
```

---

## 6. ViewModel — GameViewModel

```dart
class GameViewModel extends ChangeNotifier {
  final CountryRepository _repository;
  final HistoryService _historyService;

  // --- State ---
  GameState _gameState = GameState.loading;
  Question? _currentQuestion;
  int _score = 0;
  int _attemptsRemaining = 3;
  int _currentQuestionNumber = 0;
  int _totalQuestions = 10;  // Configurable round length
  String? _feedbackMessage;
  bool _lastAnswerCorrect = false;

  // --- Getters ---
  GameState get gameState => _gameState;
  Question? get currentQuestion => _currentQuestion;
  int get score => _score;
  int get attemptsRemaining => _attemptsRemaining;
  int get currentQuestionNumber => _currentQuestionNumber;
  int get totalQuestions => _totalQuestions;
  String? get feedbackMessage => _feedbackMessage;
  bool get lastAnswerCorrect => _lastAnswerCorrect;
  int get totalCountriesShown => _historyService.shownCount;
  int get highScore => _historyService.highScore;

  // Points per attempt: [1st=10, 2nd=8, 3rd=5]
  static const List<int> pointsTable = [10, 8, 5];

  GameViewModel({
    required CountryRepository repository,
    required HistoryService historyService,
  })  : _repository = repository,
        _historyService = historyService {
    _initialize();
  }

  Future<void> _initialize() async {
    _gameState = GameState.loading;
    notifyListeners();
    await _generateNewQuestion();
  }

  Future<void> _generateNewQuestion() async {
    _currentQuestion = await _repository.generateQuestion();
    _attemptsRemaining = 3;
    _gameState = GameState.ready;
    notifyListeners();
  }

  void answerOption(Country selected) {
    if (_gameState != GameState.ready || _currentQuestion == null) return;

    if (_currentQuestion!.isCorrect(selected)) {
      // Correct answer
      int points = pointsTable[3 - _attemptsRemaining];
      _score += points;
      _lastAnswerCorrect = true;
      _feedbackMessage = 'Correct! +$points points';
      _gameState = GameState.answered;
      notifyListeners();
    } else {
      // Incorrect answer
      _attemptsRemaining--;
      _lastAnswerCorrect = false;
      if (_attemptsRemaining <= 0) {
        _feedbackMessage =
            'Out of attempts! The answer was ${_currentQuestion!.correctCountry.name}';
        _gameState = GameState.answered;
      } else {
        _feedbackMessage = 'Wrong! $_attemptsRemaining attempts remaining';
      }
      notifyListeners();
    }
  }

  Future<void> nextQuestion() async {
    _currentQuestionNumber++;
    if (_currentQuestionNumber >= _totalQuestions) {
      await _saveGameStats();
      _gameState = GameState.gameOver;
      notifyListeners();
      return;
    }
    await _generateNewQuestion();
  }

  void resetGame() {
    _score = 0;
    _currentQuestionNumber = 0;
    _attemptsRemaining = 3;
    _feedbackMessage = null;
    _lastAnswerCorrect = false;
    _initialize();
  }

  Future<void> _saveGameStats() async {
    await _historyService.saveHighScore(_score);
    await _historyService.incrementGamesPlayed();
  }
}
```

---

## 7. Repository Pattern

### 7.1 Abstract Interface

```dart
abstract class CountryRepository {
  Future<List<Country>> fetchAllCountries();
  Future<Question> generateQuestion();
}
```

### 7.2 API Implementation

```dart
class ApiCountryRepository implements CountryRepository {
  final ApiService _apiService;

  ApiCountryRepository(this._apiService);

  @override
  Future<List<Country>> fetchAllCountries() async {
    final response = await _apiService.fetchCountries();
    return response.map((json) => Country.fromJsonV5(json)).toList();
  }

  @override
  Future<Question> generateQuestion() async {
    final countries = await fetchAllCountries();
    return _buildQuestion(countries);
  }

  Question _buildQuestion(List<Country> countries) {
    final shuffled = List<Country>.from(countries)..shuffle();
    final correct = shuffled.first;
    final options = shuffled.take(4).toList()..shuffle();
    return Question(correctCountry: correct, options: options);
  }
}
```

### 7.3 Local Fallback Implementation

```dart
class LocalCountryRepository implements CountryRepository {
  List<Country>? _cachedCountries;

  @override
  Future<List<Country>> fetchAllCountries() async {
    if (_cachedCountries != null) return _cachedCountries!;
    final jsonString = await rootBundle.loadString('assets/data/countries.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _cachedCountries = jsonList
        .map((json) => Country.fromJsonV3(json as Map<String, dynamic>))
        .toList();
    return _cachedCountries!;
  }

  @override
  Future<Question> generateQuestion() async {
    final countries = await fetchAllCountries();
    // Same question generation logic
    ...
  }
}
```

### 7.4 Repository Factory (with fallback)

```dart
class CountryRepositoryFactory {
  static CountryRepository create() {
    final apiRepo = ApiCountryRepository(ApiService());
    final localRepo = LocalCountryRepository();
    return FallbackCountryRepository(
      primary: apiRepo,
      fallback: localRepo,
    );
  }
}
```

---

## 8. Cross-Session Persistence — Tracking Answered Flags

### 8.1 Problem Statement

Without persistence, the app would reshuffle all countries every time it launches, meaning users would see the same flags repeatedly across sessions. We need a mechanism to:

1. **Track which countries have been shown** across app restarts
2. **Exclude already-shown countries** from future question generation
3. **Reset the history** when all countries have been exhausted (or on user request)

### 8.2 Persistence Strategy — SharedPreferences

We use **SharedPreferences** for persistence because:

| Consideration | SharedPreferences |
|---------------|-------------------|
| Data size | ~250 ISO codes ≈ 750 bytes — well within limits |
| Complexity | Simple key-value store, no SQL schema needed |
| Performance | Negligible read/write cost for this data size |
| Reliability | Built into Flutter, backed by platform-native storage (NSUserDefaults on iOS, SharedPreferences on Android) |

**Why not SQLite/Hive?** Overkill for storing a simple list of strings. SharedPreferences is the lightest solution that meets our needs.

### 8.3 Data Format

```json
// Stored under key: "shown_country_codes"
["US", "GB", "DE", "JP", "FR", "BR", "IN", "AU", "CA", "IT"]
```

A simple `List<String>` of ISO alpha-2 codes, serialized as a JSON array.

### 8.4 HistoryService

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _keyShownCountries = 'shown_country_codes';
  static const String _keyHighScore = 'high_score';
  static const String _keyTotalGamesPlayed = 'total_games_played';

  final SharedPreferences _prefs;

  HistoryService(this._prefs);

  /// Factory that creates and initializes the service
  static Future<HistoryService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return HistoryService(prefs);
  }

  // --- Shown Countries ---

  /// Get all previously shown country ISO codes
  Set<String> getShownCountryCodes() {
    final jsonString = _prefs.getString(_keyShownCountries);
    if (jsonString == null) return {};
    final List<dynamic> list = json.decode(jsonString);
    return list.cast<String>().toSet();
  }

  /// Mark a country as shown (call when a question is displayed)
  Future<void> markCountryShown(String isoCode) async {
    final codes = getShownCountryCodes();
    codes.add(isoCode);
    await _prefs.setString(_keyShownCountries, json.encode(codes.toList()));
  }

  /// Get the count of unique countries shown
  int get shownCount => getShownCountryCodes().length;

  /// Check if a specific country has been shown before
  bool hasBeenShown(String isoCode) =>
      getShownCountryCodes().contains(isoCode);

  /// Reset all history (when all countries exhausted or user requests)
  Future<void> resetHistory() async {
    await _prefs.remove(_keyShownCountries);
  }

  // --- High Score ---

  int get highScore => _prefs.getInt(_keyHighScore) ?? 0;

  Future<void> saveHighScore(int score) async {
    if (score > highScore) {
      await _prefs.setInt(_keyHighScore, score);
    }
  }

  // --- Games Played ---

  int get totalGamesPlayed => _prefs.getInt(_keyTotalGamesPlayed) ?? 0;

  Future<void> incrementGamesPlayed() async {
    await _prefs.setInt(_keyTotalGamesPlayed, totalGamesPlayed + 1);
  }
}
```

### 8.5 Updated Repository Interface

The repository now accepts a `HistoryService` to filter out shown countries:

```dart
abstract class CountryRepository {
  Future<List<Country>> fetchAllCountries();
  Future<Question> generateQuestion();
  Future<List<Country>> fetchUnshownCountries();  // NEW
}
```

### 8.6 Updated Question Generation Logic

```dart
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
    final unshown = all.where((c) => !shownCodes.contains(c.isoCode)).toList();

    // If all countries have been shown, reset and start fresh
    if (unshown.length < 4) {
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
    // Pick 3 distractors from the remaining unshown countries
    final distractors = unshown.skip(1).take(3).toList();
    final options = [correct, ...distractors]..shuffle();

    // Mark the correct country as shown
    await _historyService.markCountryShown(correct.isoCode);

    return Question(correctCountry: correct, options: options);
  }
}
```

### 8.7 Updated ViewModel

```dart
class GameViewModel extends ChangeNotifier {
  final CountryRepository _repository;
  final HistoryService _historyService;

  // ... existing state fields ...

  // --- New Getters ---
  int get totalCountriesShown => _historyService.shownCount;
  int get highScore => _historyService.highScore;

  GameViewModel({
    required CountryRepository repository,
    required HistoryService historyService,
  })  : _repository = repository,
        _historyService = historyService {
    _initialize();
  }

  Future<void> _generateNewQuestion() async {
    _currentQuestion = await _repository.generateQuestion();
    _attemptsRemaining = 3;
    _gameState = GameState.ready;
    notifyListeners();
  }

  void resetGame() {
    _score = 0;
    _currentQuestionNumber = 0;
    _attemptsRemaining = 3;
    _feedbackMessage = null;
    _lastAnswerCorrect = false;
    _initialize();
  }

  /// Call when game ends to persist high score
  Future<void> _saveGameStats() async {
    await _historyService.saveHighScore(_score);
    await _historyService.incrementGamesPlayed();
  }
}
```

### 8.8 Updated Provider Setup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final historyService = await HistoryService.create();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameViewModel(
        repository: CountryRepositoryFactory.create(historyService),
        historyService: historyService,
      ),
      child: const CountryTriviaApp(),
    ),
  );
}
```

### 8.9 Reset Strategy

The history is reset in two scenarios:

| Scenario | Behavior |
|----------|----------|
| **All countries exhausted** | When fewer than 4 unshown countries remain, history is automatically reset and all countries become available again |
| **User-initiated reset** | A "Reset History" button in settings clears all shown countries |

### 8.10 Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    APP LAUNCH                                 │
│                                                              │
│  1. Load SharedPreferences                                    │
│  2. Read shown_country_codes → ["US","GB","DE",...]         │
│  3. Initialize HistoryService with saved data                │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                   QUESTION GENERATION                         │
│                                                              │
│  1. Fetch all countries from API/local                       │
│  2. Filter OUT countries whose ISO code is in shown set      │
│  3. If < 4 remain → reset history, use all countries        │
│  4. Randomly pick 1 correct + 3 distractors                  │
│  5. Save correct country's ISO code to SharedPreferences     │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                    APP TERMINATION                            │
│                                                              │
│  1. Save high score (if beaten)                              │
│  2. Increment games played counter                           │
│  3. SharedPreferences auto-persists to disk                  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. UI Design

### 8.1 Screen Layout

```
┌─────────────────────────────────────┐
│  ┌───────────────────────────────┐  │
│  │  Score: 45    Question 3/10   │  │  ← ScoreBar
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │                               │  │
│  │         [FLAG IMAGE]          │  │  ← FlagDisplay
│  │       (w320 resolution)       │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ●○○  Attempts: 3            │  │  ← AttemptsIndicator
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ┌─────────────────────────┐  │  │
│  │  │  United States          │  │  │  ← AnswerButton
│  │  └─────────────────────────┘  │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │  United Kingdom         │  │  │  ← AnswerButton
│  │  └─────────────────────────┘  │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │  Germany                │  │  │  ← AnswerButton
│  │  └─────────────────────────┘  │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │  Japan                  │  │  │  ← AnswerButton
│  │  └─────────────────────────┘  │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### 8.2 Widget Details

| Widget | Type | Description |
|--------|------|-------------|
| `GamePage` | `StatelessWidget` | Main screen, wraps `Consumer<GameViewModel>` |
| `FlagDisplay` | `StatelessWidget` | `Image.network` with loading spinner and error placeholder |
| `AnswerButton` | `StatelessWidget` | Material button with press animation, color-coded feedback |
| `ScoreDisplay` | `StatelessWidget` | Animated score counter |
| `AttemptsIndicator` | `StatelessWidget` | Dot indicators showing remaining attempts |
| `FeedbackOverlay` | `StatelessWidget` | Semi-transparent overlay for correct/incorrect feedback |
| `GameOverDialog` | `StatelessWidget` | `AlertDialog` showing final score and restart button |

### 8.3 Answer Button States

| State | Background | Border | Text |
|-------|-----------|--------|------|
| Default | White | Grey | Black |
| Pressed | Light grey | Grey | Black |
| Correct | Green | Dark green | White |
| Incorrect | Red | Dark red | White |
| Disabled | Light grey | Light grey | Grey |

### 8.4 Theme

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.light,
  ),
  fontFamily: 'Roboto',
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  ),
);
```

---

## 10. Dependencies

### 10.1 pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2          # State management
  http: ^1.2.2               # HTTP client for API calls
  cached_network_image: ^3.4.1  # Image caching for flags
  shared_preferences: ^2.3.3   # Cross-session persistence (shown countries, high score)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mockito: ^5.4.4            # Mocking for tests
  build_runner: ^2.4.13      # Code generation
```

### 10.2 Dependency Justification

| Package | Purpose |
|---------|---------|
| `provider` | Lightweight, official-recommended state management for MVVM |
| `http` | Simple HTTP client for REST API calls |
| `cached_network_image` | Cache flag images to reduce network requests and improve performance |
| `shared_preferences` | Persist shown country codes and high score across app sessions |
| `mockito` | Mock repositories and services in unit tests |

---

## 11. State Management with Provider

### 11.1 Provider Setup (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final historyService = await HistoryService.create();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameViewModel(
        repository: CountryRepositoryFactory.create(historyService),
        historyService: historyService,
      ),
      child: const CountryTriviaApp(),
    ),
  );
}
```

### 10.2 Consuming the ViewModel

```dart
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Country Trivia')),
      body: Consumer<GameViewModel>(
        builder: (context, viewModel, child) {
          switch (viewModel.gameState) {
            case GameState.loading:
              return const Center(child: CircularProgressIndicator());
            case GameState.ready:
            case GameState.answered:
              return _buildGameContent(context, viewModel);
            case GameState.gameOver:
              return _buildGameOver(context, viewModel);
          }
        },
      ),
    );
  }
}
```

---

## 12. API Service

### 11.1 ApiService

```dart
class ApiService {
  static const String _baseUrl = 'https://api.restcountries.com/countries/v5';
  static const String _apiKey = 'YOUR_API_KEY';  // Load from config

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> fetchCountries() async {
    final uri = Uri.parse(
      '$_baseUrl?response_fields=names.common,codes.alpha_2&limit=100',
    );

    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $_apiKey'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final objects = body['data']['objects'] as List<dynamic>;
      return objects.cast<Map<String, dynamic>>();
    } else {
      throw ApiException(
        'Failed to fetch countries: ${response.statusCode}',
        response.statusCode,
      );
    }
  }
}
```

### 11.2 Pagination Handling

The v5 API returns max 100 results per page. The app will fetch multiple pages:

```dart
Future<List<Map<String, dynamic>>> fetchAllCountries() async {
  final List<Map<String, dynamic>> allCountries = [];
  int offset = 0;
  const int limit = 100;
  bool hasMore = true;

  while (hasMore) {
    final uri = Uri.parse(
      '$_baseUrl?response_fields=names.common,codes.alpha_2&limit=$limit&offset=$offset',
    );
    final response = await _client.get(uri, headers: _headers);
    final body = json.decode(response.body);
    final objects = body['data']['objects'] as List<dynamic>;
    allCountries.addAll(objects.cast<Map<String, dynamic>>());
    hasMore = body['data']['meta']['more'] as bool;
    offset += limit;
  }

  return allCountries;
}
```

---

## 13. Error Handling

### 13.1 Error Types

| Error | Handling |
|-------|----------|
| Network unavailable | Show snackbar with retry option, use local fallback |
| API rate limited (429) | Exponential backoff, then fallback to local data |
| API server error (5xx) | Fallback to local data, log error |
| Image load failure | Show placeholder icon (flag outline) |
| Empty country list | Show error state with retry button |

### 13.2 Error State UI

```
┌─────────────────────────────────────┐
│                                     │
│           ⚠️                        │
│                                     │
│    Could not load countries.        │
│    Check your connection.           │
│                                     │
│    [ Retry ]                        │
│                                     │
└─────────────────────────────────────┘
```

---

## 14. Testing Strategy

### 14.1 Test Pyramid

```
            ┌─────────┐
            │   E2E   │  (Manual / integration test)
           ─┤─────────┤─
          ┌─┴─────────┴─┐
          │  Widget Test │  (GamePage interaction)
         ─┤─────────────┤─
        ┌─┴─────────────┴─┐
        │   Unit Tests     │  (ViewModel, Repository, Models)
        └──────────────────┘
```

### 14.2 Unit Tests

| Test File | What's Tested |
|-----------|--------------|
| `country_test.dart` | JSON parsing (v3 + v5), flag URL generation, equality |
| `question_test.dart` | Correct answer detection, option count |
| `game_viewmodel_test.dart` | Scoring logic, attempt tracking, state transitions, reset |
| `country_repository_test.dart` | Question generation, fallback behavior |
| `history_service_test.dart` | Save/load shown codes, reset history, high score persistence |

### 14.3 Widget Tests

| Test | Description |
|------|-------------|
| `game_page_test.dart` | Verify flag renders, 4 buttons present, tap updates score |
| `answer_button_test.dart` | Verify button states (default, correct, incorrect, disabled) |
| `attempts_indicator_test.dart` | Verify dot count matches attempts remaining |

### 14.4 ViewModel Test Example

```dart
test('correct answer on first attempt awards 10 points', () {
  final viewModel = GameViewModel(repository: mockRepository);
  // Wait for initialization
  await Future.delayed(Duration.zero);

  final question = viewModel.currentQuestion!;
  viewModel.answerOption(question.correctCountry);

  expect(viewModel.score, 10);
  expect(viewModel.lastAnswerCorrect, true);
});

test('three incorrect answers reveal correct answer', () {
  final viewModel = GameViewModel(repository: mockRepository);
  await Future.delayed(Duration.zero);

  final question = viewModel.currentQuestion!;
  final wrongOptions = question.options
      .where((o) => o.isoCode != question.correctCountry.isoCode)
      .toList();

  viewModel.answerOption(wrongOptions[0]);
  expect(viewModel.attemptsRemaining, 2);
  expect(viewModel.score, 0);

  viewModel.answerOption(wrongOptions[1]);
  expect(viewModel.attemptsRemaining, 1);

  viewModel.answerOption(wrongOptions[2]);
  expect(viewModel.attemptsRemaining, 0);
  expect(viewModel.feedbackMessage, contains('Out of attempts'));
});
```

---

## 15. Execution Tickets

### 15.1 Ticket Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        TICKET DEPENDENCY GRAPH                               │
│                                                                             │
│  T01 ──┬──▶ T02 ──┬──▶ T05 ──┬──▶ T08 ──┬──▶ T11 ──┬──▶ T14             │
│        │          │          │          │          │                      │
│        │          │          │          │          └──▶ T15             │
│        │          │          │          │                                 │
│        │          │          │          └──▶ T12 ──┬──▶ T16             │
│        │          │          │                     │                      │
│        │          │          │                     └──▶ T17             │
│        │          │          │                                        │
│        │          │          └──▶ T09 ──┬──▶ T13 ──┬──▶ T18             │
│        │          │                     │          │                      │
│        │          │                     │          └──▶ T19             │
│        │          │                     │                                 │
│        │          │                     └──▶ T10                           │
│        │          │                                                        │
│        │          └──▶ T06 ──┬──▶ T07                                      │
│        │                     │                                             │
│        │                     └──▶ T20                                      │
│        │                                                                    │
│        └──▶ T03 ──┬──▶ T04                                                │
│                     │                                                      │
│                     └──▶ T21                                                │
│                                                                             │
│  LEGEND:                                                                    │
│  ───────▶  depends on (must complete before)                                │
│                                                                             │
│  PARALLEL GROUPS:                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Wave 1:  T01 (alone — bootstraps everything)                        │   │
│  │ Wave 2:  T02, T03 (parallel — models + project setup)               │   │
│  │ Wave 3:  T04, T05, T06 (parallel — data layer components)           │   │
│  │ Wave 4:  T07, T08, T09 (parallel — repository + API + history)     │   │
│  │ Wave 5:  T10, T11, T12 (parallel — ViewModel + UI widgets)         │   │
│  │ Wave 6:  T13, T14, T15 (parallel — UI assembly + tests)            │   │
│  │ Wave 7:  T16, T17, T18 (parallel — tests + polish)                │   │
│  │ Wave 8:  T19, T20, T21 (parallel — final polish + release)          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 15.2 Ticket Details

---

#### T01 — Project Bootstrap & Dependency Setup
| Field | Value |
|-------|-------|
| **ID** | T01 |
| **Title** | Set up project structure and dependencies |
| **Priority** | P0 — Critical |
| **Depends on** | None |
| **Can parallelize with** | None (must be first) |
| **Est. effort** | 2h |

**Description:**
Create the folder structure, add all dependencies to `pubspec.yaml`, configure `analysis_options.yaml`, and ensure `flutter pub get` succeeds.

**Acceptance Criteria:**
- [ ] Folder structure created (`lib/models/`, `lib/services/`, `lib/repositories/`, `lib/viewmodels/`, `lib/views/`, `lib/views/widgets/`, `lib/utils/`, `assets/data/`)
- [ ] `pubspec.yaml` updated with: `provider`, `http`, `cached_network_image`, `shared_preferences`, `mockito`, `build_runner`
- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` passes with no issues
- [ ] `assets/data/` folder declared in `pubspec.yaml`

---

#### T02 — Data Models (Country, Question, GameState)
| Field | Value |
|-------|-------|
| **ID** | T02 |
| **Title** | Create core data models |
| **Priority** | P0 — Critical |
| **Depends on** | T01 |
| **Can parallelize with** | T03 |
| **Est. effort** | 3h |

**Description:**
Implement the three core domain models: `Country` (with v3/v5 JSON parsing, flag URL generation, equality), `Question` (with correct-answer detection), and `GameState` enum.

**Acceptance Criteria:**
- [ ] `Country` model with `name`, `isoCode`, `flagUrl` getter
- [ ] `Country.fromJsonV5()` factory for new API format
- [ ] `Country.fromJsonV3()` factory for legacy/fallback format
- [ ] `Country` equality based on `isoCode`
- [ ] `Question` model with `correctCountry`, `options`, `isCorrect()` method
- [ ] `GameState` enum with `loading`, `ready`, `answered`, `gameOver`
- [ ] Unit tests: `country_test.dart` — JSON parsing, flag URL, equality
- [ ] Unit tests: `question_test.dart` — correct detection, option count

---

#### T03 — Constants, Theme & Fallback Dataset
| Field | Value |
|-------|-------|
| **ID** | T03 |
| **Title** | Create constants, theme, and bundled fallback JSON |
| **Priority** | P1 — High |
| **Depends on** | T01 |
| **Can parallelize with** | T02 |
| **Est. effort** | 3h |

**Description:**
Create `constants.dart` (API URL, CDN URL, storage keys), `theme.dart` (Material 3 theme), and `assets/data/countries.json` (full country dataset for offline fallback).

**Acceptance Criteria:**
- [ ] `constants.dart` with API base URL, flag CDN pattern, SharedPreferences keys
- [ ] `theme.dart` with Material 3 `ThemeData` (indigo seed, button styles)
- [ ] `assets/data/countries.json` with all countries (name + ISO code)
- [ ] JSON file loads correctly via `rootBundle.loadString()`

---

#### T04 — API Service
| Field | Value |
|-------|-------|
| **ID** | T04 |
| **Title** | Implement ApiService with HTTP client |
| **Priority** | P0 — Critical |
| **Depends on** | T02, T03 |
| **Can parallelize with** | T05, T06 |
| **Est. effort** | 3h |

**Description:**
Implement `ApiService` with pagination support for the REST Countries v5 API. Handles HTTP requests, JSON parsing, and error handling.

**Acceptance Criteria:**
- [ ] `ApiService` with configurable `http.Client` (for testing)
- [ ] `fetchAllCountries()` with pagination (follows `meta.more`)
- [ ] Proper `Authorization: Bearer` header
- [ ] Response parsing: `data.objects[]` → `List<Map<String, dynamic>>`
- [ ] Error handling with custom `ApiException`
- [ ] Unit tests with mocked HTTP client

---

#### T05 — Country Repository Interface
| Field | Value |
|-------|-------|
| **ID** | T05 |
| **Title** | Define abstract CountryRepository interface |
| **Priority** | P0 — Critical |
| **Depends on** | T02 |
| **Can parallelize with** | T04, T06 |
| **Est. effort** | 1h |

**Description:**
Define the abstract `CountryRepository` interface that all data source implementations will follow.

**Acceptance Criteria:**
- [ ] Abstract class with `fetchAllCountries()`, `generateQuestion()`, `fetchUnshownCountries()`
- [ ] Documentation comments explaining each method's contract

---

#### T06 — History Service (SharedPreferences)
| Field | Value |
|-------|-------|
| **ID** | T06 |
| **Title** | Implement HistoryService for cross-session persistence |
| **Priority** | P0 — Critical |
| **Depends on** | T03 |
| **Can parallelize with** | T04, T05 |
| **Est. effort** | 3h |

**Description:**
Implement `HistoryService` wrapping `SharedPreferences` to persist shown country codes, high score, and games played across app sessions.

**Acceptance Criteria:**
- [ ] `HistoryService.create()` async factory
- [ ] `getShownCountryCodes()` → `Set<String>`
- [ ] `markCountryShown(isoCode)` — adds code and persists
- [ ] `resetHistory()` — clears all shown codes
- [ ] `hasBeenShown(isoCode)` → `bool`
- [ ] `shownCount` → `int`
- [ ] `highScore` getter + `saveHighScore(score)`
- [ ] `totalGamesPlayed` getter + `incrementGamesPlayed()`
- [ ] Unit tests: `history_service_test.dart` — save, load, reset, high score

---

#### T07 — API Country Repository
| Field | Value |
|-------|-------|
| **ID** | T07 |
| **Title** | Implement ApiCountryRepository |
| **Priority** | P0 — Critical |
| **Depends on** | T04, T05, T06 |
| **Can parallelize with** | T08, T09 |
| **Est. effort** | 3h |

**Description:**
Implement `ApiCountryRepository` that fetches from the REST API, filters out shown countries, and generates questions with no-repeat logic.

**Acceptance Criteria:**
- [ ] Implements `CountryRepository`
- [ ] `fetchAllCountries()` delegates to `ApiService`
- [ ] `fetchUnshownCountries()` filters using `HistoryService`
- [ ] Auto-resets history when < 4 unshown countries remain
- [ ] `generateQuestion()` picks 1 correct + 3 distractors, marks as shown
- [ ] Unit tests: `api_country_repository_test.dart`

---

#### T08 — Local Country Repository
| Field | Value |
|-------|-------|
| **ID** | T08 |
| **Title** | Implement LocalCountryRepository (offline fallback) |
| **Priority** | P1 — High |
| **Depends on** | T03, T05, T06 |
| **Can parallelize with** | T07, T09 |
| **Est. effort** | 2h |

**Description:**
Implement `LocalCountryRepository` that loads from the bundled JSON asset. Used when the API is unavailable.

**Acceptance Criteria:**
- [ ] Implements `CountryRepository`
- [ ] Loads from `assets/data/countries.json` via `rootBundle`
- [ ] Caches parsed countries in memory
- [ ] Same question generation logic as API repository
- [ ] Unit tests: `local_country_repository_test.dart`

---

#### T09 — Fallback Repository & Factory
| Field | Value |
|-------|-------|
| **ID** | T09 |
| **Title** | Implement FallbackCountryRepository and factory |
| **Priority** | P0 — Critical |
| **Depends on** | T07, T08 |
| **Can parallelize with** | T10, T11 |
| **Est. effort** | 2h |

**Description:**
Implement `FallbackCountryRepository` that tries the API first and falls back to local data on failure. Plus the `CountryRepositoryFactory`.

**Acceptance Criteria:**
- [ ] `FallbackCountryRepository` wraps primary + fallback repos
- [ ] Tries primary first, catches exceptions, falls back
- [ ] `CountryRepositoryFactory.create(historyService)` returns configured repo
- [ ] Unit tests: `fallback_country_repository_test.dart`

---

#### T10 — GameViewModel
| Field | Value |
|-------|-------|
| **ID** | T10 |
| **Title** | Implement GameViewModel with full game logic |
| **Priority** | P0 — Critical |
| **Depends on** | T05, T06 |
| **Can parallelize with** | T11, T12 |
| **Est. effort** | 4h |

**Description:**
Implement `GameViewModel` (ChangeNotifier) with scoring, attempt tracking, question generation, and history integration.

**Acceptance Criteria:**
- [ ] All state fields: `gameState`, `currentQuestion`, `score`, `attemptsRemaining`, etc.
- [ ] `answerOption(Country)` — correct awards 10/8/5, incorrect decrements attempts
- [ ] `nextQuestion()` — advances or triggers game over
- [ ] `resetGame()` — resets all state
- [ ] `_saveGameStats()` — persists high score and games played
- [ ] Comprehensive unit tests: `game_viewmodel_test.dart`
  - [ ] Correct answer on 1st attempt → 10 points
  - [ ] Correct answer on 2nd attempt → 8 points
  - [ ] Correct answer on 3rd attempt → 5 points
  - [ ] 3 incorrect answers → 0 points, correct answer revealed
  - [ ] Reset restores initial state

---

#### T11 — Flag Display Widget
| Field | Value |
|-------|-------|
| **ID** | T11 |
| **Title** | Implement FlagDisplay widget |
| **Priority** | P1 — High |
| **Depends on** | T03 |
| **Can parallelize with** | T10, T12 |
| **Est. effort** | 2h |

**Description:**
Create the `FlagDisplay` widget that renders flag images from flagcdn.com with loading and error states.

**Acceptance Criteria:**
- [ ] Uses `CachedNetworkImage` for network image loading
- [ ] Shows `CircularProgressIndicator` while loading
- [ ] Shows placeholder icon on error
- [ ] Accepts `imageUrl` parameter
- [ ] Widget test: loading, success, error states

---

#### T12 — Answer Button Widget
| Field | Value |
|-------|-------|
| **ID** | T12 |
| **Title** | Implement AnswerButton widget |
| **Priority** | P1 — High |
| **Depends on** | T03 |
| **Can parallelize with** | T10, T11 |
| **Est. effort** | 2h |

**Description:**
Create the `AnswerButton` widget with visual states for default, correct, incorrect, and disabled.

**Acceptance Criteria:**
- [ ] Accepts `text`, `state`, `onPressed` parameters
- [ ] Visual states: default (white), correct (green), incorrect (red), disabled (grey)
- [ ] Press animation/feedback
- [ ] Disabled state prevents taps
- [ ] Widget test: all four visual states

---

#### T13 — Score & Attempts Widgets
| Field | Value |
|-------|-------|
| **ID** | T13 |
| **Title** | Implement ScoreDisplay and AttemptsIndicator widgets |
| **Priority** | P2 — Medium |
| **Depends on** | T03 |
| **Can parallelize with** | T14, T15 |
| **Est. effort** | 2h |

**Description:**
Create the `ScoreDisplay` (animated score counter) and `AttemptsIndicator` (dot indicators) widgets.

**Acceptance Criteria:**
- [ ] `ScoreDisplay` shows current score with count-up animation
- [ ] `AttemptsIndicator` shows 3 dots, filled = remaining attempts
- [ ] Widget tests for both

---

#### T14 — Game Page Assembly
| Field | Value |
|-------|-------|
| **ID** | T14 |
| **Title** | Implement GamePage with Provider consumer |
| **Priority** | P0 — Critical |
| **Depends on** | T10, T11, T12 |
| **Can parallelize with** | T13, T15 |
| **Est. effort** | 3h |

**Description:**
Assemble the main `GamePage` screen using `Consumer<GameViewModel>`, integrating all widgets.

**Acceptance Criteria:**
- [ ] `Scaffold` with `AppBar` (title: "Country Trivia")
- [ ] `Consumer<GameViewModel>` switches on `gameState`
- [ ] Loading state → `CircularProgressIndicator`
- [ ] Ready/answered state → flag + options layout
- [ ] Game over state → `GameOverDialog`
- [ ] Responsive layout (works on small and large screens)

---

#### T15 — Feedback Overlay & Game Over Dialog
| Field | Value |
|-------|-------|
| **ID** | T15 |
| **Title** | Implement FeedbackOverlay and GameOverDialog |
| **Priority** | P1 — High |
| **Depends on** | T10 |
| **Can parallelize with** | T13, T14 |
| **Est. effort** | 2h |

**Description:**
Create the `FeedbackOverlay` (correct/incorrect feedback) and `GameOverDialog` (final score + restart).

**Acceptance Criteria:**
- [ ] `FeedbackOverlay` shows green/red overlay with message
- [ ] `GameOverDialog` shows final score, high score, restart button
- [ ] "Next Question" button appears after feedback
- [ ] Widget tests for both

---

#### T16 — Widget Tests
| Field | Value |
|-------|-------|
| **ID** | T16 |
| **Title** | Write comprehensive widget tests |
| **Priority** | P1 — High |
| **Depends on** | T14, T15 |
| **Can parallelize with** | T17, T18 |
| **Est. effort** | 3h |

**Description:**
Write widget tests covering the full user interaction flow.

**Acceptance Criteria:**
- [ ] `game_page_test.dart` — flag renders, 4 buttons present
- [ ] Tap correct answer → score updates
- [ ] Tap incorrect answer → attempts decrement
- [ ] 3 incorrect → correct answer revealed
- [ ] "Next Question" advances to new question
- [ ] Game over → dialog appears with final score
- [ ] All tests pass

---

#### T17 — Animations & Polish
| Field | Value |
|-------|-------|
| **ID** | T17 |
| **Title** | Add animations and visual polish |
| **Priority** | P2 — Medium |
| **Depends on** | T14 |
| **Can parallelize with** | T16, T18 |
| **Est. effort** | 3h |

**Description:**
Add animations for score count-up, button press feedback, flag fade-in, and transitions.

**Acceptance Criteria:**
- [ ] Score count-up animation
- [ ] Flag fade-in on question change
- [ ] Button press scale animation
- [ ] Smooth transitions between questions
- [ ] No jank (60fps maintained)

---

#### T18 — Error Handling & Edge Cases
| Field | Value |
|-------|-------|
| **ID** | T18 |
| **Title** | Implement error handling and edge case management |
| **Priority** | P1 — High |
| **Depends on** | T14 |
| **Can parallelize with** | T16, T17 |
| **Est. effort** | 2h |

**Description:**
Handle all error states: network failure, API errors, image load failure, empty data.

**Acceptance Criteria:**
- [ ] Network unavailable → snackbar with retry, fallback to local
- [ ] API rate limited → exponential backoff, then fallback
- [ ] Image load failure → placeholder icon
- [ ] Empty country list → error state with retry button
- [ ] All error states tested

---

#### T19 — Performance Optimization
| Field | Value |
|-------|-------|
| **ID** | T19 |
| **Title** | Performance optimization and image caching |
| **Priority** | P2 — Medium |
| **Depends on** | T14 |
| **Can parallelize with** | T20, T21 |
| **Est. effort** | 2h |

**Description:**
Optimize app performance with image caching, efficient rebuilds, and memory management.

**Acceptance Criteria:**
- [ ] `CachedNetworkImage` properly configured
- [ ] `const` constructors used where possible
- [ ] `Consumer` scoped to minimize rebuilds
- [ ] No memory leaks (dispose controllers)
- [ ] App launches in < 2s

---

#### T20 — Sound & Haptic Feedback
| Field | Value |
|-------|-------|
| **ID** | T20 |
| **Title** | Add sound effects and haptic feedback |
| **Priority** | P3 — Low (Optional) |
| **Depends on** | T14 |
| **Can parallelize with** | T19, T21 |
| **Est. effort** | 2h |

**Description:**
Add sound effects for correct/incorrect answers and haptic feedback on button presses.

**Acceptance Criteria:**
- [ ] Correct answer sound
- [ ] Incorrect answer sound
- [ ] Haptic feedback on tap
- [ ] Mute toggle in settings (if time permits)

---

#### T21 — Final Testing & Release
| Field | Value |
|-------|-------|
| **ID** | T21 |
| **Title** | Final testing, bug fixes, and release preparation |
| **Priority** | P0 — Critical |
| **Depends on** | T16, T17, T18, T19, T20 |
| **Can parallelize with** | None (must be last) |
| **Est. effort** | 3h |

**Description:**
Comprehensive final testing, bug fixing, and preparation for release.

**Acceptance Criteria:**
- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] `flutter analyze` passes with no issues
- [ ] Manual testing on Android and iOS
- [ ] No known bugs
- [ ] README updated with setup instructions
- [ ] App icon and splash screen configured

---

### 15.3 Execution Waves

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EXECUTION WAVES                                      │
│                                                                             │
│  WAVE 1 (Sequential)                                                        │
│  ┌─────┐                                                                   │
│  │ T01 │  Project bootstrap & dependencies                                  │
│  └──┬──┘                                                                   │
│     │                                                                      │
│  WAVE 2 (Parallel)                                                          │
│  ┌─────┐ ┌─────┐                                                           │
│  │ T02 │ │ T03 │  Models + Constants/Theme/Dataset                        │
│  └──┬──┘ └──┬──┘                                                           │
│     │       │                                                              │
│  WAVE 3 (Parallel)                                                          │
│  ┌─────┐ ┌─────┐ ┌─────┐                                                   │
│  │ T04 │ │ T05 │ │ T06 │  API Service + Repository Interface + History      │
│  └──┬──┘ └──┬──┘ └──┬──┘                                                   │
│     │       │       │                                                        │
│  WAVE 4 (Parallel)                                                          │
│  ┌─────┐ ┌─────┐ ┌─────┐                                                   │
│  │ T07 │ │ T08 │ │ T09 │  API Repo + Local Repo + Fallback/Factory         │
│  └──┬──┘ └──┬──┘ └──┬──┘                                                   │
│     │       │       │                                                        │
│  WAVE 5 (Parallel)                                                          │
│  ┌─────┐ ┌─────┐ ┌─────┐                                                   │
│  │ T10 │ │ T11 │ │ T12 │  ViewModel + FlagDisplay + AnswerButton           │
│  └──┬──┘ └──┬──┘ └──┬──┘                                                   │
│     │       │       │                                                        │
│  WAVE 6 (Parallel)                                                          │
│  ┌─────┐ ┌─────┐ ┌─────┐                                                   │
│  │ T13 │ │ T14 │ │ T15 │  Score/Attempts + GamePage + Feedback/Dialog      │
│  └──┬──┘ └──┬──┘ └──┬──┘                                                   │
│     │       │       │                                                        │
│  WAVE 7 (Parallel)                                                          │
│  ┌─────┐ ┌─────┐ ┌─────┐                                                   │
│  │ T16 │ │ T17 │ │ T18 │  Widget Tests + Animations + Error Handling       │
│  └──┬──┘ └──┬──┘ └──┬──┘                                                   │
│     │       │       │                                                        │
│  WAVE 8 (Parallel)                                                          │
│  ┌─────┐ ┌─────┐ ┌─────┐                                                   │
│  │ T19 │ │ T20 │ │ T21 │  Performance + Sound + Final Testing              │
│  └─────┘ └─────┘ └─────┘                                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 15.4 Ticket Summary Table

| Ticket | Title | Priority | Depends On | Parallel With | Wave | Est. |
|--------|-------|----------|------------|---------------|------|------|
| T01 | Project Bootstrap & Dependencies | P0 | — | — | 1 | 2h |
| T02 | Data Models | P0 | T01 | T03 | 2 | 3h |
| T03 | Constants, Theme & Fallback JSON | P1 | T01 | T02 | 2 | 3h |
| T04 | API Service | P0 | T02, T03 | T05, T06 | 3 | 3h |
| T05 | Repository Interface | P0 | T02 | T04, T06 | 3 | 1h |
| T06 | History Service | P0 | T03 | T04, T05 | 3 | 3h |
| T07 | API Country Repository | P0 | T04, T05, T06 | T08, T09 | 4 | 3h |
| T08 | Local Country Repository | P1 | T03, T05, T06 | T07, T09 | 4 | 2h |
| T09 | Fallback Repo & Factory | P0 | T07, T08 | T10, T11 | 4 | 2h |
| T10 | GameViewModel | P0 | T05, T06 | T11, T12 | 5 | 4h |
| T11 | Flag Display Widget | P1 | T03 | T10, T12 | 5 | 2h |
| T12 | Answer Button Widget | P1 | T03 | T10, T11 | 5 | 2h |
| T13 | Score & Attempts Widgets | P2 | T03 | T14, T15 | 6 | 2h |
| T14 | Game Page Assembly | P0 | T10, T11, T12 | T13, T15 | 6 | 3h |
| T15 | Feedback Overlay & Game Over Dialog | P1 | T10 | T13, T14 | 6 | 2h |
| T16 | Widget Tests | P1 | T14, T15 | T17, T18 | 7 | 3h |
| T17 | Animations & Polish | P2 | T14 | T16, T18 | 7 | 3h |
| T18 | Error Handling & Edge Cases | P1 | T14 | T16, T17 | 7 | 2h |
| T19 | Performance Optimization | P2 | T14 | T20, T21 | 8 | 2h |
| T20 | Sound & Haptic Feedback | P3 | T14 | T19, T21 | 8 | 2h |
| T21 | Final Testing & Release | P0 | T16–T20 | — | 8 | 3h |

**Total estimated effort:** ~52 hours (~6.5 working days)

---

## 16. Implementation Phases

### Phase 1: Foundation (Day 1)
- [ ] Set up project structure (folders, `pubspec.yaml` dependencies)
- [ ] Create data models (`Country`, `Question`, `GameState`)
- [ ] Create constants and theme
- [ ] Create fallback JSON dataset (`assets/data/countries.json`)

### Phase 2: Data Layer (Day 1-2)
- [ ] Implement `ApiService` with HTTP client
- [ ] Implement `CountryRepository` abstract interface
- [ ] Implement `ApiCountryRepository`
- [ ] Implement `LocalCountryRepository`
- [ ] Implement `FallbackCountryRepository`
- [ ] Implement `HistoryService` with SharedPreferences
- [ ] Write unit tests for models and repositories

### Phase 3: ViewModel (Day 2)
- [ ] Implement `GameViewModel` with full game logic
- [ ] Integrate `HistoryService` into ViewModel
- [ ] Write comprehensive unit tests for ViewModel
- [ ] Verify scoring system (10/8/5 points)
- [ ] Verify no-repeat logic across sessions

### Phase 4: UI Layer (Day 2-3)
- [ ] Implement `GamePage` with Provider consumer
- [ ] Implement `FlagDisplay` widget with loading/error states
- [ ] Implement `AnswerButton` widget with visual states
- [ ] Implement `ScoreDisplay` and `AttemptsIndicator`
- [ ] Implement `FeedbackOverlay` for correct/incorrect feedback
- [ ] Implement `GameOverDialog`
- [ ] Write widget tests

### Phase 5: Polish (Day 3)
- [ ] Add animations (score count-up, button press, flag fade-in)
- [ ] Add sound effects (correct/wrong buzzer) — optional
- [ ] Add haptic feedback on answer
- [ ] Error handling and edge cases
- [ ] Performance optimization (image caching)
- [ ] Final testing and bug fixes

---

## 16. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Provider over Bloc/Riverpod** | Simpler learning curve, sufficient for this app's complexity, officially recommended by Flutter team |
| **Repository pattern** | Decouples data source from ViewModel; enables easy switching between API and local data |
| **Fallback local dataset** | App works offline and during development without API key |
| **CachedNetworkImage** | Reduces network requests for flag images, improves performance |
| **ChangeNotifier** | Simplest Provider integration; sufficient for single-ViewModel app |
| **4 options per question** | Standard multiple-choice format; balances difficulty and playability |
| **3 attempts with decreasing points** | Rewards knowledge while giving learning opportunity |
| **SharedPreferences for persistence** | Lightweight key-value storage ideal for tracking ~250 ISO codes; no SQL overhead needed |
| **Auto-reset on exhaustion** | When < 4 unshown countries remain, history resets automatically so the game never gets stuck |

---

## 17. Future Enhancements

| Feature | Description |
|---------|-------------|
| Difficulty levels | Easy (3 options), Medium (4 options), Hard (6 options) |
| Regional filtering | Quiz on specific continents/regions |
| Timed mode | Answer within 10 seconds for bonus points |
| Streak multiplier | Consecutive correct answers multiply points |
| Leaderboard | Local high scores with SharedPreferences |
| Daily challenge | One special question per day |
| Accessibility | Screen reader support, high contrast mode |
| Localization | Multi-language support |
| Statistics | Track accuracy, best streak, countries missed |

---

## 18. Summary

This document provides a complete blueprint for building the Country Trivia Flutter app using MVVM architecture with Provider state management. The app will:

1. Fetch country data from the REST Countries v5 API (with local fallback)
2. Display flag images from flagcdn.com
3. Present 4-option multiple-choice questions
4. Award 10, 8, or 5 points based on attempt number
5. Reveal the correct answer after 3 failed attempts
6. **Track shown countries across sessions** using SharedPreferences to prevent flag repetition
7. Persist high score and games played across app restarts
8. Run on both Android and iOS

The architecture is designed for testability, maintainability, and extensibility, with clear separation of concerns across all layers.
