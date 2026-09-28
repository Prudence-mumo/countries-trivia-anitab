import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../viewmodels/game_viewmodel.dart';
import 'widgets/answer_button.dart';
import 'widgets/attempts_indicator.dart';
import 'widgets/feedback_overlay.dart';
import 'widgets/flag_display.dart';
import 'widgets/game_over_dialog.dart';
import 'widgets/score_display.dart';

/// Main game screen.
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  String? _lastShownMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Trivia'),
        centerTitle: true,
      ),
      body: Consumer<GameViewModel>(
        builder: (context, viewModel, child) {
          // Show snackbar for incorrect answers with remaining attempts
          if (viewModel.feedbackMessage != null &&
              viewModel.feedbackMessage != _lastShownMessage &&
              viewModel.gameState == GameState.ready) {
            _lastShownMessage = viewModel.feedbackMessage;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.feedbackMessage!),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            });
          }

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

  Widget _buildGameContent(BuildContext context, GameViewModel viewModel) {
    final question = viewModel.currentQuestion;
    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ScoreDisplay(
                score: viewModel.score,
                questionNumber: viewModel.currentQuestionNumber + 1,
                totalQuestions: viewModel.totalQuestions,
              ),
              const SizedBox(height: 16),
              FlagDisplay(imageUrl: question.flagImageUrl),
              const SizedBox(height: 16),
              AttemptsIndicator(attemptsRemaining: viewModel.attemptsRemaining),
              const SizedBox(height: 16),
              ...question.options.map((option) {
                final isCorrect = option.isoCode == question.correctCountry.isoCode;
                final isAnswered = viewModel.gameState == GameState.answered;

                AnswerButtonState state;
                if (isAnswered && isCorrect) {
                  state = AnswerButtonState.correct;
                } else if (isAnswered && viewModel.lastAnswerCorrect) {
                  state = AnswerButtonState.correct;
                } else if (isAnswered) {
                  state = AnswerButtonState.disabled;
                } else {
                  state = AnswerButtonState.defaultState;
                }

                return AnswerButton(
                  text: option.name,
                  state: state,
                  onPressed: () => viewModel.answerOption(option),
                );
              }),
              if (viewModel.gameState == GameState.answered) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => viewModel.nextQuestion(),
                    child: Text(
                      viewModel.currentQuestionNumber + 1 >= viewModel.totalQuestions
                          ? 'See Results'
                          : 'Next Question',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (viewModel.gameState == GameState.answered && viewModel.feedbackMessage != null)
          FeedbackOverlay(
            isCorrect: viewModel.lastAnswerCorrect,
            message: viewModel.feedbackMessage!,
          ),
      ],
    );
  }

  Widget _buildGameOver(BuildContext context, GameViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameOverDialog(
          finalScore: viewModel.score,
          highScore: viewModel.highScore,
          onRestart: () {
            Navigator.of(context).pop();
            viewModel.resetGame();
          },
        ),
      );
    });

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Game Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
