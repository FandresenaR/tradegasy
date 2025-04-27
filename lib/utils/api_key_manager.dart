// This file defines API key types and management functions
// for the TradeGasy app

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Enum for different API key types
enum ApiKeyType {
  binanceApiKey,
  binanceSecretKey,
  huggingfaceApiKey,
  replicateApiKey,
  openrouterApiKey,
}

class ApiKeyManager {
  static final ApiKeyManager _instance = ApiKeyManager._internal();
  factory ApiKeyManager() => _instance;

  ApiKeyManager._internal();

  // Secure storage for API keys
  final _secureStorage = const FlutterSecureStorage();

  // Key names for storing in secure storage
  final Map<ApiKeyType, String> _keyNames = {
    ApiKeyType.binanceApiKey: 'binance_api_key',
    ApiKeyType.binanceSecretKey: 'binance_secret_key',
    ApiKeyType.huggingfaceApiKey: 'huggingface_api_key',
    ApiKeyType.replicateApiKey: 'replicate_api_key',
    ApiKeyType.openrouterApiKey: 'openrouter_api_key',
  };

  // Initialize keys (can be used for default values if needed)
  Future<void> initialize() async {
    // Check if keys exist, if not initialize with empty values
    for (var keyType in ApiKeyType.values) {
      final keyExists = await _secureStorage.containsKey(
        key: _keyNames[keyType]!,
      );
      if (!keyExists) {
        await _secureStorage.write(key: _keyNames[keyType]!, value: '');
      }
    }
  }

  // Save an API key
  Future<void> saveApiKey(ApiKeyType keyType, String value) async {
    await _secureStorage.write(key: _keyNames[keyType]!, value: value);
  }

  // Get an API key synchronously (may return null)
  String? getApiKey(ApiKeyType keyType) {
    // This is a synchronous method that returns a cached value or null
    // For actual retrieval, use the async method
    return null;
  }

  // Get an API key asynchronously
  Future<String?> getApiKeyAsync(ApiKeyType keyType) async {
    return await _secureStorage.read(key: _keyNames[keyType]!);
  }

  // Delete an API key
  Future<void> deleteApiKey(ApiKeyType keyType) async {
    await _secureStorage.delete(key: _keyNames[keyType]!);
  }

  // Check if an API key exists
  Future<bool> hasApiKey(ApiKeyType keyType) async {
    final value = await _secureStorage.read(key: _keyNames[keyType]!);
    return value != null && value.isNotEmpty;
  }

  // Delete all API keys
  Future<void> deleteAllApiKeys() async {
    await _secureStorage.deleteAll();
  }
}
