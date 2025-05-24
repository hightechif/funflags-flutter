import 'package:flutter/foundation.dart';
import 'package:funflags/data/services/cache_service.dart';
import 'package:funflags/data/services/country_service.dart';
import 'package:funflags/domain/models/country.dart';
import 'package:funflags/domain/models/paginated_result.dart';
import 'package:funflags/domain/repositories/country_repository.dart';

class CountryRepositoryImpl implements CountryRepository {
  List<Country> _allCountries = [];
  List<Country> _regionCountries = [];
  String? _currentRegion;
  bool _isBackgroundRefreshing = false;

  @override
  Future<PaginatedResult<Country>> getCountries({
    String? region,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      String cacheKey = region ?? 'all';
      bool regionChanged = region != _currentRegion;

      // If region changed or no data in memory, try cache first
      if (regionChanged || _allCountries.isEmpty) {
        final cachedCountries = await getCachedCountries(cacheKey);

        if (cachedCountries != null) {
          // Load from cache immediately
          cachedCountries.sort((a, b) => a.name.compareTo(b.name));

          if (region == null || region == 'World') {
            _allCountries = cachedCountries;
          } else {
            _regionCountries = cachedCountries;
          }
          _currentRegion = region;

          // Check if cache needs refresh in background
          final isExpired = await CacheService.isCacheExpired(cacheKey);
          if (isExpired && !_isBackgroundRefreshing) {
            _refreshDataInBackground(region, cacheKey);
          }
        } else {
          // No cache available, fetch from API
          final freshCountries = await _fetchFromAPI(region);
          freshCountries.sort((a, b) => a.name.compareTo(b.name));

          if (region == null || region == 'World') {
            _allCountries = freshCountries;
          } else {
            _regionCountries = freshCountries;
          }
          _currentRegion = region;

          // Cache the fresh data
          await cacheCountries(freshCountries, cacheKey);
        }
      }

      // Get data from memory
      List<Country> countries =
          (region == null || region == 'World')
              ? _allCountries
              : _regionCountries;

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

  Future<List<Country>> _fetchFromAPI(String? region) async {
    if (region == null || region == 'World') {
      return await CountryService.getAllCountries();
    } else {
      return await CountryService.getCountriesByRegion(region);
    }
  }

  Future<void> _refreshDataInBackground(String? region, String cacheKey) async {
    if (_isBackgroundRefreshing) return;

    _isBackgroundRefreshing = true;

    try {
      final freshCountries = await _fetchFromAPI(region);
      freshCountries.sort((a, b) => a.name.compareTo(b.name));

      // Update cache
      await cacheCountries(freshCountries, cacheKey);

      // Update in-memory data
      if (region == null || region == 'World') {
        _allCountries = freshCountries;
      } else if (region == _currentRegion) {
        _regionCountries = freshCountries;
      }
    } catch (e) {
      // Silently fail background refresh - user still has cached data
      if (kDebugMode) {
        print('Background refresh failed: $e');
      }
    } finally {
      _isBackgroundRefreshing = false;
    }
  }

  @override
  Future<List<Country>> searchCountries(String query, {String? region}) async {
    List<Country> countries;

    if (region == null || region == 'World') {
      if (_allCountries.isEmpty) {
        // Try to load from cache first, then API if needed
        await getCountries(region: region, page: 1, pageSize: 1000);
      }
      countries = _allCountries;
    } else {
      if (_regionCountries.isEmpty || _currentRegion != region) {
        // Try to load from cache first, then API if needed
        await getCountries(region: region, page: 1, pageSize: 1000);
      }
      countries = _regionCountries;
    }

    return countries.where((country) {
      return country.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
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

  @override
  Future<bool> hasCachedData(String key) async {
    return await CacheService.hasCachedData(key);
  }

  @override
  Future<DateTime?> getCacheTimestamp(String key) async {
    return await CacheService.getCacheTimestamp(key);
  }

  @override
  Future<void> forceRefresh({String? region}) async {
    String cacheKey = region ?? 'all';

    try {
      final freshCountries = await _fetchFromAPI(region);
      freshCountries.sort((a, b) => a.name.compareTo(b.name));

      // Update memory
      if (region == null || region == 'World') {
        _allCountries = freshCountries;
      } else {
        _regionCountries = freshCountries;
      }
      _currentRegion = region;

      // Update cache
      await cacheCountries(freshCountries, cacheKey);
    } catch (e) {
      throw Exception('Failed to refresh data: $e');
    }
  }
}
