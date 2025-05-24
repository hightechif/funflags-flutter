import 'package:funflags/domain/models/country.dart';
import 'package:funflags/domain/models/paginated_result.dart';

abstract class CountryRepository {
  Future<PaginatedResult<Country>> getCountries({
    String? region,
    int page = 1,
    int pageSize = 20,
  });

  Future<List<Country>> searchCountries(String query, {String? region});

  Future<void> cacheCountries(List<Country> countries, String key);

  Future<List<Country>?> getCachedCountries(String key);

  Future<void> clearCache();

  Future<bool> hasCachedData(String key);

  Future<DateTime?> getCacheTimestamp(String key);

  Future<void> forceRefresh({String? region});
}
