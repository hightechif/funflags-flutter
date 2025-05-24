// lib/data/repositories/country_repository_impl.dart
import 'package:funflags/data/services/cache_service.dart';
import 'package:funflags/data/services/country_service.dart';
import 'package:funflags/domain/models/country.dart';
import 'package:funflags/domain/models/paginated_result.dart';
import 'package:funflags/domain/repositories/country_repository.dart';

class CountryRepositoryImpl implements CountryRepository {
  List<Country> _allCountries = [];
  List<Country> _regionCountries = [];
  String? _currentRegion;

  @override
  Future<PaginatedResult<Country>> getCountries({
    String? region,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      List<Country> countries;
      String cacheKey = region ?? 'all';

      // Check if we need to load new data
      if (region != _currentRegion || _allCountries.isEmpty) {
        // Try to get from cache first
        final cachedCountries = await getCachedCountries(cacheKey);

        if (cachedCountries != null) {
          countries = cachedCountries;
        } else {
          // Fetch from API
          if (region == null || region == 'World') {
            countries = await CountryService.getAllCountries();
          } else {
            countries = await CountryService.getCountriesByRegion(region);
          }

          // Cache the results
          await cacheCountries(countries, cacheKey);
        }

        // Sort countries alphabetically
        countries.sort((a, b) => a.name.compareTo(b.name));

        if (region == null || region == 'World') {
          _allCountries = countries;
        } else {
          _regionCountries = countries;
        }
        _currentRegion = region;
      } else {
        // Use existing data
        countries =
            (region == null || region == 'World')
                ? _allCountries
                : _regionCountries;
      }

      // Implement pagination
      final startIndex = (page - 1) * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, countries.length);

      if (startIndex >= countries.length) {
        return PaginatedResult<Country>(
          items: [],
          hasMore: false,
          currentPage: page,
          totalItems: countries.length,
        );
      }

      final paginatedItems = countries.sublist(startIndex, endIndex);
      final hasMore = endIndex < countries.length;

      return PaginatedResult<Country>(
        items: paginatedItems,
        hasMore: hasMore,
        currentPage: page,
        totalItems: countries.length,
      );
    } catch (e) {
      throw Exception('Failed to load countries: $e');
    }
  }

  @override
  Future<List<Country>> searchCountries(String query, {String? region}) async {
    List<Country> countries;

    if (region == null || region == 'World') {
      if (_allCountries.isEmpty) {
        final result = await getCountries(
          region: region,
          page: 1,
          pageSize: 1000,
        );
        countries = await _getAllCountriesForSearch(region);
      } else {
        countries = _allCountries;
      }
    } else {
      if (_regionCountries.isEmpty || _currentRegion != region) {
        final result = await getCountries(
          region: region,
          page: 1,
          pageSize: 1000,
        );
        countries = await _getAllCountriesForSearch(region);
      } else {
        countries = _regionCountries;
      }
    }

    return countries.where((country) {
      return country.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<List<Country>> _getAllCountriesForSearch(String? region) async {
    // Get all countries for search (not paginated)
    List<Country> allCountries = [];
    int page = 1;
    const pageSize = 50;

    while (true) {
      final result = await getCountries(
        region: region,
        page: page,
        pageSize: pageSize,
      );
      allCountries.addAll(result.items);

      if (!result.hasMore) break;
      page++;
    }

    return allCountries;
  }

  @override
  Future<void> cacheCountries(List<Country> countries, String key) async {
    await CacheService.cacheCountries(countries, key);
  }

  @override
  Future<List<Country>?> getCachedCountries(String key) async {
    return await CacheService.getCachedCountries(key);
  }

  @override
  Future<void> clearCache() async {
    await CacheService.clearCache();
    _allCountries.clear();
    _regionCountries.clear();
    _currentRegion = null;
  }
}
