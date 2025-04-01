import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/models/signal.dart';
import 'package:tradegasy/services/binance_service.dart';
import 'package:tradegasy/utils/technical_analysis.dart';

class SignalGenerator {
  BinanceService? _binanceService;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  // Initialize service safely
  Future<void> initialize() async {
    try {
      _binanceService = BinanceService();
      await _binanceService!.initialize();
      _initialized = true;
    } catch (e) {
      print('Error initializing signal generator: $e');
      throw Exception('Failed to initialize signal generator');
    }
  }

  // Generate trading signals based on technical analysis
  Future<List<TradingSignal>> generateSignals() async {
    if (!_initialized || _binanceService == null) {
      throw Exception('Signal generator not initialized');
    }

    final List<TradingSignal> signals = [];

    try {
      final List<String> tradingPairs =
          await _binanceService!.getTradingPairs();

      // Focus on top trading pairs
      final topPairs = tradingPairs.take(10).toList();

      for (final pair in topPairs) {
        try {
          final candles = await _binanceService!.getKlines(
            symbol: pair,
            interval: '1h',
            limit: 100,
          );

          if (candles.length < 50) continue;

          final signalResult = _analyzeForSignal(pair, candles);
          if (signalResult != null) {
            signals.add(signalResult);
          }
        } catch (e) {
          print('Error analyzing $pair: $e');
        }
      }
    } catch (e) {
      print('Error generating signals: $e');
    }

    return signals;
  }

  TradingSignal? _analyzeForSignal(String pair, List<Candle> candles) {
    // Extract close prices for technical indicators
    final List<double> closePrices = candles.map((c) => c.close).toList();
    try {
      // Calculate technical indicators with our custom implementation
      // to avoid compatibility issues with the package
      final rsi = TechnicalAnalysis.calculateRSI(closePrices, period: 14);
      final macd = TechnicalAnalysis.calculateMACD(
        closePrices,
        fastPeriod: 12,
        slowPeriod: 26,
        signalPeriod: 9,
      );

      final ema20 = TechnicalAnalysis.calculateEMA(closePrices, period: 20);
      final ema50 = TechnicalAnalysis.calculateEMA(closePrices, period: 50);
      bool buySignal = false;
      bool sellSignal = false;

      // RSI oversold and MACD crossover
      if (rsi.last < 30 &&
          macd.histogram.last > 0 &&
          macd.histogram[macd.histogram.length - 2] < 0) {
        buySignal = true;
      }

      // RSI overbought and MACD crossover
      if (rsi.last > 70 &&
          macd.histogram.last < 0 &&
          macd.histogram[macd.histogram.length - 2] > 0) {
        sellSignal = true;
      }

      // EMA crossover
      if (ema20.last > ema50.last &&
          ema20[ema20.length - 2] < ema50[ema50.length - 2]) {
        buySignal = true;
      }

      // EMA crossover down
      if (ema20.last < ema50.last &&
          ema20[ema20.length - 2] > ema50[ema50.length - 2]) {
        sellSignal = true;
      }

      if (buySignal || sellSignal) {
        final currentPrice = candles.last.close;
        final signalType = buySignal ? SignalType.buy : SignalType.sell;

        // Calculate target prices
        double takeProfit;
        double stopLoss;

        if (signalType == SignalType.buy) {
          // For buy, set 2% take profit and 1% stop loss
          takeProfit = currentPrice * 1.02;
          stopLoss = currentPrice * 0.99;
        } else {
          // For sell, set 2% take profit and 1% stop loss in the opposite direction
          takeProfit = currentPrice * 0.98;
          stopLoss = currentPrice * 1.01;
        }

        // Generate analysis notes
        String notes = 'Signal based on ';
        if (rsi.last < 30 || rsi.last > 70) {
          notes += 'RSI ${rsi.last.toStringAsFixed(2)} ';
        }
        if (macd.histogram.last * macd.histogram[macd.histogram.length - 2] <
            0) {
          notes += 'MACD crossover ';
        }
        if ((ema20.last > ema50.last &&
                ema20[ema20.length - 2] < ema50[ema50.length - 2]) ||
            (ema20.last < ema50.last &&
                ema20[ema20.length - 2] > ema50[ema50.length - 2])) {
          notes += 'EMA crossover ';
        }

        return TradingSignal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          pair: pair,
          type: signalType,
          entryPrice: currentPrice,
          takeProfit: takeProfit,
          stopLoss: stopLoss,
          timestamp: DateTime.now(),
          status: SignalStatus.pending,
          notes: notes,
        );
      }
    } catch (e) {
      print('Technical analysis error for $pair: $e');
    }

    return null;
  }
}
