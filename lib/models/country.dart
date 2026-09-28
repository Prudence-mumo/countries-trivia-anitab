/// Represents a country with its name and ISO code.
class Country {
  /// Common name of the country (e.g., "United States").
  final String name;

  /// ISO 3166-1 alpha-2 code (e.g., "US").
  final String isoCode;

  const Country({required this.name, required this.isoCode});

  /// Flag image URL from flagcdn.com.
  String get flagUrl => 'http://flagcdn.com/w320/${isoCode.toLowerCase()}.png';

  /// Parse from REST Countries v5 API response.
  factory Country.fromJsonV5(Map<String, dynamic> json) {
    return Country(
      name: json['names']['common'] as String,
      isoCode: json['codes']['alpha_2'] as String,
    );
  }

  /// Parse from REST Countries v3 API response (legacy/fallback).
  factory Country.fromJsonV3(Map<String, dynamic> json) {
    return Country(
      name: json['name'] as String,
      isoCode: json['cca2'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode;

  @override
  int get hashCode => isoCode.hashCode;

  @override
  String toString() => 'Country(name: $name, isoCode: $isoCode)';
}
