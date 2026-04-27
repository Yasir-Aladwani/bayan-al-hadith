import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  int    _themeMode            = 1;
  double _fontScale            = 1.0;
  bool   _notificationsEnabled = true;
  String _fontFamily           = 'Amiri';

  static String currentFont = 'Amiri';

  bool   get isDark               => _themeMode != 0;
  bool   get isAmoled             => _themeMode == 2;
  int    get themeMode            => _themeMode;
  double get fontScale            => _fontScale;
  bool   get notificationsEnabled => _notificationsEnabled;
  String get fontFamily           => _fontFamily;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode            = prefs.getInt('themeMode')            ?? 1;
    _fontScale            = prefs.getDouble('fontScale')          ?? 1.0;
    _notificationsEnabled = prefs.getBool('notifications')        ?? true;
    _fontFamily           = prefs.getString('fontFamily')         ?? 'Amiri';
    currentFont           = _fontFamily;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode',    _themeMode);
    await prefs.setDouble('fontScale', _fontScale);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setString('fontFamily',  _fontFamily);
  }

  void setThemeMode(int mode) {
    _themeMode = mode.clamp(0, 2);
    notifyListeners();
    _save();
  }

  void toggleDark() {
    _themeMode = _themeMode == 0 ? 1 : 0;
    notifyListeners();
    _save();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    notifyListeners();
    _save();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    _save();
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    currentFont = family;
    notifyListeners();
    _save();
  }
}
