import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  static const Map<String, Locale> supportedLocales = {
    'English': Locale('en'),
    'हिंदी': Locale('hi'),
    'मराठी': Locale('mr'),
    'தமிழ்': Locale('ta'),
    'తెలుగు': Locale('te'),
  };

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_language');
    if (savedLanguage != null && supportedLocales.containsKey(savedLanguage)) {
      state = supportedLocales[savedLanguage]!;
    }
  }

  Future<void> setLocale(String languageName) async {
    final locale = supportedLocales[languageName];
    if (locale != null) {
      state = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageName);
    }
  }

  String getLanguageName(Locale locale) {
    return supportedLocales.entries
        .firstWhere(
          (entry) => entry.value == locale,
          orElse: () => const MapEntry('English', Locale('en')),
        )
        .key;
  }
}
