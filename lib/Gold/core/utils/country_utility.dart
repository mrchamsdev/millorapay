import 'package:country_picker/country_picker.dart';

/// Clean model representing a country for application-wide usage.
class CountryData {
  final String isoCode;
  final String name;
  final String phoneCode;
  final String? flagEmoji;

  const CountryData({
    required this.isoCode,
    required this.name,
    required this.phoneCode,
    this.flagEmoji,
  });

  Map<String, dynamic> toJson() => {
        'isoCode': isoCode,
        'name': name,
        'phoneCode': phoneCode,
        if (flagEmoji != null) 'flagEmoji': flagEmoji,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryData &&
          runtimeType == other.runtimeType &&
          isoCode.toUpperCase() == other.isoCode.toUpperCase();

  @override
  int get hashCode => isoCode.toUpperCase().hashCode;
}

/// Scalable Country Utility providing static allowed countries,
/// full world country lists, normalization, and country-based geo defaults.
class CountryUtility {
  /// Priority / Static allowed countries matching business requirements
  static const List<CountryData> staticAllowedCountries = [
    CountryData(isoCode: "IN", name: "India", phoneCode: "91", flagEmoji: "🇮🇳"),
    CountryData(isoCode: "US", name: "United States", phoneCode: "1", flagEmoji: "🇺🇸"),
    CountryData(isoCode: "GB", name: "United Kingdom", phoneCode: "44", flagEmoji: "🇬🇧"),
    CountryData(isoCode: "AE", name: "United Arab Emirates", phoneCode: "971", flagEmoji: "🇦🇪"),
    CountryData(isoCode: "CA", name: "Canada", phoneCode: "1", flagEmoji: "🇨🇦"),
    CountryData(isoCode: "AU", name: "Australia", phoneCode: "61", flagEmoji: "🇦🇺"),
    CountryData(isoCode: "DE", name: "Germany", phoneCode: "49", flagEmoji: "🇩🇪"),
    CountryData(isoCode: "FR", name: "France", phoneCode: "33", flagEmoji: "🇫🇷"),
    CountryData(isoCode: "IT", name: "Italy", phoneCode: "39", flagEmoji: "🇮🇹"),
    CountryData(isoCode: "JP", name: "Japan", phoneCode: "81", flagEmoji: "🇯🇵"),
    CountryData(isoCode: "BR", name: "Brazil", phoneCode: "55", flagEmoji: "🇧🇷"),
    CountryData(isoCode: "SG", name: "Singapore", phoneCode: "65", flagEmoji: "🇸🇬"),
    CountryData(isoCode: "SA", name: "Saudi Arabia", phoneCode: "966", flagEmoji: "🇸🇦"),
  ];

  /// Default country fallback
  static const CountryData defaultCountry = CountryData(
    isoCode: "IN",
    name: "India",
    phoneCode: "91",
    flagEmoji: "🇮🇳",
  );

  static List<CountryData>? _cachedCountries;

  /// Returns countries utility as a Future (matching async API contract).
  static Future<List<CountryData>> fetchCountriesUtility() async {
    return getAllCountries();
  }

  /// Returns full list of all countries with priority countries at top,
  /// followed by all other countries from country_picker without duplicates.
  static List<CountryData> getAllCountries() {
    if (_cachedCountries != null) return _cachedCountries!;

    final Map<String, CountryData> countryMap = {};

    // 1. Static prioritized countries
    for (final c in staticAllowedCountries) {
      countryMap[c.isoCode.toUpperCase()] = c;
    }

    // 2. All other countries from country_picker package
    try {
      final allPickerCountries = CountryService().getAll();
      for (final pc in allPickerCountries) {
        final upperIso = pc.countryCode.toUpperCase();
        if (!countryMap.containsKey(upperIso)) {
          countryMap[upperIso] = CountryData(
            isoCode: pc.countryCode,
            name: pc.name,
            phoneCode: pc.phoneCode,
            flagEmoji: pc.flagEmoji,
          );
        }
      }
    } catch (_) {}

    _cachedCountries = countryMap.values.toList();
    return _cachedCountries!;
  }

  /// Finds country by ISO code or Name (case-insensitive).
  static CountryData? findCountry(String? query) {
    if (query == null || query.trim().isEmpty) return null;
    final trimmed = query.trim();
    final upper = trimmed.toUpperCase();

    final all = getAllCountries();
    for (final c in all) {
      if (c.isoCode.toUpperCase() == upper || c.name.toUpperCase() == upper) {
        return c;
      }
    }
    return null;
  }

  /// Resolves the ISO code from either ISO code or country name.
  static String? getIsoCode(String? query) {
    return findCountry(query)?.isoCode;
  }

  /// Automatically detects or extracts a country from a full address string (e.g. "Hyderabad, Telangana, India").
  static CountryData? detectCountryFromAddress(String? address) {
    if (address == null || address.trim().isEmpty) return null;
    final parts = address.split(RegExp(r'[,;|\n]')).map((p) => p.trim()).toList();
    for (int i = parts.length - 1; i >= 0; i--) {
      final match = findCountry(parts[i]);
      if (match != null) return match;
    }
    for (final c in staticAllowedCountries) {
      if (address.toLowerCase().contains(c.name.toLowerCase())) {
        return c;
      }
    }
    return null;
  }

  /// Normalizes country name for API requests.
  static String normalizeCountryForApi(String? rawCountry) {
    if (rawCountry == null || rawCountry.trim().isEmpty) return "India";
    final upper = rawCountry.trim().toUpperCase();
    if (upper == "IN" || upper == "IND" || upper == "INDIA") return "India";
    if (upper == "US" || upper == "USA" || upper == "UNITED STATES" || upper == "UNITEDSTATES") return "United States";
    if (upper == "GB" || upper == "UK" || upper == "UNITED KINGDOM" || upper == "UNITEDKINGDOM") return "United Kingdom";
    if (upper == "CA" || upper == "CAN" || upper == "CANADA") return "Canada";
    if (upper == "AE" || upper == "UAE" || upper == "UNITED ARAB EMIRATES") return "United Arab Emirates";

    final found = findCountry(rawCountry);
    return found?.name ?? rawCountry.trim();
  }

  /// Default center coordinates for initial map camera position when country is selected.
  static (double, double) getDefaultCoordinates(String? isoCode) {
    switch (isoCode?.toUpperCase()) {
      case 'IN':
        return (20.5937, 78.9629); // India
      case 'US':
        return (37.0902, -95.7129); // USA
      case 'GB':
      case 'UK':
        return (55.3781, -3.4360); // UK
      case 'AE':
        return (23.4241, 53.8478); // UAE
      case 'CA':
        return (56.1304, -106.3468); // Canada
      case 'AU':
        return (-25.2744, 133.7751); // Australia
      case 'DE':
        return (51.1657, 10.4515); // Germany
      case 'FR':
        return (46.2276, 2.2137); // France
      case 'IT':
        return (41.8719, 12.5674); // Italy
      case 'JP':
        return (36.2048, 138.2529); // Japan
      case 'BR':
        return (-14.2350, -51.9253); // Brazil
      case 'SG':
        return (1.3521, 103.8198); // Singapore
      case 'SA':
        return (23.8859, 45.0792); // Saudi Arabia
      default:
        return (20.5937, 78.9629); // Fallback India
    }
  }
}
