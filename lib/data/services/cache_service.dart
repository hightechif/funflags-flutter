import 'dart:convert';

import 'package:funflags/domain/models/country.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _countriesPrefix = 'countries_';
  static const String _timestampPrefix = 'timestamp_';
  static const String _versionPrefix = 'version_';
  static const Duration _cacheExpiry = Duration(
    days: 30,
  ); // Extended to 30 days
  static const int _currentVersion = 1;

  static Future<void> cacheCountries(
    List<Country> countries,
    String key,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(countries.map((c) => c.toJson()).toList());

    await prefs.setString('$_countriesPrefix$key', jsonString);
    await prefs.setInt(
      '$_timestampPrefix$key',
      DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setInt('$_versionPrefix$key', _currentVersion);
  }

  static Future<List<Country>?> getCachedCountries(String key) async {
    final prefs = await SharedPreferences.getInstance();

    // Check version compatibility
    final version = prefs.getInt('$_versionPrefix$key') ?? 0;
    if (version != _currentVersion) {
      await _removeCacheForKey(prefs, key);
      return null;
    }

    final jsonString = prefs.getString('$_countriesPrefix$key');
    if (jsonString == null) return null;

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Country.fromJson(json)).toList();
    } catch (e) {
      // Invalid cache, remove it
      await _removeCacheForKey(prefs, key);
      return null;
    }
  }

  static Future<bool> isCacheExpired(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_timestampPrefix$key');
    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) > _cacheExpiry;
  }

  static Future<bool> hasCachedData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_countriesPrefix$key');
  }

  static Future<void> _removeCacheForKey(
    SharedPreferences prefs,
    String key,
  ) async {
    await prefs.remove('$_countriesPrefix$key');
    await prefs.remove('$_timestampPrefix$key');
    await prefs.remove('$_versionPrefix$key');
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_countriesPrefix) ||
          key.startsWith(_timestampPrefix) ||
          key.startsWith(_versionPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  static Future<DateTime?> getCacheTimestamp(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_timestampPrefix$key');
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }
}
