import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'repositories/country_repository_factory.dart';
import 'services/history_service.dart';
import 'viewmodels/game_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final historyService = await HistoryService.create();

  runApp(
    ChangeNotifierProvider(
      create: (_) => GameViewModel(
        repository: CountryRepositoryFactory.create(historyService),
        historyService: historyService,
      ),
      child: const CountryTriviaApp(),
    ),
  );
}
