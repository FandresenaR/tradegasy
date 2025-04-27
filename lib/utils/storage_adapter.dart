import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Storage adapter interface for persisting application data
abstract class StorageAdapter {
  Future<void> initialize();
  Future<bool> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<bool> setString(String key, String value);
  Future<String?> getString(String key);
}

/// Implementation using SharedPreferences
class SharedPrefsAdapter implements StorageAdapter {
  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _available = false;
  // Create fallback memory storage for web or when SharedPreferences fails
  final MemoryStorageAdapter _memoryStorage = MemoryStorageAdapter();

  SharedPrefsAdapter();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // On web, immediately use memory storage without even trying SharedPreferences
    if (kIsWeb) {
      _initialized = true;
      _available = false;
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      _available = true;
    } catch (e) {
      print('SharedPreferences unavailable: $e');
      _initialized = true;
      _available = false;
    }
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_available || _prefs == null) {
      // Use memory storage as fallback
      return _memoryStorage.setBool(key, value);
    }

    try {
      return await _prefs!.setBool(key, value);
    } catch (e) {
      // Fall back to memory storage on error
      print('Error setting bool in SharedPreferences: $e');
      return _memoryStorage.setBool(key, value);
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_available || _prefs == null) {
      // Use memory storage as fallback
      return _memoryStorage.getBool(key);
    }

    try {
      return _prefs!.getBool(key);
    } catch (e) {
      // Fall back to memory storage on error
      print('Error getting bool from SharedPreferences: $e');
      return _memoryStorage.getBool(key);
    }
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_available || _prefs == null) {
      // Use memory storage as fallback
      return _memoryStorage.setString(key, value);
    }

    try {
      return await _prefs!.setString(key, value);
    } catch (e) {
      // Fall back to memory storage on error
      print('Error setting string in SharedPreferences: $e');
      return _memoryStorage.setString(key, value);
    }
  }

  @override
  Future<String?> getString(String key) async {
    if (!_initialized) {
      await initialize();
    }

    if (!_available || _prefs == null) {
      // Use memory storage as fallback
      return _memoryStorage.getString(key);
    }

    try {
      return _prefs!.getString(key);
    } catch (e) {
      // Fall back to memory storage on error
      print('Error getting string from SharedPreferences: $e');
      return _memoryStorage.getString(key);
    }
  }
}

/// In-memory storage fallback implementation
class MemoryStorageAdapter implements StorageAdapter {
  final Map<String, dynamic> _storage = {};

  @override
  Future<void> initialize() async {
    // No initialization needed for in-memory storage
    return;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool?> getBool(String key) async {
    return _storage[key] as bool?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<String?> getString(String key) async {
    return _storage[key] as String?;
  }
}
