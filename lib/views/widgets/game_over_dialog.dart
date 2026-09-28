import 'package:flutter/material.dart';

/// Dialog shown when the game ends with final score and restart option.
class GameOverDialog extends StatelessWidget {
  final int finalScore;
  final int highScore;
  final VoidCallback onRestart;

  const GameOverDialog({
    super.key,
    required this.finalScore,
    required this.highScore,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Game Over!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Final Score: $finalScore',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'High Score: $highScore',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRestart();
          },
          child: const Text('Play Again'),
        ),
      ],
    );
  }
}
