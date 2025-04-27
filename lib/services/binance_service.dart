import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/services/api_key_manager.dart';

class BinanceService {
  final String _baseUrl = 'https://api.binance.com';
  String? _apiKey;
  String? _apiSecret;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  // Add a more robust initialization method
  Future<void> initialize() async {
    try {
      // Get API keys from the secure API key manager
      final apiKeyManager = ApiKeyManager();
      _apiKey = apiKeyManager.getApiKey(ApiKeyType.binanceApiKey);
      _apiSecret = apiKeyManager.getApiKey(ApiKeyType.binanceSecretKey);

      // If secure keys aren't available, try fallback to .env
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = dotenv.env['BINANCE_API_KEY'];
      }

      if (_apiSecret == null || _apiSecret!.isEmpty) {
        _apiSecret = dotenv.env['BINANCE_API_SECRET'];
      }

      if (_apiKey != null && _apiKey!.isNotEmpty) {
        print(
          "BinanceService initialized with key: ${_apiKey?.substring(0, min(10, _apiKey!.length))}...",
        );
        _initialized = true;
      } else {
        print('BinanceService: No API key available');
        _initialized = false;
      }
    } catch (e) {
      print('Error initializing BinanceService: $e');
      _initialized = false;
    }
  }

  // Generates a signature for authenticated endpoints
  String _generateSignature(Map<String, dynamic> params) {
    final queryString = Uri(queryParameters: params).query;
    final bytes = utf8.encode(queryString);
    final secretBytes = utf8.encode(_apiSecret!);
    final hmac = Hmac(sha256, secretBytes);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  // Get klines (candlestick data)
  Future<List<Candle>> getKlines({
    required String symbol,
    required String interval,
    int limit = 100,
  }) async {
    try {
      // Convertir les intervalles non standard en intervalles compatibles avec l'API
      String apiInterval = interval;

      // Pour les intervalles longs, on utilise un intervalle plus court mais on récupère plus de données
      int adjustedLimit = limit;

      if (interval == '7d') {
        apiInterval = '1d';
        adjustedLimit = limit * 7; // 7 jours = 7 points à intervalle journalier
      } else if (interval == '1M') {
        apiInterval = '1d';
        adjustedLimit = limit * 30; // 1 mois ≈ 30 jours
      } else if (interval == '6M') {
        apiInterval = '1w';
        adjustedLimit = limit * 26; // 6 mois ≈ 26 semaines
      } else if (interval == '1y') {
        apiInterval = '1w';
        adjustedLimit = limit * 52; // 1 an ≈ 52 semaines
      } else if (interval == '5y') {
        apiInterval = '1M'; // Intervalle mensuel
        adjustedLimit = limit * 5; // 5 ans = 60 mois
      }

      // Limiter à 1000 pour respecter les limites de l'API
      adjustedLimit = adjustedLimit.clamp(1, 1000);

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/v3/klines?symbol=$symbol&interval=$apiInterval&limit=$adjustedLimit',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('API returned status code ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as List;
      final candles =
          data.map((item) {
            final timestamp = item[0] as int;
            final open = double.parse(item[1]);
            final high = double.parse(item[2]);
            final low = double.parse(item[3]);
            final close = double.parse(item[4]);
            final volume = double.parse(item[5]);

            return Candle(
              time: DateTime.fromMillisecondsSinceEpoch(timestamp),
              open: open,
              high: high,
              low: low,
              close: close,
              volume: volume,
            );
          }).toList();

      return candles;
    } catch (e) {
      print('Error getting klines: $e');
      throw Exception('Failed to get klines: $e');
    }
  }

  // Get account information (authenticated endpoint)
  Future<AccountInfo> getAccountInfo() async {
    if (!_initialized) {
      await initialize();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final params = {'timestamp': timestamp};

    final signature = _generateSignature(params);
    params['signature'] = signature;

    final uri = Uri.parse(
      '$_baseUrl/api/v3/account',
    ).replace(queryParameters: params);

    final response = await http.get(uri, headers: {'X-MBX-APIKEY': _apiKey!});

    if (response.statusCode == 200) {
      return AccountInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load account info: ${response.body}');
    }
  }

  // Get current ticker prices
  Future<List<TickerPrice>> getTickers() async {
    if (!_initialized) {
      await initialize();
    }

    final uri = Uri.parse('$_baseUrl/api/v3/ticker/price');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => TickerPrice.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load tickers: ${response.body}');
    }
  }

  // Get 24hr ticker statistics
  Future<List<TickerStats>> get24hTickers() async {
    if (!_initialized) {
      await initialize();
    }

    final uri = Uri.parse('$_baseUrl/api/v3/ticker/24hr');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => TickerStats.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load 24h tickers: ${response.body}');
    }
  }

  // Get trading pairs for trading signals
  Future<List<String>> getTradingPairs() async {
    if (!_initialized) {
      await initialize();
    }

    final tickers = await getTickers();
    // Filter to get commonly traded pairs with null safety
    final majorPairs =
        tickers
            .where(
              (ticker) =>
                  ticker.symbol.endsWith('USDT') == true ||
                  ticker.symbol.endsWith('BUSD') == true ||
                  ticker.symbol.endsWith('BTC') == true,
            )
            .map((ticker) => ticker.symbol)
            .where((symbol) => symbol.isNotEmpty)
            .toList();

    return majorPairs;
  }
}
