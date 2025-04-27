import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tradegasy/services/openrouter_service.dart';
import 'package:tradegasy/services/api_key_manager.dart';

class ApiDebuggingTools {
  final ApiKeyManager _apiKeyManager = ApiKeyManager();

  // Test OpenRouter API connection and show detailed results
  Future<void> testOpenRouterConnection(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Testing OpenRouter connection...'),
              ],
            ),
          ),
    );

    // Get API key
    final openrouterApiKey = await _apiKeyManager.getApiKey(
      ApiKeyType.openrouterApiKey,
    );

    // Check if API key exists
    if (openrouterApiKey == null || openrouterApiKey.isEmpty) {
      Navigator.pop(context); // Close loading dialog
      _showResult(context, false, 'No OpenRouter API key found');
      return;
    }

    // Check API key format
    if (!openrouterApiKey.startsWith('sk-')) {
      Navigator.pop(context); // Close loading dialog
      _showResult(
        context,
        false,
        'Invalid API key format. OpenRouter keys should start with "sk-"',
      );
      return;
    }

    try {
      // Test API connection
      final response = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openrouterApiKey',
              'HTTP-Referer': 'https://tradegasy.app',
              'X-Title': 'TradeGasy App',
            },
            body: jsonEncode({
              'model': 'anthropic/claude-3-haiku',
              'messages': [
                {'role': 'user', 'content': 'Hello, just testing connection'},
              ],
              'max_tokens': 10,
            }),
          )
          .timeout(const Duration(seconds: 10));

      // Close loading dialog
      Navigator.pop(context);

      // Show results based on response
      if (response.statusCode == 200) {
        _showResult(context, true, 'API connection successful');
      } else {
        // Parse error
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        final errorCode = errorData['error']?['code'] ?? response.statusCode;

        _showResult(
          context,
          false,
          'API Error ($errorCode): $errorMessage\n\n'
          'If the error persists, please verify your API key in the settings.',
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showResult(context, false, 'Connection error: $e');
    }
  }

  // Show test result dialog
  void _showResult(BuildContext context, bool success, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              success ? 'Connection Successful' : 'Connection Failed',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: success ? Colors.green : Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(message),
                const SizedBox(height: 12),
                if (!success)
                  const Text(
                    'Please check if your API key is correctly set up on openrouter.ai',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Run diagnostics for all API services
  Future<Map<String, dynamic>> runFullDiagnostics() async {
    Map<String, dynamic> results = {};

    // OpenRouter diagnostics
    try {
      results['openrouter'] = await _checkOpenRouterStatus();
    } catch (e) {
      results['openrouter'] = {
        'isValid': false,
        'message': 'Erreur lors de la vérification: ${_formatErrorMessage(e)}',
        'errorCode': _extractErrorCode(e.toString()),
      };
    }

    // Hugging Face diagnostics
    try {
      results['huggingface'] = await _checkHuggingFaceStatus();
    } catch (e) {
      results['huggingface'] = {
        'isValid': false,
        'message': 'Erreur lors de la vérification: ${_formatErrorMessage(e)}',
        'errorCode': _extractErrorCode(e.toString()),
      };
    }

    // Replicate diagnostics
    try {
      results['replicate'] = await _checkReplicateStatus();
    } catch (e) {
      results['replicate'] = {
        'isValid': false,
        'message': 'Erreur lors de la vérification: ${_formatErrorMessage(e)}',
        'errorCode': _extractErrorCode(e.toString()),
      };
    }

    // Binance diagnostics
    try {
      results['binance'] = await _checkBinanceStatus();
    } catch (e) {
      results['binance'] = {
        'isValid': false,
        'message': 'Erreur lors de la vérification: ${_formatErrorMessage(e)}',
        'errorCode': _extractErrorCode(e.toString()),
      };
    }

    return results;
  }

  // Helper function to format error messages in a consistent way
  String _formatErrorMessage(dynamic error) {
    String message = error.toString();

    // Check for 405 Method Not Allowed errors
    if (message.contains('405') && message.contains('Method Not Allowed')) {
      return '405 Method Not Allowed - Problème d\'URL API';
    }

    // Limit length of error messages for UI display
    if (message.length > 100) {
      message = '${message.substring(0, 97)}...';
    }

    return message;
  }

  // Extract error code from error message
  String _extractErrorCode(String errorMessage) {
    // Check for HTTP status codes
    RegExp statusCodeRegex = RegExp(r'(\d{3})');

    if (errorMessage.contains('405')) {
      return '405';
    }

    final match = statusCodeRegex.firstMatch(errorMessage);
    if (match != null) {
      return match.group(1) ?? '';
    }

    return '';
  }

  // Check OpenRouter status
  Future<Map<String, dynamic>> _checkOpenRouterStatus() async {
    ApiKeyStatus status = await _apiKeyManager.getApiKeyStatus(
      ApiKeyType.openrouterApiKey,
    );

    if (status == ApiKeyStatus.valid) {
      try {
        // Try to make a simple test request
        final response = await http.get(
          Uri.parse('https://openrouter.ai/api/v1/auth/key'),
          headers: {
            'Authorization':
                'Bearer ${await _apiKeyManager.getApiKey(ApiKeyType.openrouterApiKey)}',
            'HTTP-Referer': 'https://tradegasy.app',
            'X-Title': 'TradeGasy',
          },
        );

        if (response.statusCode == 200) {
          return {'isValid': true, 'message': 'API OpenRouter connectée'};
        } else if (response.statusCode == 405) {
          // Handle 405 Method Not Allowed explicitly
          return {
            'isValid': false,
            'message': 'Erreur 405 Method Not Allowed - Problème d\'URL API',
            'errorCode': '405',
          };
        } else {
          return {
            'isValid': false,
            'message': 'Erreur API: ${response.statusCode} - ${response.body}',
            'errorCode': response.statusCode.toString(),
          };
        }
      } catch (e) {
        if (e.toString().contains('405')) {
          return {
            'isValid': false,
            'message': 'Erreur 405 Method Not Allowed - Problème d\'URL API',
            'errorCode': '405',
          };
        }

        throw e;
      }
    } else {
      return {
        'isValid': false,
        'message': 'Clé API non configurée ou invalide (${status.toString()})',
      };
    }
  }

  // Check Hugging Face status
  Future<Map<String, dynamic>> _checkHuggingFaceStatus() async {
    ApiKeyStatus status = await _apiKeyManager.getApiKeyStatus(
      ApiKeyType.huggingfaceApiKey,
    );

    if (status == ApiKeyStatus.valid) {
      try {
        final apiKey = await _apiKeyManager.getApiKey(
          ApiKeyType.huggingfaceApiKey,
        );
        // Simple check for Hugging Face API
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
        if (response.statusCode == 200 || response.statusCode == 503) {
          return {'isValid': true, 'message': 'API Hugging Face connectée'};
        } else {
          return {
            'isValid': false,
            'message': 'Erreur API: ${response.statusCode} - ${response.body}',
            'errorCode': response.statusCode.toString(),
          };
        }
      } catch (e) {
        throw e;
      }
    } else {
      return {
        'isValid': false,
        'message': 'Clé API non configurée ou invalide (${status.toString()})',
      };
    }
  }

  // Check Replicate status
  Future<Map<String, dynamic>> _checkReplicateStatus() async {
    ApiKeyStatus status = await _apiKeyManager.getApiKeyStatus(
      ApiKeyType.replicateApiKey,
    );

    if (status == ApiKeyStatus.valid) {
      try {
        final apiKey = await _apiKeyManager.getApiKey(
          ApiKeyType.replicateApiKey,
        );
        // Simple check for Replicate API
        final response = await http
            .get(
              Uri.parse('https://api.replicate.com/v1/models'),
              headers: {'Authorization': 'Token $apiKey'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return {'isValid': true, 'message': 'API Replicate connectée'};
        } else {
          return {
            'isValid': false,
            'message': 'Erreur API: ${response.statusCode} - ${response.body}',
            'errorCode': response.statusCode.toString(),
          };
        }
      } catch (e) {
        throw e;
      }
    } else {
      return {
        'isValid': false,
        'message': 'Clé API non configurée ou invalide (${status.toString()})',
      };
    }
  }

  // Check Binance status
  Future<Map<String, dynamic>> _checkBinanceStatus() async {
    ApiKeyStatus apiKeyStatus = await _apiKeyManager.getApiKeyStatus(
      ApiKeyType.binanceApiKey,
    );

    ApiKeyStatus secretKeyStatus = await _apiKeyManager.getApiKeyStatus(
      ApiKeyType.binanceSecretKey,
    );

    if (apiKeyStatus == ApiKeyStatus.valid &&
        secretKeyStatus == ApiKeyStatus.valid) {
      try {
        // For Binance we don't make an actual API call here due to complexity of signature generation
        // Instead we just check if both keys are set and appear valid in format
        return {'isValid': true, 'message': 'Clés Binance configurées'};
      } catch (e) {
        throw e;
      }
    } else {
      return {
        'isValid': false,
        'message': 'Clés API Binance non configurées ou invalides',
      };
    }
  }

  // ... rest of the class methods remain the same ...
}

// Helper class
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
