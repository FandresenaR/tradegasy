import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/services/mock_ai_service.dart';
import 'package:tradegasy/services/api_key_manager.dart';

class OpenRouterService {
  // API providers configuration
  final Map<String, AIProvider> _apiProviders = {
    'huggingface': AIProvider(
      name: 'Hugging Face',
      baseUrl: 'https://api-inference.huggingface.co/models',
      modelId: 'mistralai/Mistral-7B-Instruct-v0.2',
      requiresApiKey: true,
      apiKeyEnvName: 'HUGGINGFACE_API_KEY',
      apiKeyType: ApiKeyType.huggingfaceApiKey,
    ),
    'replicate': AIProvider(
      name: 'Replicate',
      baseUrl: 'https://api.replicate.com/v1/predictions',
      modelId: 'meta/llama-2-7b-chat',
      requiresApiKey: true,
      apiKeyEnvName: 'REPLICATE_API_KEY',
      apiKeyType: ApiKeyType.replicateApiKey,
    ),
    'openrouter_nvidia': AIProvider(
      name: 'OpenRouter (Nvidia Llama 3.1)',
      baseUrl: 'https://openrouter.ai/api/v1',
      modelId: 'nvidia/llama-3.1-nemotron-ultra-253b-v1:free',
      requiresApiKey: true,
      apiKeyEnvName: 'OPENROUTER_API_KEY',
      apiKeyType: ApiKeyType.openrouterApiKey,
    ),
    'openrouter_deepseek_base': AIProvider(
      name: 'OpenRouter (DeepSeek V3 Base)',
      baseUrl: 'https://openrouter.ai/api/v1',
      modelId: 'deepseek/deepseek-v3-base:free',
      requiresApiKey: true,
      apiKeyEnvName: 'OPENROUTER_API_KEY',
      apiKeyType: ApiKeyType.openrouterApiKey,
    ),
    'openrouter_deepseek_chat': AIProvider(
      name: 'OpenRouter (DeepSeek Chat V3)',
      baseUrl: 'https://openrouter.ai/api/v1',
      modelId: 'deepseek/deepseek-chat-v3-0324:free',
      requiresApiKey: true,
      apiKeyEnvName: 'OPENROUTER_API_KEY',
      apiKeyType: ApiKeyType.openrouterApiKey,
    ),
  };

  // Current service configuration
  String _currentProvider = 'openrouter_nvidia'; // Default to Nvidia Llama 3.1
  String? _apiKey;
  bool _isInitialized = false;
  bool _fallbackModeActive = false;
  late MockAiService _mockAiService;
  int _maxRetries = 3;

  // Add method to explicitly switch between the three OpenRouter models
  Future<bool> switchAiModel(String modelType) async {
    String providerKey;

    switch (modelType.toLowerCase()) {
      case 'nvidia':
      case 'llama':
      case 'llama3':
        providerKey = 'openrouter_nvidia';
        break;
      case 'deepseek':
      case 'deepseek-base':
      case 'base':
        providerKey = 'openrouter_deepseek_base';
        break;
      case 'deepseek-chat':
      case 'chat':
        providerKey = 'openrouter_deepseek_chat';
        break;
      default:
        print(
          'Unknown model type: $modelType. Using default Nvidia Llama 3.1.',
        );
        providerKey = 'openrouter_nvidia';
    }

    if (providerKey == _currentProvider) {
      print('Already using ${_apiProviders[providerKey]!.name}');
      return true;
    }

    print('Switching to ${_apiProviders[providerKey]!.name}...');
    if (await _initializeProvider(providerKey)) {
      _currentProvider = providerKey;
      _isInitialized = true;
      print('Successfully switched to: ${_apiProviders[providerKey]!.name}');
      return true;
    } else {
      print('Failed to switch to ${_apiProviders[providerKey]!.name}');
      return false;
    }
  }

  // Instance du gestionnaire de clés API
  final ApiKeyManager _apiKeyManager = ApiKeyManager();

  // Flag pour indiquer si un problème de connexion a été détecté
  bool _showedConnectionAlert = false;

  // Fonction de callback pour naviguer vers l'écran de diagnostic
  Function? _navigateToDiagnosticScreen;

  // Récupérer le nombre de tentatives maximum depuis les variables d'environnement
  int get maxRetries {
    final envRetries = dotenv.env['RETRY_COUNT'];
    if (envRetries != null && int.tryParse(envRetries) != null) {
      return int.parse(envRetries);
    }
    return _maxRetries;
  }

  // Expose the API key for debugging
  String? get apiKey => _apiKey;

  // Get the current provider
  AIProvider get currentProvider => _apiProviders[_currentProvider]!;

  // Définir la fonction de navigation vers l'écran de diagnostic
  void setNavigationCallback(Function callback) {
    // We're keeping this method but removing the assignment since the field is unused
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _showedConnectionAlert = false;

    try {
      print("Initializing AI service with provider: ${currentProvider.name}");

      // Initialize the fallback service
      _mockAiService = MockAiService();

      // Vérifier l'état des clés API
      await _checkApiKeys();

      // Try the current provider first
      if (await _initializeProvider(_currentProvider)) {
        _isInitialized = true;
        return;
      }

      // If that fails, try other providers
      for (var provider in _apiProviders.keys) {
        if (provider != _currentProvider) {
          if (await _initializeProvider(provider)) {
            _currentProvider = provider;
            _isInitialized = true;
            print("Successfully switched to provider: ${currentProvider.name}");
            return;
          }
        }
      }

      // Si on arrive ici, vérifions si le fallback mode est activé dans les variables d'environnement
      final enableFallback = dotenv.env['ENABLE_API_FALLBACK'];
      if (enableFallback?.toLowerCase() == 'true') {
        print("API fallback enabled, using mock service");
        _fallbackModeActive = true;
      } else {
        print(
          "Warning: No AI provider available and fallback mode is disabled",
        );
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing AI service: $e');
      _fallbackModeActive = true;
      _isInitialized = true;
    }
  }

  // Vérifier l'état des clés API et afficher une alerte si nécessaire
  Future<void> _checkApiKeys() async {
    bool allInvalid = true;

    for (var provider in _apiProviders.values) {
      if (provider.requiresApiKey) {
        final status = await _apiKeyManager.verifyApiKey(provider.apiKeyType);
        if (status == ApiKeyStatus.valid) {
          allInvalid = false;
          break;
        }
      }
    }

    if (allInvalid && !_showedConnectionAlert) {
      _showedConnectionAlert = true;
      print("WARNING: All API keys are invalid or not set!");
    }
  }

  // Initialize a specific provider
  Future<bool> _initializeProvider(String providerKey) async {
    if (!_apiProviders.containsKey(providerKey)) return false;

    var provider = _apiProviders[providerKey]!;
    print("Trying to initialize ${provider.name}...");

    // Charger la clé API depuis le gestionnaire de clés API
    if (provider.requiresApiKey) {
      // Vérifier d'abord si la clé est valide
      final status = await _apiKeyManager.verifyApiKey(provider.apiKeyType);

      if (status != ApiKeyStatus.valid) {
        print("${provider.name} API key is not valid (status: $status)");

        // Essayer de charger la clé depuis .env si disponible
        String? envKey = dotenv.env[provider.apiKeyEnvName];
        if (envKey != null && envKey.isNotEmpty) {
          _apiKey = envKey.trim();
          print("Loaded API key for ${provider.name} from .env");

          // Sauvegarder cette clé dans le gestionnaire
          await _apiKeyManager.saveApiKey(provider.apiKeyType, _apiKey!);

          // Re-vérifier le statut
          final newStatus = await _apiKeyManager.verifyApiKey(
            provider.apiKeyType,
          );
          if (newStatus != ApiKeyStatus.valid) {
            print(
              "${provider.name} API key from .env is not valid (status: $newStatus)",
            );
            return false;
          }
        } else {
          return false;
        }
      } else {
        // La clé est valide, on la charge
        _apiKey = await _apiKeyManager.getApiKeyAsync(provider.apiKeyType);
        print("Loaded valid API key for ${provider.name}");
      }

      // Test the API connection
      return await _testProviderConnection(providerKey);
    }

    // If the API doesn't require a key
    return true;
  }

  // Test the connection to a provider
  Future<bool> _testProviderConnection(String providerKey) async {
    if (!_apiProviders.containsKey(providerKey)) return false;

    var provider = _apiProviders[providerKey]!;

    try {
      // Obtenir le timeout depuis les variables d'environnement
      int timeoutSeconds = 10;
      final envTimeout = dotenv.env['API_TIMEOUT_SECONDS'];
      if (envTimeout != null && int.tryParse(envTimeout) != null) {
        timeoutSeconds = int.parse(envTimeout);
      }

      // Test different providers
      switch (providerKey) {
        case 'huggingface':
          // Test connection to Hugging Face
          final response = await http
              .post(
                Uri.parse('${provider.baseUrl}/${provider.modelId}'),
                headers: {
                  'Authorization': 'Bearer $_apiKey',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'inputs': 'Hello, can you hear me?',
                  'parameters': {'max_new_tokens': 5},
                }),
              )
              .timeout(Duration(seconds: timeoutSeconds));

          print("Test response from ${provider.name}: ${response.statusCode}");

          // Mettre à jour le statut de la clé
          if (response.statusCode == 200 || response.statusCode == 503) {
            await _apiKeyManager.verifyApiKey(provider.apiKeyType);
            return true;
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            // Clé API invalide
            await _apiKeyManager.saveApiKey(provider.apiKeyType, "");
            await _apiKeyManager.verifyApiKey(provider.apiKeyType);
            return false;
          }

          return false;

        case 'replicate':
          // Test connection to Replicate
          final response = await http
              .get(
                Uri.parse('https://api.replicate.com/v1/models'),
                headers: {'Authorization': 'Token $_apiKey'},
              )
              .timeout(Duration(seconds: timeoutSeconds));

          print("Test response from ${provider.name}: ${response.statusCode}");

          // Mettre à jour le statut de la clé
          if (response.statusCode == 200) {
            await _apiKeyManager.verifyApiKey(provider.apiKeyType);
            return true;
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            // Clé API invalide
            await _apiKeyManager.saveApiKey(provider.apiKeyType, "");
            await _apiKeyManager.verifyApiKey(provider.apiKeyType);
            return false;
          }

          return false;

        case 'openrouter_nvidia':
        case 'openrouter_deepseek_base':
        case 'openrouter_deepseek_chat':
          // Test connection to OpenRouter
          final response = await http
              .get(
                Uri.parse('https://openrouter.ai/api/v1/models'),
                headers: {
                  'Authorization': 'Bearer $_apiKey',
                  'HTTP-Referer': 'https://tradegasy.app',
                  'X-Title': 'TradeGasy',
                },
              )
              .timeout(Duration(seconds: timeoutSeconds));

          print("Test response from ${provider.name}: ${response.statusCode}");

          // Mettre à jour le statut de la clé
          if (response.statusCode == 200) {
            // Mettre à jour le statut comme valide
            await _apiKeyManager.verifyApiKey(provider.apiKeyType);
            return true;
          } else if (response.statusCode == 401) {
            // Clé API invalide
            await _apiKeyManager.saveApiKey(provider.apiKeyType, "");
            await _apiKeyManager.verifyApiKey(provider.apiKeyType);
            print(
              "ERROR: OpenRouter API key invalid or expired (401). Please check your key.",
            );
            return false;
          }

          return false;

        default:
          return false;
      }
    } catch (e) {
      print("Error testing connection to ${provider.name}: $e");
      await _apiKeyManager.saveApiKey(provider.apiKeyType, "");
      await _apiKeyManager.verifyApiKey(provider.apiKeyType);
      return false;
    }
  }

  // Determine if a question is chart-related
  bool isChartRelatedQuestion(String question) {
    final chartKeywords = [
      'chart',
      'price',
      'trend',
      'analysis',
      'market',
      'bullish',
      'bearish',
      'support',
      'resistance',
      'indicator',
      'candlestick',
      'timeframe',
      'volume',
      'moving average',
      'macd',
      'rsi',
      'stochastic',
      'overbought',
      'oversold',
      'breakout',
      'consolidation',
      'correction',
      'reversal',
      'buy',
      'sell',
      'profit',
      'loss',
      'trade',
      'entry',
      'exit',
      'stop loss',
      'take profit',
      'candle',
      'pattern',
      'flag',
      'head and shoulders',
      'doji',
    ];

    return chartKeywords.any(
      (keyword) => question.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  // Generate a general response for non-chart questions
  Future<String> generateGeneralResponse({
    required String userQuestion,
    required List<String> conversationHistory,
  }) async {
    // Ensure the service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Si toutes les clés API sont invalides, suggérer le diagnostic
    if (_needsApiKeyDiagnostic()) {
      return _getApiDiagnosticMessage("répondre à votre question");
    }

    // If fallback mode is active, use a simple response
    if (_fallbackModeActive) {
      print('Using local general response (fallback mode active)');
      return "Je suis actuellement en mode hors-ligne et mes capacités sont limitées. "
          "Pour résoudre ce problème, veuillez vérifier vos clés API dans les paramètres de l'application > Diagnostic des API.\n\n"
          "Voici ma meilleure réponse: ${userQuestion.contains('?') ? 'Pour répondre à votre question sur ' + userQuestion.replaceAll('?', '') + ', j\'aurais besoin de plus de contexte.' : 'Je comprends que vous voulez discuter de ' + userQuestion + '. Pourriez-vous fournir plus de détails?'}";
    }

    // Try using the current provider
    try {
      print('Generating general response using ${currentProvider.name}');
      String response;

      switch (_currentProvider) {
        case 'huggingface':
          response = await _generateGeneralWithHuggingFace(
            userQuestion,
            conversationHistory,
          );
          break;
        case 'replicate':
          response = await _generateGeneralWithReplicate(
            userQuestion,
            conversationHistory,
          );
          break;
        case 'openrouter_nvidia':
        case 'openrouter_deepseek_base':
        case 'openrouter_deepseek_chat':
          response = await _generateGeneralWithOpenRouter(
            userQuestion,
            conversationHistory,
          );
          break;
        default:
          throw Exception('Unknown provider: $_currentProvider');
      }

      // Clean up the response
      return response;
    } catch (e) {
      print('Error using ${currentProvider.name} for general response: $e');

      // Try fallback providers
      for (var provider in _apiProviders.keys) {
        if (provider != _currentProvider) {
          try {
            if (await _initializeProvider(provider)) {
              _currentProvider = provider;
              print(
                'Switched to alternative provider for general response: ${currentProvider.name}',
              );

              // Try with the new provider
              switch (provider) {
                case 'huggingface':
                  return await _generateGeneralWithHuggingFace(
                    userQuestion,
                    conversationHistory,
                  );
                case 'replicate':
                  return await _generateGeneralWithReplicate(
                    userQuestion,
                    conversationHistory,
                  );
                case 'openrouter_nvidia':
                case 'openrouter_deepseek_base':
                case 'openrouter_deepseek_chat':
                  return await _generateGeneralWithOpenRouter(
                    userQuestion,
                    conversationHistory,
                  );
              }
            }
          } catch (e) {
            print(
              'Error with alternative provider ${_apiProviders[provider]!.name} for general response: ${_formatApiErrorMessage(e.toString())}',
            );
          }
        }
      }

      // Si toutes les clés API sont invalides, suggérer le diagnostic
      return _getApiDiagnosticMessage("répondre à votre question");
    }
  }

  // Vérifier si un diagnostic des clés API est nécessaire
  bool _needsApiKeyDiagnostic() {
    bool allInvalid = true;

    for (var provider in _apiProviders.values) {
      if (provider.requiresApiKey) {
        final status = _apiKeyManager.getApiKeyStatus(provider.apiKeyType);
        if (status == ApiKeyStatus.valid) {
          allInvalid = false;
          break;
        }
      }
    }

    return allInvalid;
  }

  // Helper method to clean up and format AI responses
  String _cleanupGeneralResponseFormat(String response) {
    // Remove any assistant prefixes that might be in the response
    response = response.replaceAll(
      RegExp(r'^(Assistant:|Bot:|AI:)\s*', caseSensitive: false),
      '',
    );

    // Trim any extra whitespace
    response = response.trim();

    // If the response is empty, provide a fallback
    if (response.isEmpty) {
      return "Je n'ai pas pu générer une réponse. Veuillez réessayer.";
    }

    return response;
  }

  // Fonction pour corriger l'encodage des caractères accentués dans une réponse
  String _fixEncodingIssues(String text) {
    // Remplacer les caractères mal encodés courants en français
    final Map<String, String> encodingFixes = {
      'Ã©': 'é',
      'Ã¨': 'è',
      'Ã': 'à',
      'Ãª': 'ê',
      'Ã«': 'ë',
      'Ã¯': 'ï',
      'Ã®': 'î',
      'Ã´': 'ô',
      'Ã¹': 'ù',
      'Ã»': 'û',
      'Ã§': 'ç',
      'Å"': 'œ',
      'Â°': '°',
      'Â«': '«',
      'Â»': '»',
    };

    // Appliquer les corrections
    String fixedText = text;
    encodingFixes.forEach((key, value) {
      fixedText = fixedText.replaceAll(key, value);
    });

    return fixedText;
  }

  // Add this new method
  Future<String> generateMarketAnalysis({
    required String symbol,
    required String interval,
    required List<Candle> candles,
    List<String>? conversationHistory,
    required String userQuestion,
    String? locale, // Ajout du paramètre de langue
  }) async {
    // Ensure the service is initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Si toutes les clés API sont invalides, suggérer le diagnostic
    if (_needsApiKeyDiagnostic()) {
      return _getApiDiagnosticMessage("analyser le marché");
    }

    // If fallback mode is active, use the mock service
    if (_fallbackModeActive) {
      print('Using local market analysis (fallback mode active)');
      return _mockAiService.generateMarketAnalysis(
        symbol: symbol,
        interval: interval,
        candles: candles,
        question: userQuestion,
        locale: locale, // Passer la langue au service mock
      );
    }

    // Déterminer la langue à utiliser
    String language = 'English';
    String languageCode = locale?.split('_')[0] ?? 'en';

    if (languageCode == 'fr') {
      language = 'French';
    }

    try {
      print(
        'Generating market analysis using ${currentProvider.name} in $language',
      );

      // Préparer les données des chandeliers pour l'analyse
      final List<Map<String, dynamic>> candleData =
          candles
              .map(
                (c) => {
                  'time': c.time.toIso8601String(),
                  'open': c.open,
                  'high': c.high,
                  'low': c.low,
                  'close': c.close,
                  'volume': c.volume,
                },
              )
              .toList();

      // Create messages array for the OpenRouter chat completions API
      List<Map<String, String>> messages = [];

      // Add system message with language instruction
      messages.add({
        'role': 'system',
        'content':
            'You are a helpful assistant for cryptocurrency traders specialized in technical analysis. ' +
            'Provide clear, conversational responses analyzing the chart data provided. ' +
            'Please respond in $language. ' + // Instruction de langue
            'Provide a comprehensive analysis with actionable insights.',
      });

      // Add chart data context for analysis
      String chartDataContext =
          'I am analyzing $symbol chart data on $interval timeframe. ' +
          'The most recent candlestick data is as follows (showing last 10 candles): \n';

      // Include only the last 10 candles to avoid overwhelming the model
      final last10Candles =
          candleData.length > 10
              ? candleData.sublist(candleData.length - 10)
              : candleData;

      chartDataContext += last10Candles
          .map(
            (c) =>
                'Time: ${c['time']}, Open: ${c['open']}, High: ${c['high']}, ' +
                'Low: ${c['low']}, Close: ${c['close']}, Volume: ${c['volume']}',
          )
          .join('\n');

      // Add chart context as a user message
      messages.add({'role': 'user', 'content': chartDataContext});

      // Add assistant acknowledgment
      messages.add({
        'role': 'assistant',
        'content':
            languageCode == 'fr'
                ? 'J\'ai reçu les données du graphique pour $symbol sur l\'intervalle $interval. Que souhaitez-vous savoir à ce sujet?'
                : 'I have received the chart data for $symbol on $interval timeframe. What would you like to know about it?',
      });

      // Add current question
      messages.add({'role': 'user', 'content': userQuestion});

      // Use the full URL for OpenRouter
      String apiEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
      final provider = _apiProviders[_currentProvider]!;

      // Calculate a safe max_tokens value
      int maxTokens = 300; // Safe value for free tier
      int retriesLeft = maxRetries;

      while (retriesLeft > 0) {
        try {
          final response = await http.post(
            Uri.parse(apiEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'HTTP-Referer': 'https://tradegasy.app',
              'X-Title': 'TradeGasy',
            },
            body: jsonEncode({
              'model': provider.modelId,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': maxTokens,
            }),
          );

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse != null &&
                jsonResponse['choices'] != null &&
                jsonResponse['choices'].isNotEmpty &&
                jsonResponse['choices'][0]['message'] != null) {
              final content = jsonResponse['choices'][0]['message']['content'];

              // Corriger les problèmes d'encodage des caractères accentués si la réponse est en français
              if (languageCode == 'fr') {
                return _fixEncodingIssues(content);
              }

              return content;
            } else {
              print(
                "Warning: Unexpected OpenRouter response structure: ${response.body}",
              );
              return languageCode == 'fr'
                  ? "Je n'ai pas pu générer une analyse. Veuillez réessayer."
                  : "I couldn't generate an analysis. Please try again.";
            }
          } else if (response.statusCode == 402) {
            // Credit limit error
            return languageCode == 'fr'
                ? "Je ne peux pas générer une analyse complète en raison des limites de crédits sur la version gratuite."
                : "I cannot generate a complete analysis due to credit limits on the free version.";
          } else {
            // Retry for other errors
            retriesLeft--;
            if (retriesLeft > 0) {
              await Future.delayed(Duration(seconds: 1));
            }
          }
        } catch (e) {
          print('Error in OpenRouter request: ${e.toString()}');
          retriesLeft--;
          if (retriesLeft > 0) {
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }

      // If we reach here, we've exhausted all retries
      // Fall back to the mock service
      print('Falling back to mock AI service after OpenRouter failures');
      String response = await _mockAiService.generateMarketAnalysis(
        symbol: symbol,
        interval: interval,
        candles: candles,
        question: userQuestion,
        locale: locale,
      );

      // Corriger les problèmes d'encodage même pour les réponses du service mock
      if (languageCode == 'fr') {
        return _fixEncodingIssues(response);
      }

      return response;
    } catch (e) {
      print('Error generating market analysis: $e');
      // Fall back to the mock service
      String response = await _mockAiService.generateMarketAnalysis(
        symbol: symbol,
        interval: interval,
        candles: candles,
        question: userQuestion,
        locale: locale,
      );

      // Corriger les problèmes d'encodage même pour les réponses du service mock
      if (languageCode == 'fr') {
        return _fixEncodingIssues(response);
      }

      return response;
    }
  }

  // Générer un message suggérant le diagnostic des API
  String _getApiDiagnosticMessage(String action) {
    return "Je ne peux pas $action car je n'arrive pas à me connecter aux services d'IA.\n\n"
        "Veuillez vérifier vos clés API dans les paramètres de l'application > Diagnostic des API.\n\n"
        "Vous pouvez:\n"
        "1. Vérifier la validité de vos clés API\n"
        "2. Essayer les clés de démo si disponibles\n"
        "3. Mettre à jour vos clés API avec des clés valides";
  }

  // Generate general response with Hugging Face
  Future<String> _generateGeneralWithHuggingFace(
    String userQuestion,
    List<String> conversationHistory,
  ) async {
    final provider = _apiProviders['huggingface']!;

    // Create a general conversation prompt without chart data
    String prompt = "<s>[INST] ";

    // Add system instruction
    prompt += "You are a helpful assistant for cryptocurrency traders. ";
    prompt +=
        "You provide clear, conversational responses to general questions. ";

    // Add conversation history
    if (conversationHistory.isNotEmpty) {
      prompt += "\n\nPrevious conversation:\n";
      for (int i = 0; i < conversationHistory.length; i++) {
        if (i % 2 == 0) {
          prompt += "User: ${conversationHistory[i]}\n";
        } else {
          prompt += "Assistant: ${conversationHistory[i]}\n";
        }
      }
    }

    // Add current question
    prompt += "\n\nUser question: $userQuestion [/INST]";

    final response = await http.post(
      Uri.parse('${provider.baseUrl}/${provider.modelId}'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': 512,
          'temperature': 0.7, // Higher temperature for more varied responses
          'top_p': 0.9,
          'do_sample': true,
        },
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String generatedText =
          jsonResponse[0]['generated_text'] ??
          'I don\'t have an answer for that right now.';
      return generatedText;
    } else {
      // Mettre à jour le statut de la clé si erreur d'authentification
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _apiKeyManager.saveApiKey(provider.apiKeyType, "");
        await _apiKeyManager.verifyApiKey(provider.apiKeyType);
      }
      throw Exception('API error: ${response.statusCode}');
    }
  }

  // Generate general response with Replicate
  Future<String> _generateGeneralWithReplicate(
    String userQuestion,
    List<String> conversationHistory,
  ) async {
    final provider = _apiProviders['replicate']!;

    // Create a general conversation prompt
    String prompt = "<s>[INST] <<SYS>>\n";
    prompt += "You are a helpful assistant for cryptocurrency traders. ";
    prompt +=
        "Provide natural, conversational responses to general questions.\n";
    prompt += "<</SYS>>\n\n";

    // Add conversation history
    if (conversationHistory.isNotEmpty) {
      prompt += "Previous messages:\n";
      for (int i = 0; i < conversationHistory.length; i++) {
        if (i % 2 == 0) {
          prompt += "User: ${conversationHistory[i]}\n";
        } else {
          prompt += "Assistant: ${conversationHistory[i]}\n";
        }
      }
      prompt += "\n";
    }

    prompt += "$userQuestion [/INST]";

    // Create a prediction
    final createResponse = await http.post(
      Uri.parse(provider.baseUrl),
      headers: {
        'Authorization': 'Token $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'version': provider.modelId,
        'input': {
          'prompt': prompt,
          'max_new_tokens': 512,
          'temperature': 0.7, // Higher temperature for more varied responses
        },
      }),
    );

    if (createResponse.statusCode != 201) {
      // Mettre à jour le statut de la clé si erreur d'authentification
      if (createResponse.statusCode == 401 ||
          createResponse.statusCode == 403) {
        await _apiKeyManager.saveApiKey(provider.apiKeyType, "");
        await _apiKeyManager.verifyApiKey(provider.apiKeyType);
      }
      throw Exception(
        'Failed to create prediction: ${createResponse.statusCode}',
      );
    }

    final createJson = jsonDecode(createResponse.body);
    final String predictionId = createJson['id'];

    // Wait for prediction completion
    String? output;
    for (int i = 0; i < 30; i++) {
      await Future.delayed(Duration(seconds: 2));

      final getResponse = await http.get(
        Uri.parse('${provider.baseUrl}/$predictionId'),
        headers: {'Authorization': 'Token $_apiKey'},
      );

      if (getResponse.statusCode == 200) {
        final getJson = jsonDecode(getResponse.body);
        if (getJson['status'] == 'succeeded') {
          output = getJson['output'];
          break;
        } else if (getJson['status'] == 'failed') {
          throw Exception('Prediction failed: ${getJson['error']}');
        }
      }
    }

    if (output == null) {
      throw Exception('Prediction timed out');
    }

    return output;
  }

  // Generate general response with OpenRouter
  Future<String> _generateGeneralWithOpenRouter(
    String userQuestion,
    List<String> conversationHistory,
  ) async {
    final provider = _apiProviders[_currentProvider]!;

    // Create messages array for the OpenRouter chat completions API
    List<Map<String, String>> messages = [];

    // Add system message
    messages.add({
      'role': 'system',
      'content':
          'You are a helpful assistant for cryptocurrency traders. You provide clear, conversational responses to general questions.',
    });

    // Add conversation history
    if (conversationHistory.isNotEmpty) {
      for (int i = 0; i < conversationHistory.length; i += 2) {
        if (i < conversationHistory.length) {
          messages.add({'role': 'user', 'content': conversationHistory[i]});
        }
        if (i + 1 < conversationHistory.length) {
          messages.add({
            'role': 'assistant',
            'content': conversationHistory[i + 1],
          });
        }
      }
    }

    // Add current question
    messages.add({'role': 'user', 'content': userQuestion});

    // Calculate a safe max_tokens value based on the model
    int maxTokens = 220; // Default safe value for free tier

    // Récupérer le nombre de tentatives depuis les variables d'environnement
    int retriesLeft = maxRetries;
    Exception? lastError;

    // Use the full URL for OpenRouter instead of relying on baseUrl to avoid 405 errors
    String apiEndpoint = 'https://openrouter.ai/api/v1/chat/completions';

    while (retriesLeft > 0) {
      try {
        final response = await http.post(
          Uri.parse(apiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'https://tradegasy.app',
            'X-Title': 'TradeGasy',
          },
          body: jsonEncode({
            'model': provider.modelId,
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': maxTokens,
          }),
        );

        if (response.statusCode == 200) {
          // Mettre à jour le statut comme valide
          await _apiKeyManager.verifyApiKey(provider.apiKeyType);

          final jsonResponse = jsonDecode(response.body);
          // Add null-safety checks to prevent the NoSuchMethodError
          if (jsonResponse != null &&
              jsonResponse['choices'] != null &&
              jsonResponse['choices'].isNotEmpty &&
              jsonResponse['choices'][0]['message'] != null &&
              jsonResponse['choices'][0]['message']['content'] != null) {
            final content = jsonResponse['choices'][0]['message']['content'];
            return content;
          } else {
            print(
              "Warning: Unexpected OpenRouter response structure: ${response.body}",
            );
            return "Je n'ai pas pu générer une réponse. Veuillez réessayer ou vérifier votre clé API OpenRouter.";
          }
        } else if (response.statusCode == 402) {
          // Credit limit error - try with even fewer tokens
          final jsonResponse = jsonDecode(response.body);
          String errorMessage = "Credit limit error";

          if (jsonResponse != null &&
              jsonResponse['error'] != null &&
              jsonResponse['error']['message'] != null) {
            errorMessage = jsonResponse['error']['message'];

            // Extract available token count if present in the error message
            final tokenRegex = RegExp(r'can only afford (\d+)');
            final match = tokenRegex.firstMatch(errorMessage);

            if (match != null && match.groupCount >= 1) {
              final availableTokens = int.tryParse(match.group(1) ?? "0") ?? 0;
              if (availableTokens > 0) {
                maxTokens = availableTokens - 20; // Leave some margin
                if (maxTokens < 50) maxTokens = 50; // Minimum sensible value

                print(
                  "Adjusting max_tokens to $maxTokens based on available credits",
                );
                retriesLeft--; // Retry with adjusted token count
                continue;
              }
            }
          }

          print("OpenRouter credit limit reached: $errorMessage");
          return "Je ne peux pas générer une analyse complète en raison des limites de crédits sur la version gratuite. Essayez une question plus courte ou passez à une version payante d'OpenRouter pour des réponses plus détaillées.";
        } else if (response.statusCode == 401) {
          // Mettre à jour le statut comme invalide
          await _apiKeyManager.saveApiKey(provider.apiKeyType, "");
          await _apiKeyManager.verifyApiKey(provider.apiKeyType);

          // Problème d'authentification - pas besoin de réessayer
          throw Exception(
            'API key invalid or expired (401). Please check your OpenRouter API key.',
          );
        } else if (response.statusCode == 405) {
          // 405 Error should never happen now that we're using the full URL
          print(
            "Still received 405 Method Not Allowed despite using the full URL.",
          );
          throw Exception(
            'API error: 405 Method Not Allowed. The OpenRouter API endpoint may have changed.',
          );
        } else {
          // Autres erreurs peuvent être réessayées
          lastError = Exception(
            'API error: ${response.statusCode}, Message: ${response.body}',
          );
          retriesLeft--;
          if (retriesLeft > 0) {
            print('Retrying OpenRouter request, attempts left: $retriesLeft');
            await Future.delayed(
              Duration(seconds: 1),
            ); // Small delay before retry
          }
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        retriesLeft--;
        if (retriesLeft > 0) {
          print(
            'Error in OpenRouter request: ${_formatApiErrorMessage(e.toString())}',
          );
          print('Retrying, attempts left: $retriesLeft');
          await Future.delayed(
            Duration(seconds: 1),
          ); // Small delay before retry
        }
      }
    }

    // We've exhausted all retries
    if (lastError != null) {
      throw lastError;
    }

    return "Je n'ai pas pu générer une réponse. Veuillez réessayer ou vérifier votre connexion internet.";
  }

  // Helper method to format API error messages for better logging
  String _formatApiErrorMessage(String errorMessage) {
    // Trim the error message if it's too long
    if (errorMessage.length > 150) {
      return '${errorMessage.substring(0, 147)}...';
    }

    // Remove any sensitive data like API keys that might be in the error
    errorMessage = errorMessage.replaceAll(
      RegExp(r'Bearer [a-zA-Z0-9_-]+'),
      'Bearer [REDACTED]',
    );
    errorMessage = errorMessage.replaceAll(
      RegExp(r'Token [a-zA-Z0-9_-]+'),
      'Token [REDACTED]',
    );

    return errorMessage;
  }
}

// Class to represent an API provider
class AIProvider {
  final String name;
  final String baseUrl;
  final String modelId;
  final bool requiresApiKey;
  final String apiKeyEnvName;
  final ApiKeyType apiKeyType;

  AIProvider({
    required this.name,
    required this.baseUrl,
    required this.modelId,
    required this.requiresApiKey,
    required this.apiKeyEnvName,
    required this.apiKeyType,
  });
}
