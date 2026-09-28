import 'package:flutter/material.dart';

/// Displays the current score with animation.
class ScoreDisplay extends StatelessWidget {
  final int score;
  final int questionNumber;
  final int totalQuestions;

  const ScoreDisplay({
    super.key,
    required this.score,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Score: $score',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Question $questionNumber/$totalQuestions',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
