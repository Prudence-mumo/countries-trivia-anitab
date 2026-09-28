import 'package:flutter/foundation.dart';
import '../models/country.dart';
import '../models/game_state.dart';
import '../models/question.dart';
import '../repositories/country_repository.dart';
import '../services/history_service.dart';
import '../utils/constants.dart';

/// Main game logic and state management.
class GameViewModel extends ChangeNotifier {
  final CountryRepository _repository;
  final HistoryService _historyService;

  // --- State ---
  GameState _gameState = GameState.loading;
  Question? _currentQuestion;
  int _score = 0;
  int _attemptsRemaining = AppConstants.maxAttempts;
  int _currentQuestionNumber = 0;
  int _totalQuestions = AppConstants.totalQuestionsPerRound;
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
    _attemptsRemaining = AppConstants.maxAttempts;
    _gameState = GameState.ready;
    notifyListeners();
  }

  void answerOption(Country selected) {
    if (_gameState != GameState.ready || _currentQuestion == null) return;

    if (_currentQuestion!.isCorrect(selected)) {
      int points = AppConstants.pointsTable[AppConstants.maxAttempts - _attemptsRemaining];
      _score += points;
      _lastAnswerCorrect = true;
      _feedbackMessage = 'Correct! +$points points';
      _gameState = GameState.answered;
      notifyListeners();
    } else {
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
    _attemptsRemaining = AppConstants.maxAttempts;
    _feedbackMessage = null;
    _lastAnswerCorrect = false;
    _initialize();
  }

  Future<void> _saveGameStats() async {
    await _historyService.saveHighScore(_score);
    await _historyService.incrementGamesPlayed();
  }
}
