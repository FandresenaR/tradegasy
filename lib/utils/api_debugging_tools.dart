import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tradegasy/services/api_key_manager.dart';

class ApiDebuggingTools {
  // Singleton
  static final ApiDebuggingTools _instance = ApiDebuggingTools._internal();
  factory ApiDebuggingTools() => _instance;
  ApiDebuggingTools._internal();

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
    final apiKeyManager = ApiKeyManager();
    final openrouterApiKey = await apiKeyManager.getApiKeyAsync(
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
}
