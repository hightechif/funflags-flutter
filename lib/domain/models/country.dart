class Country {
  final String name;
  final String code;
  final String continent;
  final String flagUrl;

  Country({
    required this.name,
    required this.code,
    required this.continent,
    required this.flagUrl,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'] ?? '',
      code: json['cca2'] ?? '',
      continent: json['continents']?.first ?? '',
      flagUrl: json['flags']['png'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': {'common': name},
      'cca2': code,
      'continents': [continent],
      'flags': {'png': flagUrl},
    };
  }
}
