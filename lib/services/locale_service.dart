import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the app locale (Vietnamese / English).
///
/// - Detects device language on first launch → defaults to vi or en
/// - Persists user preference in secure storage
/// - Notifies listeners when locale changes so the UI rebuilds immediately
///
/// **Requirements: 39.1, 39.2, 39.7**
class LocaleService extends ChangeNotifier {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const _kLocaleKey = 'app_locale';
  static const _storage = FlutterSecureStorage();

  Locale _locale = const Locale('vi');

  /// Current active locale.
  Locale get locale => _locale;

  /// Initialise: load persisted preference, or detect device language.
  Future<void> init() async {
    final stored = await _storage.read(key: _kLocaleKey);
    if (stored != null) {
      _locale = Locale(stored);
    } else {
      // Detect device locale
      final deviceLocale = PlatformDispatcher.instance.locale;
      _locale = deviceLocale.languageCode == 'vi'
          ? const Locale('vi')
          : const Locale('en');
      await _storage.write(key: _kLocaleKey, value: _locale.languageCode);
    }
    notifyListeners();
  }

  /// Switch to [newLocale] and persist the preference.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    await _storage.write(key: _kLocaleKey, value: newLocale.languageCode);
    notifyListeners();
  }

  /// Toggle between Vietnamese and English.
  Future<void> toggle() async {
    final next = _locale.languageCode == 'vi'
        ? const Locale('en')
        : const Locale('vi');
    await setLocale(next);
  }

  /// List of supported locales.
  static const List<Locale> supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];
}
