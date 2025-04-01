import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/utils/constants.dart';

class BinanceService {
  final String _baseUrl = 'https://api.binance.com';
  String? _apiKey;
  String? _apiSecret;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  // Add a more robust initialization method
  Future<void> initialize() async {
    try {
      // Try to get API keys from .env, fall back to constants
      _apiKey = dotenv.env['BINANCE_API_KEY'];
      _apiSecret = dotenv.env['BINANCE_API_SECRET'];

      // If .env access failed, use constants
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = AppConstants.BINANCE_API_KEY;
        _apiSecret = AppConstants.BINANCE_API_SECRET;
      }

      print(
        "BinanceService initialized with key: ${_apiKey?.substring(0, 10)}...",
      );
      _initialized = true;
    } catch (e) {
      print('Error initializing BinanceService: $e');
      // Fall back to constants
      _apiKey = AppConstants.BINANCE_API_KEY;
      _apiSecret = AppConstants.BINANCE_API_SECRET;
      _initialized = true;
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
    int? limit,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Handle extended intervals
    if (['7d', '1M', '6M', '1y', '5y'].contains(interval)) {
      return _getExtendedKlines(symbol, interval, limit);
    }

    final params = {
      'symbol': symbol,
      'interval': interval,
      if (limit != null) 'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$_baseUrl/api/v3/klines',
    ).replace(queryParameters: params);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Candle.fromBinanceData(e)).toList();
    } else {
      throw Exception('Failed to load klines: ${response.body}');
    }
  }

  // Handle extended intervals by fetching multiple standard intervals and aggregating
  Future<List<Candle>> _getExtendedKlines(
    String symbol,
    String interval,
    int? limit,
  ) async {
    String binanceInterval;
    int multiplier;

    // Convert custom intervals to standard Binance intervals with appropriate multipliers
    switch (interval) {
      case '7d':
        binanceInterval = '1d';
        multiplier = 7;
        break;
      case '1M':
        binanceInterval = '1d';
        multiplier = 30;
        break;
      case '6M':
        binanceInterval = '1w';
        multiplier = 26; // ~6 months
        break;
      case '1y':
        binanceInterval = '1w';
        multiplier = 52; // ~1 year
        break;
      case '5y':
        binanceInterval = '1M';
        multiplier = 60; // 5 years
        break;
      default:
        throw Exception('Unsupported interval: $interval');
    }

    // Calculate a reasonable limit to get enough data points
    final effectiveLimit = limit ?? 100;

    final params = {
      'symbol': symbol,
      'interval': binanceInterval,
      'limit': (effectiveLimit * multiplier).toString(),
    };

    final uri = Uri.parse(
      '$_baseUrl/api/v3/klines',
    ).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final candles = data.map((e) => Candle.fromBinanceData(e)).toList();

      // For longer timeframes, we might want to aggregate the data
      if (candles.length > effectiveLimit) {
        return _aggregateCandles(candles, effectiveLimit);
      }

      return candles;
    } else {
      throw Exception('Failed to load extended klines: ${response.body}');
    }
  }

  // Aggregate candles to reduce data points for visualization
  List<Candle> _aggregateCandles(List<Candle> candles, int targetCount) {
    if (candles.length <= targetCount) return candles;

    final step = candles.length ~/ targetCount;
    final result = <Candle>[];

    for (int i = 0; i < candles.length; i += step) {
      final endIdx = i + step < candles.length ? i + step : candles.length;
      final chunk = candles.sublist(i, endIdx);

      if (chunk.isEmpty) continue;

      final open = chunk.first.open;
      final close = chunk.last.close;
      final high = chunk.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final low = chunk.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      final volume = chunk.map((c) => c.volume).reduce((a, b) => a + b);

      result.add(
        Candle(
          time: chunk.first.time,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ),
      );
    }

    return result;
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
    // Filter to get commonly traded pairs
    final majorPairs =
        tickers
            .where(
              (ticker) =>
                  ticker.symbol.endsWith('USDT') ||
                  ticker.symbol.endsWith('BUSD') ||
                  ticker.symbol.endsWith('BTC'),
            )
            .map((ticker) => ticker.symbol)
            .toList();

    return majorPairs;
  }
}
