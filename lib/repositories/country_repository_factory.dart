import '../services/api_service.dart';
import '../services/history_service.dart';
import 'api_country_repository.dart';
import 'country_repository.dart';
import 'fallback_country_repository.dart';
import 'local_country_repository.dart';

/// Factory for creating the appropriate CountryRepository.
class CountryRepositoryFactory {
  CountryRepositoryFactory._();

  /// Creates a repository with API primary and local fallback.
  static CountryRepository create(HistoryService historyService) {
    final apiRepo = ApiCountryRepository(
      ApiService(),
      historyService,
    );
    final localRepo = LocalCountryRepository(historyService);

    return FallbackCountryRepository(
      primary: apiRepo,
      fallback: localRepo,
    );
  }
}
