import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tradegasy/services/api_key_manager.dart';
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/utils/technical_analysis.dart';

class MarketDataService {
  final ApiKeyManager? apiKeyManager;

  MarketDataService({this.apiKeyManager});

  Future<Map<String, dynamic>> getBinanceData(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.binance.com$endpoint'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getCoinMarketCapData(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('https://pro-api.coinmarketcap.com/v1$endpoint'),
        headers: {
          'X-CMC_PRO_API_KEY':
              apiKeyManager?.getApiKey(ApiKeyType.openrouterApiKey) ?? '',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Fetches detailed technical analysis data with numerical indicators
  /// that can be referenced in AI-generated market analysis
  Future<Map<String, dynamic>> getTechnicalAnalysisData(
    List<Candle> candles,
    String symbol,
    String interval,
  ) async {
    // Calculate key technical indicators
    List<double> prices = candles.map((c) => c.close).toList();

    // RSI calculation
    List<double> rsiValues = TechnicalAnalysis.calculateRSI(prices);
    double currentRSI = rsiValues.isNotEmpty ? rsiValues.last : 50.0;

    // Moving Averages
    List<double> sma20 = TechnicalAnalysis.calculateEMA(prices, period: 20);
    List<double> sma50 = TechnicalAnalysis.calculateEMA(prices, period: 50);
    double currentSMA20 = sma20.isNotEmpty ? sma20.last : 0.0;
    double currentSMA50 = sma50.isNotEmpty ? sma50.last : 0.0;

    // MACD
    MACDResult macd = TechnicalAnalysis.calculateMACD(prices);
    double currentMACD = macd.macdLine.isNotEmpty ? macd.macdLine.last : 0.0;
    double currentSignal =
        macd.signalLine.isNotEmpty ? macd.signalLine.last : 0.0;
    double currentHistogram =
        macd.histogram.isNotEmpty ? macd.histogram.last : 0.0;

    // Price change percentage
    double priceChangePercent = 0.0;
    if (candles.length > 10) {
      double startPrice = candles[candles.length - 11].close;
      double endPrice = candles.last.close;
      priceChangePercent = ((endPrice - startPrice) / startPrice) * 100;
    }

    // Volume analysis
    double avgVolume = 0.0;
    if (candles.length >= 7) {
      double volumeSum = 0.0;
      for (int i = candles.length - 7; i < candles.length; i++) {
        volumeSum += candles[i].volume;
      }
      avgVolume = volumeSum / 7;
    }
    double currentVolume = candles.isNotEmpty ? candles.last.volume : 0.0;
    double volumeChange = (currentVolume / (avgVolume > 0 ? avgVolume : 1)) - 1;

    // Support and resistance levels (simple calculation)
    List<double> sortedPrices = List.from(prices);
    sortedPrices.sort();
    double supportLevel = sortedPrices[sortedPrices.length ~/ 4];
    double resistanceLevel = sortedPrices[3 * sortedPrices.length ~/ 4];

    // Compile the data
    return {
      'symbol': symbol,
      'interval': interval,
      'lastUpdated': DateTime.now().toIso8601String(),
      'currentPrice': candles.last.close,
      'indicators': {
        'rsi': currentRSI.toStringAsFixed(2),
        'sma20': currentSMA20.toStringAsFixed(2),
        'sma50': currentSMA50.toStringAsFixed(2),
        'priceChange': priceChangePercent.toStringAsFixed(2),
        'macd': {
          'line': currentMACD.toStringAsFixed(4),
          'signal': currentSignal.toStringAsFixed(4),
          'histogram': currentHistogram.toStringAsFixed(4),
        },
        'volume': {
          'current': currentVolume.toInt(),
          'average': avgVolume.toInt(),
          'change': (volumeChange * 100).toStringAsFixed(2) + '%',
        },
        'levels': {
          'support': supportLevel.toStringAsFixed(2),
          'resistance': resistanceLevel.toStringAsFixed(2),
        },
      },
      'trend': _determineTrend(candles, currentRSI, currentSMA20, currentSMA50),
    };
  }

  /// Determines market trend based on price action and indicators
  String _determineTrend(
    List<Candle> candles,
    double rsi,
    double sma20,
    double sma50,
  ) {
    if (candles.length < 3) return 'neutral';

    double currentPrice = candles.last.close;

    // Check if price is above/below moving averages
    bool aboveSMA20 = currentPrice > sma20;
    bool aboveSMA50 = currentPrice > sma50;

    // Check recent price action for higher highs/lows
    bool higherHigh =
        candles[candles.length - 1].high > candles[candles.length - 2].high;
    bool higherLow =
        candles[candles.length - 1].low > candles[candles.length - 2].low;

    // Determine trend
    if ((aboveSMA20 && aboveSMA50) || (higherHigh && higherLow && rsi > 50)) {
      return 'bullish';
    } else if ((!aboveSMA20 && !aboveSMA50) ||
        (!higherHigh && !higherLow && rsi < 50)) {
      return 'bearish';
    }

    return 'neutral';
  }
}
