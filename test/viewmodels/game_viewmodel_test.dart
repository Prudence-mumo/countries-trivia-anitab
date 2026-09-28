import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/models/game_state.dart';
import 'package:country_trivia/models/question.dart';
import 'package:country_trivia/repositories/country_repository.dart';
import 'package:country_trivia/services/history_service.dart';
import 'package:country_trivia/viewmodels/game_viewmodel.dart';

class _FakeRepository implements CountryRepository {
  int _callCount = 0;

  @override
  Future<List<Country>> fetchAllCountries() async => const [];

  @override
  Future<List<Country>> fetchUnshownCountries() async => const [];

  @override
  Future<Question> generateQuestion() async {
    _callCount++;
    final correct = Country(name: 'Country$_callCount', isoCode: 'C$_callCount');
    return Question(
      correctCountry: correct,
      options: [
        correct,
        const Country(name: 'Wrong1', isoCode: 'W1'),
        const Country(name: 'Wrong2', isoCode: 'W2'),
        const Country(name: 'Wrong3', isoCode: 'W3'),
      ],
    );
  }
}

void main() {
  late GameViewModel viewModel;
  late _FakeRepository fakeRepository;
  late HistoryService historyService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    historyService = await HistoryService.create();
    fakeRepository = _FakeRepository();
    viewModel = GameViewModel(
      repository: fakeRepository,
      historyService: historyService,
    );
    await Future.delayed(Duration.zero);
  });

  group('GameViewModel', () {
    test('initial state is ready with question', () {
      expect(viewModel.gameState, GameState.ready);
      expect(viewModel.score, 0);
      expect(viewModel.attemptsRemaining, 3);
      expect(viewModel.currentQuestion, isNotNull);
    });

    test('correct answer on first attempt awards 10 points', () {
      final question = viewModel.currentQuestion!;
      viewModel.answerOption(question.correctCountry);

      expect(viewModel.score, 10);
      expect(viewModel.lastAnswerCorrect, true);
      expect(viewModel.gameState, GameState.answered);
    });

    test('correct answer on second attempt awards 8 points', () {
      final question = viewModel.currentQuestion!;
      final wrong = question.options.firstWhere(
        (o) => o.isoCode != question.correctCountry.isoCode,
      );

      viewModel.answerOption(wrong);
      expect(viewModel.attemptsRemaining, 2);
      expect(viewModel.score, 0);

      viewModel.answerOption(question.correctCountry);
      expect(viewModel.score, 8);
      expect(viewModel.lastAnswerCorrect, true);
    });

    test('correct answer on third attempt awards 5 points', () {
      final question = viewModel.currentQuestion!;
      final wrongs = question.options
          .where((o) => o.isoCode != question.correctCountry.isoCode)
          .toList();

      viewModel.answerOption(wrongs[0]);
      viewModel.answerOption(wrongs[1]);
      expect(viewModel.attemptsRemaining, 1);

      viewModel.answerOption(question.correctCountry);
      expect(viewModel.score, 5);
    });

    test('three incorrect answers reveals correct answer', () {
      final question = viewModel.currentQuestion!;
      final wrongs = question.options
          .where((o) => o.isoCode != question.correctCountry.isoCode)
          .toList();

      viewModel.answerOption(wrongs[0]);
      viewModel.answerOption(wrongs[1]);
      viewModel.answerOption(wrongs[2]);

      expect(viewModel.attemptsRemaining, 0);
      expect(viewModel.score, 0);
      expect(viewModel.feedbackMessage, contains('Out of attempts'));
      expect(viewModel.feedbackMessage, contains(question.correctCountry.name));
    });

    test('nextQuestion advances question number', () async {
      final initialNumber = viewModel.currentQuestionNumber;
      await viewModel.nextQuestion();
      expect(viewModel.currentQuestionNumber, initialNumber + 1);
    });

    test('resetGame restores initial state', () {
      final question = viewModel.currentQuestion!;
      viewModel.answerOption(question.correctCountry);
      expect(viewModel.score, 10);

      viewModel.resetGame();
      expect(viewModel.score, 0);
      expect(viewModel.attemptsRemaining, 3);
      expect(viewModel.currentQuestionNumber, 0);
    });

    test('saves high score on game over', () async {
      final question = viewModel.currentQuestion!;
      viewModel.answerOption(question.correctCountry);
      expect(viewModel.score, 10);

      // Advance through all remaining questions
      for (int i = 0; i < 10; i++) {
        await viewModel.nextQuestion();
      }

      expect(viewModel.gameState, GameState.gameOver);
      expect(historyService.highScore, 10);
      expect(historyService.totalGamesPlayed, 1);
    });
  });
}
