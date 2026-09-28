import 'package:flutter/material.dart';

/// Semi-transparent overlay showing correct/incorrect feedback.
class FeedbackOverlay extends StatelessWidget {
  final bool isCorrect;
  final String message;

  const FeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    size: 64,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
