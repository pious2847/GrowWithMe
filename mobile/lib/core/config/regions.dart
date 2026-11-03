import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Country and region configuration. The app ships with Ghana as the home
/// market but is structured so any country can be added as a "care pack"
/// (regions, emergency numbers, immunization schedule, local foods, language).
@immutable
class CountryConfig {
  const CountryConfig({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.regions,
    required this.languages,
    required this.emergency,
    this.isHomeMarket = false,
  });

  final String code;
  final String name;
  final String flag;
  final String dialCode;
  final List<String> regions;
  final List<LanguageOption> languages;
  final String emergency;
  final bool isHomeMarket;
}

@immutable
class LanguageOption {
  const LanguageOption(this.code, this.label, {this.beta = false});
  final String code;
  final String label;
  final bool beta;
}

const ghanaRegions = <String>[
  'Northern',
  'Savannah',
  'North East',
  'Upper East',
  'Upper West',
  'Ashanti',
  'Bono',
  'Bono East',
  'Ahafo',
  'Central',
  'Eastern',
  'Greater Accra',
  'Oti',
  'Volta',
  'Western',
  'Western North',
];

const supportedCountries = <CountryConfig>[
  CountryConfig(
    code: 'GH',
    name: 'Ghana',
    flag: '🇬🇭',
    dialCode: '+233',
    regions: ghanaRegions,
    languages: [
      LanguageOption('en', 'English'),
      LanguageOption('tw', 'Twi', beta: true),
      LanguageOption('dag', 'Dagbani', beta: true),
    ],
    emergency: '112',
    isHomeMarket: true,
  ),
  CountryConfig(
    code: 'NG',
    name: 'Nigeria',
    flag: '🇳🇬',
    dialCode: '+234',
    regions: ['Lagos', 'Kano', 'Kaduna', 'Oyo', 'Abuja FCT', 'Enugu', 'Other'],
    languages: [
      LanguageOption('en', 'English'),
      LanguageOption('ha', 'Hausa', beta: true),
    ],
    emergency: '112',
  ),
  CountryConfig(
    code: 'KE',
    name: 'Kenya',
    flag: '🇰🇪',
    dialCode: '+254',
    regions: ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 'Other'],
    languages: [
      LanguageOption('en', 'English'),
      LanguageOption('sw', 'Kiswahili', beta: true),
    ],
    emergency: '999',
  ),
  CountryConfig(
    code: 'UG',
    name: 'Uganda',
    flag: '🇺🇬',
    dialCode: '+256',
    regions: ['Kampala', 'Gulu', 'Mbarara', 'Mbale', 'Other'],
    languages: [
      LanguageOption('en', 'English'),
      LanguageOption('lg', 'Luganda', beta: true),
    ],
    emergency: '112',
  ),
  CountryConfig(
    code: 'TZ',
    name: 'Tanzania',
    flag: '🇹🇿',
    dialCode: '+255',
    regions: ['Dar es Salaam', 'Mwanza', 'Arusha', 'Other'],
    languages: [
      LanguageOption('en', 'English'),
      LanguageOption('sw', 'Kiswahili', beta: true),
    ],
    emergency: '112',
  ),
  CountryConfig(
    code: 'XX',
    name: 'Another country',
    flag: '🌍',
    dialCode: '+',
    regions: ['Other'],
    languages: [LanguageOption('en', 'English')],
    emergency: '112',
  ),
];

CountryConfig countryByCode(String? code) => supportedCountries.firstWhere(
  (c) => c.code == code,
  orElse: () => supportedCountries.first,
);

/// Reads the saved country without Riverpod, for service classes that build
/// prompts, widget text and offline content outside the widget tree.
Future<String> savedCountryCode() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('regionSettings');
  if (raw == null) return RegionSettings.defaults.countryCode;
  try {
    final map = jsonDecode(raw) as Map;
    return map['countryCode'] as String? ?? RegionSettings.defaults.countryCode;
  } catch (_) {
    return RegionSettings.defaults.countryCode;
  }
}

/// Consent- and preference-driven region settings, persisted locally so the
/// app can be fully useful before any network call.
@immutable
class RegionSettings {
  const RegionSettings({
    required this.countryCode,
    required this.region,
    required this.languageCode,
  });

  final String countryCode;
  final String? region;
  final String languageCode;

  CountryConfig get country => countryByCode(countryCode);
  bool get isGhana => countryCode == 'GH';

  RegionSettings copyWith({
    String? countryCode,
    String? region,
    String? languageCode,
  }) => RegionSettings(
    countryCode: countryCode ?? this.countryCode,
    region: region ?? this.region,
    languageCode: languageCode ?? this.languageCode,
  );

  Map<String, dynamic> toJson() => {
    'countryCode': countryCode,
    'region': region,
    'languageCode': languageCode,
  };

  static const defaults = RegionSettings(
    countryCode: 'GH',
    region: null,
    languageCode: 'en',
  );
}

class RegionController extends AsyncNotifier<RegionSettings> {
  static const _key = 'regionSettings';

  @override
  Future<RegionSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return RegionSettings.defaults;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return RegionSettings(
        countryCode: map['countryCode'] as String? ?? 'GH',
        region: map['region'] as String?,
        languageCode: map['languageCode'] as String? ?? 'en',
      );
    } catch (_) {
      return RegionSettings.defaults;
    }
  }

  Future<void> save(RegionSettings settings) async {
    state = AsyncData(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  Future<void> setCountry(CountryConfig country) async {
    final current = state.value ?? RegionSettings.defaults;
    await save(
      current.copyWith(
        countryCode: country.code,
        region: country.regions.length == 1 ? country.regions.first : null,
        languageCode: country.languages.first.code,
      ),
    );
  }

  Future<void> setRegion(String region) async {
    final current = state.value ?? RegionSettings.defaults;
    await save(current.copyWith(region: region));
  }

  Future<void> setLanguage(String code) async {
    final current = state.value ?? RegionSettings.defaults;
    await save(current.copyWith(languageCode: code));
  }
}

final regionProvider = AsyncNotifierProvider<RegionController, RegionSettings>(
  RegionController.new,
);
