import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds user-facing appearance and playback preferences.
///
/// Appearance lives here (rather than in `ThemeMode.system`) because dark is
/// the product's primary experience and users need an explicit, remembered
/// choice.
class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyReduceMotion = 'settings_reduce_motion';
  static const String _keyTextScale = 'settings_text_scale';
  static const String _keyWifiOnly = 'settings_wifi_only';
  static const String _keyOptimizeStreaming = 'settings_optimize_streaming';
  static const String _keyAutoPlayNext = 'settings_auto_play_next';

  SettingsProvider(this._prefs);

  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool _reduceMotion = false;
  bool get reduceMotion => _reduceMotion;

  double _textScale = 1.0;
  double get textScale => _textScale;

  bool _wifiOnly = true;
  bool get wifiOnly => _wifiOnly;

  bool _optimizeStreaming = true;
  bool get optimizeStreaming => _optimizeStreaming;

  bool _autoPlayNext = true;
  bool get autoPlayNext => _autoPlayNext;

  void load() {
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.getString(_keyThemeMode),
      orElse: () => ThemeMode.dark,
    );
    _reduceMotion = _prefs.getBool(_keyReduceMotion) ?? false;
    _textScale = _prefs.getDouble(_keyTextScale) ?? 1.0;
    _wifiOnly = _prefs.getBool(_keyWifiOnly) ?? true;
    _optimizeStreaming = _prefs.getBool(_keyOptimizeStreaming) ?? true;
    _autoPlayNext = _prefs.getBool(_keyAutoPlayNext) ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  /// Convenience cycle for the compact settings control.
  Future<void> cycleThemeMode() {
    const order = <ThemeMode>[
      ThemeMode.dark,
      ThemeMode.light,
      ThemeMode.system
    ];
    final next = order[(order.indexOf(_themeMode) + 1) % order.length];
    return setThemeMode(next);
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();
    await _prefs.setBool(_keyReduceMotion, value);
  }

  Future<void> setTextScale(double value) async {
    final clamped = value.clamp(0.85, 1.3);
    if ((_textScale - clamped).abs() < 0.01) return;
    _textScale = clamped;
    notifyListeners();
    await _prefs.setDouble(_keyTextScale, clamped);
  }

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    notifyListeners();
    await _prefs.setBool(_keyWifiOnly, value);
  }

  Future<void> setOptimizeStreaming(bool value) async {
    _optimizeStreaming = value;
    notifyListeners();
    await _prefs.setBool(_keyOptimizeStreaming, value);
  }

  Future<void> setAutoPlayNext(bool value) async {
    _autoPlayNext = value;
    notifyListeners();
    await _prefs.setBool(_keyAutoPlayNext, value);
  }

  String get themeLabel => switch (_themeMode) {
        ThemeMode.dark => 'Dark',
        ThemeMode.light => 'Light',
        ThemeMode.system => 'System',
      };
}
