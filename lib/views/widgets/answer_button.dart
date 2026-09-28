import 'package:flutter/material.dart';

/// Visual states for the answer button.
enum AnswerButtonState { defaultState, correct, incorrect, disabled }

/// A tappable answer option button with visual feedback states.
class AnswerButton extends StatelessWidget {
  final String text;
  final AnswerButtonState state;
  final VoidCallback? onPressed;

  const AnswerButton({
    super.key,
    required this.text,
    this.state = AnswerButtonState.defaultState,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor, textColor) = _colorsForState();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: state == AnswerButtonState.disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            side: BorderSide(color: borderColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: state == AnswerButtonState.defaultState ? 2 : 0,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color) _colorsForState() {
    switch (state) {
      case AnswerButtonState.defaultState:
        return (Colors.white, Colors.grey.shade300, Colors.black87);
      case AnswerButtonState.correct:
        return (Colors.green, Colors.green.shade700, Colors.white);
      case AnswerButtonState.incorrect:
        return (Colors.red, Colors.red.shade700, Colors.white);
      case AnswerButtonState.disabled:
        return (Colors.grey.shade200, Colors.grey.shade300, Colors.grey);
    }
  }
}
