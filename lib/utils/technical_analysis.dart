/// MACD (Moving Average Convergence Divergence) result
class MACDResult {
  final List<double> macdLine;
  final List<double> signalLine;
  final List<double> histogram;

  MACDResult({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

/// A simple utility class for technical analysis indicators
class TechnicalAnalysis {
  /// Calculate Relative Strength Index
  static List<double> calculateRSI(List<double> prices, {int period = 14}) {
    if (prices.length <= period) {
      return List.filled(prices.length, 50.0);
    }

    List<double> rsi = List.filled(prices.length, 0.0);
    List<double> gains = List.filled(prices.length, 0.0);
    List<double> losses = List.filled(prices.length, 0.0);

    // Calculate gains and losses
    for (int i = 1; i < prices.length; i++) {
      double diff = prices[i] - prices[i - 1];
      if (diff > 0) {
        gains[i] = diff;
      } else {
        losses[i] = diff.abs();
      }
    }

    // Calculate first average gain and loss
    double avgGain = 0.0;
    double avgLoss = 0.0;
    for (int i = 1; i <= period; i++) {
      avgGain += gains[i];
      avgLoss += losses[i];
    }
    avgGain /= period;
    avgLoss /= period;

    // First RSI value
    if (avgLoss == 0) {
      rsi[period] = 100.0;
    } else {
      double rs = avgGain / avgLoss;
      rsi[period] = 100.0 - (100.0 / (1.0 + rs));
    }

    // Calculate RSI for remaining points
    for (int i = period + 1; i < prices.length; i++) {
      avgGain = ((avgGain * (period - 1)) + gains[i]) / period;
      avgLoss = ((avgLoss * (period - 1)) + losses[i]) / period;

      if (avgLoss == 0) {
        rsi[i] = 100.0;
      } else {
        double rs = avgGain / avgLoss;
        rsi[i] = 100.0 - (100.0 / (1.0 + rs));
      }
    }

    return rsi;
  }

  /// Calculate Exponential Moving Average
  static List<double> calculateEMA(List<double> prices, {int period = 20}) {
    List<double> ema = List.filled(prices.length, 0.0);
    if (prices.length <= period) {
      return List.from(prices);
    }

    // Calculate SMA for the first point
    double sum = 0.0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    ema[period - 1] = sum / period;

    // Calculate multiplier
    double multiplier = 2.0 / (period + 1);

    // Calculate EMA for remaining points
    for (int i = period; i < prices.length; i++) {
      ema[i] = (prices[i] - ema[i - 1]) * multiplier + ema[i - 1];
    }

    return ema;
  }

  /// Calculate MACD
  static MACDResult calculateMACD(
    List<double> prices, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    List<double> macdLine = List.filled(prices.length, 0.0);
    List<double> signalLine = List.filled(prices.length, 0.0);
    List<double> histogram = List.filled(prices.length, 0.0);

    // Calculate EMAs
    List<double> fastEMA = calculateEMA(prices, period: fastPeriod);
    List<double> slowEMA = calculateEMA(prices, period: slowPeriod);

    // Calculate MACD line
    for (int i = 0; i < prices.length; i++) {
      if (i >= slowPeriod - 1) {
        macdLine[i] = fastEMA[i] - slowEMA[i];
      }
    }

    // Calculate signal line (EMA of MACD line)
    List<double> validMacd = macdLine.sublist(slowPeriod - 1);
    List<double> emaOfMacd = calculateEMA(validMacd, period: signalPeriod);

    // Populate signal line and histogram
    for (int i = 0; i < emaOfMacd.length; i++) {
      int actualIndex = i + slowPeriod - 1;
      signalLine[actualIndex] = emaOfMacd[i];
      histogram[actualIndex] = macdLine[actualIndex] - signalLine[actualIndex];
    }

    return MACDResult(
      macdLine: macdLine,
      signalLine: signalLine,
      histogram: histogram,
    );
  }
}
