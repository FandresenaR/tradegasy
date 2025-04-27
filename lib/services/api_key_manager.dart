import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Types of API keys supported by the application
enum ApiKeyType {
  binanceApiKey,
  binanceSecretKey,
  openrouterApiKey,
  huggingfaceApiKey,
  replicateApiKey,
}

/// Status d'une clé API
enum ApiKeyStatus {
  valid, // La clé est valide et fonctionne
  invalid, // La clé est invalide (401, 403, etc.)
  notSet, // La clé n'est pas définie
  unknown, // Statut inconnu (n'a pas été vérifié)
  error, // Erreur lors de la vérification
}

/// Manages storage and retrieval of API keys
class ApiKeyManager {
  // Create a singleton instance
  static final ApiKeyManager _instance = ApiKeyManager._internal();
  factory ApiKeyManager() => _instance;
  ApiKeyManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache for API keys to avoid repeated secure storage access
  final Map<String, String?> _keyCache = {};

  // Cache pour le statut des clés API
  final Map<ApiKeyType, ApiKeyStatus> _keyStatus = {};

  // Get storage key for each API key type
  String _getStorageKey(ApiKeyType type) {
    switch (type) {
      case ApiKeyType.binanceApiKey:
        return 'binance_api_key';
      case ApiKeyType.binanceSecretKey:
        return 'binance_secret_key';
      case ApiKeyType.openrouterApiKey:
        return 'openrouter_api_key';
      case ApiKeyType.huggingfaceApiKey:
        return 'huggingface_api_key';
      case ApiKeyType.replicateApiKey:
        return 'replicate_api_key';
    }
  }

  // Obtenir le nom lisible pour chaque type de clé API
  String getApiKeyName(ApiKeyType type) {
    switch (type) {
      case ApiKeyType.binanceApiKey:
        return 'Binance API Key';
      case ApiKeyType.binanceSecretKey:
        return 'Binance Secret Key';
      case ApiKeyType.openrouterApiKey:
        return 'OpenRouter API Key';
      case ApiKeyType.huggingfaceApiKey:
        return 'Hugging Face API Key';
      case ApiKeyType.replicateApiKey:
        return 'Replicate API Key';
    }
  }

  // Obtenir l'URL d'inscription pour chaque service d'API
  String getApiKeySignupUrl(ApiKeyType type) {
    switch (type) {
      case ApiKeyType.binanceApiKey:
      case ApiKeyType.binanceSecretKey:
        return 'https://www.binance.com/en/my/settings/api-management';
      case ApiKeyType.openrouterApiKey:
        return 'https://openrouter.ai/keys';
      case ApiKeyType.huggingfaceApiKey:
        return 'https://huggingface.co/settings/tokens';
      case ApiKeyType.replicateApiKey:
        return 'https://replicate.com/account/api-tokens';
    }
  }

  // Obtenir le statut d'une clé API (mis en cache)
  ApiKeyStatus getApiKeyStatus(ApiKeyType type) {
    return _keyStatus[type] ?? ApiKeyStatus.unknown;
  }

  /// Retrieves an API key from secure storage
  Future<String?> getApiKeyAsync(ApiKeyType type) async {
    final key = _getStorageKey(type);

    // Check cache first
    if (_keyCache.containsKey(key)) {
      return _keyCache[key];
    }

    try {
      final value = await _storage.read(key: key);
      _keyCache[key] = value; // Update cache

      // Mettre à jour le statut
      if (value == null || value.isEmpty) {
        _keyStatus[type] = ApiKeyStatus.notSet;
      }

      return value;
    } catch (e) {
      print('Error retrieving API key: $e');
      _keyStatus[type] = ApiKeyStatus.error;
      return null;
    }
  }

  /// Synchronous API key retrieval (from cache, may return null if not cached)
  String? getApiKey(ApiKeyType type) {
    final key = _getStorageKey(type);
    final cachedValue = _keyCache[key];

    // Mettre à jour le statut si la clé est en cache
    if (_keyCache.containsKey(key)) {
      if (cachedValue == null || cachedValue.isEmpty) {
        _keyStatus[type] = ApiKeyStatus.notSet;
      }
    }

    return cachedValue;
  }

  /// Saves an API key to secure storage
  Future<void> saveApiKey(ApiKeyType type, String value) async {
    final key = _getStorageKey(type);
    try {
      // Si la valeur est vide, supprimons la clé
      if (value.isEmpty) {
        await _storage.delete(key: key);
        _keyCache[key] = null;
        _keyStatus[type] = ApiKeyStatus.notSet;
        return;
      }

      // Sinon, sauvegardons la clé
      await _storage.write(key: key, value: value);
      _keyCache[key] = value; // Update cache

      // Réinitialiser le statut pour qu'il soit vérifié à nouveau
      _keyStatus[type] = ApiKeyStatus.unknown;
    } catch (e) {
      print('Error saving API key: $e');
      _keyStatus[type] = ApiKeyStatus.error;
      throw Exception('Failed to save API key: $e');
    }
  }

  /// Supprime une clé API du stockage sécurisé
  Future<void> deleteApiKey(ApiKeyType type) async {
    final key = _getStorageKey(type);
    try {
      await _storage.delete(key: key);
      _keyCache[key] = null;
      _keyStatus[type] = ApiKeyStatus.notSet;
    } catch (e) {
      print('Error deleting API key: $e');
      throw Exception('Failed to delete API key: $e');
    }
  }

  /// Efface toutes les clés API
  Future<void> clearAllKeys() async {
    try {
      for (final type in ApiKeyType.values) {
        final key = _getStorageKey(type);
        await _storage.delete(key: key);
        _keyCache[key] = null;
        _keyStatus[type] = ApiKeyStatus.notSet;
      }
    } catch (e) {
      print('Error clearing all API keys: $e');
      throw Exception('Failed to clear all API keys: $e');
    }
  }

  /// Vérifie si une clé API est valide
  Future<ApiKeyStatus> verifyApiKey(ApiKeyType type) async {
    final apiKey = await getApiKeyAsync(type);

    // Si la clé n'est pas définie, retourner notSet
    if (apiKey == null || apiKey.isEmpty) {
      _keyStatus[type] = ApiKeyStatus.notSet;
      return ApiKeyStatus.notSet;
    }

    try {
      bool isValid = false;

      switch (type) {
        case ApiKeyType.openrouterApiKey:
          final response = await http
              .get(
                Uri.parse('https://openrouter.ai/api/v1/models'),
                headers: {
                  'Authorization': 'Bearer $apiKey',
                  'HTTP-Referer': 'https://tradegasy.app',
                  'X-Title': 'TradeGasy',
                },
              )
              .timeout(const Duration(seconds: 10));

          isValid = response.statusCode == 200;

          if (response.statusCode == 401 || response.statusCode == 403) {
            _keyStatus[type] = ApiKeyStatus.invalid;
          } else if (isValid) {
            _keyStatus[type] = ApiKeyStatus.valid;
          } else {
            _keyStatus[type] = ApiKeyStatus.error;
          }
          break;

        case ApiKeyType.huggingfaceApiKey:
          final response = await http
              .post(
                Uri.parse(
                  'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2',
                ),
                headers: {
                  'Authorization': 'Bearer $apiKey',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'inputs': 'Hello',
                  'parameters': {'max_new_tokens': 5},
                }),
              )
              .timeout(const Duration(seconds: 10));

          // 200 = ok, 503 = "Model is loading" which means the key is valid
          isValid = response.statusCode == 200 || response.statusCode == 503;

          if (response.statusCode == 401 || response.statusCode == 403) {
            _keyStatus[type] = ApiKeyStatus.invalid;
          } else if (isValid) {
            _keyStatus[type] = ApiKeyStatus.valid;
          } else {
            _keyStatus[type] = ApiKeyStatus.error;
          }
          break;

        case ApiKeyType.replicateApiKey:
          final response = await http
              .get(
                Uri.parse('https://api.replicate.com/v1/models'),
                headers: {'Authorization': 'Token $apiKey'},
              )
              .timeout(const Duration(seconds: 10));

          isValid = response.statusCode == 200;

          if (response.statusCode == 401 || response.statusCode == 403) {
            _keyStatus[type] = ApiKeyStatus.invalid;
          } else if (isValid) {
            _keyStatus[type] = ApiKeyStatus.valid;
          } else {
            _keyStatus[type] = ApiKeyStatus.error;
          }
          break;

        case ApiKeyType.binanceApiKey:
        case ApiKeyType.binanceSecretKey:
          // Pour Binance, nous avons besoin des deux clés pour vérifier, donc
          // nous allons simplement vérifier le format pour l'instant
          if (apiKey.length >= 30) {
            _keyStatus[type] = ApiKeyStatus.valid;
            isValid = true;
          } else {
            _keyStatus[type] = ApiKeyStatus.invalid;
          }
          break;
      }

      return _keyStatus[type]!;
    } catch (e) {
      print('Error verifying API key: $e');
      _keyStatus[type] = ApiKeyStatus.error;
      return ApiKeyStatus.error;
    }
  }

  /// Utilise des clés de démo depuis .env si disponibles
  Future<bool> useDemoKeys() async {
    bool anySuccess = false;

    try {
      // OpenRouter
      final openRouterDemo = dotenv.env['OPENROUTER_API_KEY'];
      if (openRouterDemo != null && openRouterDemo.isNotEmpty) {
        await saveApiKey(ApiKeyType.openrouterApiKey, openRouterDemo);
        anySuccess = true;
      }

      // Hugging Face
      final huggingFaceDemo = dotenv.env['HUGGINGFACE_API_KEY'];
      if (huggingFaceDemo != null && huggingFaceDemo.isNotEmpty) {
        await saveApiKey(ApiKeyType.huggingfaceApiKey, huggingFaceDemo);
        anySuccess = true;
      }

      // Replicate
      final replicateDemo = dotenv.env['REPLICATE_API_KEY'];
      if (replicateDemo != null && replicateDemo.isNotEmpty) {
        await saveApiKey(ApiKeyType.replicateApiKey, replicateDemo);
        anySuccess = true;
      }

      // Binance
      final binanceApiKey = dotenv.env['BINANCE_API_KEY'];
      final binanceSecretKey = dotenv.env['BINANCE_SECRET_KEY'];

      if (binanceApiKey != null && binanceApiKey.isNotEmpty) {
        await saveApiKey(ApiKeyType.binanceApiKey, binanceApiKey);
        anySuccess = true;
      }

      if (binanceSecretKey != null && binanceSecretKey.isNotEmpty) {
        await saveApiKey(ApiKeyType.binanceSecretKey, binanceSecretKey);
        anySuccess = true;
      }

      return anySuccess;
    } catch (e) {
      print('Error using demo keys: $e');
      return false;
    }
  }

  /// Initialize the API key manager, loading keys into cache
  Future<void> initialize() async {
    try {
      for (final type in ApiKeyType.values) {
        final key = _getStorageKey(type);
        final value = await _storage.read(key: key);
        _keyCache[key] = value;

        // Initialiser le statut
        if (value == null || value.isEmpty) {
          _keyStatus[type] = ApiKeyStatus.notSet;
        } else {
          _keyStatus[type] = ApiKeyStatus.unknown;
        }
      }
      print(
        'API key manager initialized with cache: ${_keyCache.keys.length} keys',
      );
    } catch (e) {
      print('Error initializing API key manager: $e');
    }
  }

  /// Clear the API key cache
  void clearCache() {
    _keyCache.clear();
    _keyStatus.clear();
  }
}
