import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/utils/constants.dart';

class OpenRouterService {
  final String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  String? _apiKey;
  final http.Client _httpClient = http.Client();
  bool _initialized = false;

  // Add initialization method
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Try to get API key from .env, fall back to constants
      _apiKey = dotenv.env['OPENROUTER_API_KEY'];

      // If .env access failed, use constants
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = AppConstants.OPENROUTER_API_KEY;
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing OpenRouterService: $e');
      // Fall back to constants
      _apiKey = AppConstants.OPENROUTER_API_KEY;
      _initialized = true;
    }
  }

  /// Generate a response from the model
  Future<String> generateMarketAnalysis({
    required String symbol,
    required String interval,
    required List<Candle> candles,
    required List<String> conversationHistory,
    String? userQuestion,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (candles.isEmpty) {
      return "Sorry, I can't provide analysis without market data.";
    }

    // Extract analysis context from candles
    final context = _createAnalysisContext(symbol, interval, candles);

    // Create the messages for the API
    final messages = _createChatMessages(
      context,
      conversationHistory,
      userQuestion,
      symbol,
    );

    try {
      // Try to fetch a response from OpenRouter
      return await _fetchFromOpenRouter(messages);
    } catch (e) {
      print('API request error: $e');
      // Return a fallback response when API fails
      return _generateFallbackResponse(symbol, interval, candles);
    }
  }

  /// Create analysis context from market data
  String _createAnalysisContext(
    String symbol,
    String interval,
    List<Candle> candles,
  ) {
    final openPrice = candles.first.open;
    final closePrice = candles.last.close;
    final highPrice = candles
        .map((c) => c.high)
        .reduce((a, b) => a > b ? a : b);
    final lowPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final changePercent = ((closePrice - openPrice) / openPrice) * 100;
    final startDate = candles.first.time.toIso8601String();
    final endDate = candles.last.time.toIso8601String();
    final averageVolume =
        candles.map((c) => c.volume).reduce((a, b) => a + b) / candles.length;

    return '''
Current analysis for $symbol over $interval timeframe:
- Time Period: $startDate to $endDate
- Opening Price: $openPrice
- Current Price: $closePrice
- Highest Price: $highPrice
- Lowest Price: $lowPrice
- Change: ${changePercent.toStringAsFixed(2)}%
- Average Volume: ${averageVolume.toStringAsFixed(2)}

''';
  }

  /// Create chat messages for API request
  List<Map<String, dynamic>> _createChatMessages(
    String context,
    List<String> history,
    String? userQuestion,
    String symbol,
  ) {
    final messages = <Map<String, dynamic>>[];

    // Add system prompt with context
    messages.add({
      "role": "system",
      "content":
          "You are an expert cryptocurrency and forex trading analyst. "
          "Analyze market data and provide concise, professional trading insights. "
          "Focus on potential support/resistance levels, trend analysis, and trading opportunities. "
          "Base your analysis ONLY on the provided data and timeframe. "
          "Keep responses under 150 words and be specific to the current chart.",
    });

    // Add conversation history
    final historyToSend =
        history.length > 10 ? history.sublist(history.length - 10) : history;

    for (int i = 0; i < historyToSend.length; i++) {
      final role = i % 2 == 0 ? "user" : "assistant";
      messages.add({"role": role, "content": historyToSend[i]});
    }

    // Add current question
    final question =
        userQuestion ??
        "Analyze the current chart for $symbol and provide trading insights";
    messages.add({"role": "user", "content": "$context\n$question"});

    return messages;
  }

  /// Make API request to OpenRouter
  Future<String> _fetchFromOpenRouter(
    List<Map<String, dynamic>> messages,
  ) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'HTTP-Referer': 'https://tradegasy.app',
    };

    final payload = {
      "model":
          "anthropic/claude-3-haiku", // Use Claude as fallback (more stable than deepseek)
      "messages": messages,
      "temperature": 0.7,
      "max_tokens":
          1000, // Increased from 400 to 1000 to handle longer responses
    };

    try {
      // Set timeout to avoid hanging app
      final response = await _httpClient
          .post(
            Uri.parse(_baseUrl),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 30),
          ); // Increased timeout for longer responses

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print(
          'Error from OpenRouter (${response.statusCode}): ${response.body}',
        );
        throw Exception('API returned status code ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Generate a local fallback response when API fails
  String _generateFallbackResponse(
    String symbol,
    String interval,
    List<Candle> candles,
  ) {
    final openPrice = candles.first.open;
    final closePrice = candles.last.close;
    final percentChange = ((closePrice - openPrice) / openPrice) * 100;
    final trend = percentChange > 0 ? "upward" : "downward";

    return """
Based on the chart data, $symbol is showing a $trend trend over the $interval timeframe with a ${percentChange.abs().toStringAsFixed(2)}% change.

Due to connectivity issues, I'm providing a basic analysis. The market appears to be ${percentChange > 0 ? "bullish" : "bearish"} in this timeframe.

For more detailed insights, please try again when your connection to the analysis service is restored.
""";
  }
}
