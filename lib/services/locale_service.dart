import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'selected_locale';
  static Function(Locale)? _onLocaleChanged;

  // Set the locale change callback (called from MyApp)
  static void setLocaleChangeCallback(Function(Locale) callback) {
    _onLocaleChanged = callback;
  }

  // Get saved locale
  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null) {
      return Locale(localeCode);
    }
    return null;
  }

  // Save locale and notify callback
  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    // Notify the callback if set
    if (_onLocaleChanged != null) {
      // Call the callback asynchronously to ensure state updates happen
      Future.microtask(() => _onLocaleChanged!(locale));
    }
  }

  // Save locale without triggering callback (used internally)
  static Future<void> saveLocaleWithoutCallback(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  // Get default locale (English)
  static Locale getDefaultLocale() {
    return const Locale('en');
  }
}

