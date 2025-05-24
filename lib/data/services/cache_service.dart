import 'dart:convert';

import 'package:funflags/domain/models/country.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _countriesPrefix = 'countries_';
  static const String _timestampPrefix = 'timestamp_';
  static const Duration _cacheExpiry = Duration(hours: 24);

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
  }

  static Future<List<Country>?> getCachedCountries(String key) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if cache exists and is not expired
    final timestamp = prefs.getInt('$_timestampPrefix$key');
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
      // Cache expired, remove it
      await prefs.remove('$_countriesPrefix$key');
      await prefs.remove('$_timestampPrefix$key');
      return null;
    }

    final jsonString = prefs.getString('$_countriesPrefix$key');
    if (jsonString == null) return null;

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Country.fromJson(json)).toList();
    } catch (e) {
      // Invalid cache, remove it
      await prefs.remove('$_countriesPrefix$key');
      await prefs.remove('$_timestampPrefix$key');
      return null;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_countriesPrefix) ||
          key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
