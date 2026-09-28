/// Represents the current state of the game.
enum GameState {
  /// Fetching countries / generating question.
  loading,

  /// Question displayed, awaiting user input.
  ready,

  /// User just answered (showing feedback).
  answered,

  /// All questions exhausted.
  gameOver,
}
