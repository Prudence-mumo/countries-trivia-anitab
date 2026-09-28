import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/models/game_state.dart';
import 'package:country_trivia/models/question.dart';
import 'package:country_trivia/repositories/country_repository.dart';
import 'package:country_trivia/services/history_service.dart';
import 'package:country_trivia/viewmodels/game_viewmodel.dart';
import 'package:country_trivia/views/game_page.dart';

class _FakeRepository implements CountryRepository {
  @override
  Future<List<Country>> fetchAllCountries() async => const [];

  @override
  Future<List<Country>> fetchUnshownCountries() async => const [];

  @override
  Future<Question> generateQuestion() async => const Question(
        correctCountry: Country(name: 'Japan', isoCode: 'JP'),
        options: [
          Country(name: 'Japan', isoCode: 'JP'),
          Country(name: 'Germany', isoCode: 'DE'),
          Country(name: 'Brazil', isoCode: 'BR'),
          Country(name: 'Australia', isoCode: 'AU'),
        ],
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<GameViewModel> _createViewModel() async {
    final historyService = await HistoryService.create();
    return GameViewModel(
      repository: _FakeRepository(),
      historyService: historyService,
    );
  }

  Future<void> _pumpApp(WidgetTester tester, GameViewModel viewModel) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<GameViewModel>.value(
        value: viewModel,
        child: const MaterialApp(home: GamePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('GamePage shows loading state initially', (tester) async {
    final viewModel = await _createViewModel();
    await _pumpApp(tester, viewModel);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('GamePage shows flag and 4 answer buttons when ready', (tester) async {
    final viewModel = await _createViewModel();
    await _pumpApp(tester, viewModel);

    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Brazil'), findsOneWidget);
    expect(find.text('Australia'), findsOneWidget);
  });

  testWidgets('tapping correct answer shows feedback', (tester) async {
    final viewModel = await _createViewModel();
    await _pumpApp(tester, viewModel);

    await tester.tap(find.text('Japan'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Correct! +10 points'), findsOneWidget);
  });

  testWidgets('tapping incorrect answer decrements attempts', (tester) async {
    final viewModel = await _createViewModel();
    await _pumpApp(tester, viewModel);

    await tester.tap(find.text('Germany'));
    await tester.pump(const Duration(milliseconds: 100));

    // After 1 incorrect answer, 2 attempts remain (2 green dots, 1 grey)
    expect(find.byIcon(Icons.circle), findsNWidgets(3));
  });

  testWidgets('three incorrect answers reveals correct answer', (tester) async {
    final viewModel = await _createViewModel();
    await _pumpApp(tester, viewModel);

    await tester.tap(find.text('Germany'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Brazil'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Australia'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Out of attempts'), findsOneWidget);
  });
}
