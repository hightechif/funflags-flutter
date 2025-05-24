class Country {
  final String name;
  final String code;
  final String flagUrl;
  final String continent;

  Country({
    required this.name,
    required this.code,
    required this.flagUrl,
    required this.continent,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'],
      code: json['cca2'],
      flagUrl: json['flags']['png'],
      continent: json['region'],
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
