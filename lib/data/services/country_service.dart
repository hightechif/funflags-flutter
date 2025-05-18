import 'dart:convert';

import 'package:funflags/domain/models/country.dart';
import 'package:http/http.dart' as http;

class CountryService {
  static const String baseUrl = 'https://restcountries.com/v3.1';

  static Future<List<Country>> getCountriesByRegion(String region) async {
    final response = await http.get(Uri.parse('$baseUrl/region/$region'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Country.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load countries');
    }
  }

  static Future<List<Country>> getAllCountries() async {
    final response = await http.get(Uri.parse('$baseUrl/all'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Country.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load countries');
    }
  }
}
