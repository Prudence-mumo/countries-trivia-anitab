import 'package:flutter/material.dart';

/// Shows remaining attempts as dot indicators.
class AttemptsIndicator extends StatelessWidget {
  final int attemptsRemaining;
  final int maxAttempts;

  const AttemptsIndicator({
    super.key,
    required this.attemptsRemaining,
    this.maxAttempts = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxAttempts, (index) {
        final isActive = index < attemptsRemaining;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.circle,
            size: 16,
            color: isActive ? Colors.green : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
