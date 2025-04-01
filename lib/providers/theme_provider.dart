import 'package:flutter/material.dart';
import 'package:tradegasy/utils/storage_adapter.dart';

class ThemeProvider extends ChangeNotifier {
  // Initialize with dark mode by default
  bool _isDarkMode = true;
  bool _initialized = false;
  static const String _themePreferenceKey = 'isDarkMode';

  final StorageAdapter _storage;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _initialized;

  ThemeProvider(this._storage) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      // Try to load from storage, default to true (dark mode) if no preference is set
      final savedTheme = await _storage.getBool(_themePreferenceKey);
      _isDarkMode = savedTheme ?? true;
    } catch (e) {
      // Use dark theme if loading fails
      print('Error loading theme preference: $e');
      _isDarkMode = true;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      await _storage.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }
}
