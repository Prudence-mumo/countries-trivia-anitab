import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'views/game_page.dart';

/// Root application widget.
class CountryTriviaApp extends StatelessWidget {
  const CountryTriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Country Trivia',
      theme: AppTheme.light,
      home: const GamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
