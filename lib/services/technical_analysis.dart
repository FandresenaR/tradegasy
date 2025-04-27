import 'package:tradegasy/models/binance_models.dart';

/// Represents the direction of a trading signal
enum SignalDirection { buy, sell, neutral }

class TechnicalAnalysis {
  /// Vérifie l'indicateur MACD pour détecter des signaux
  SignalDirection checkMACD(List<Candle> candles) {
    // Paramètres MACD standards
    const fastPeriod = 12;
    const slowPeriod = 26;
    const signalPeriod = 9;

    // Vérifier si nous avons suffisamment de données pour calculer le MACD
    if (candles.length < slowPeriod + signalPeriod) {
      print(
        'Insufficient data for MACD: ${candles.length} candles, need ${slowPeriod + signalPeriod}',
      );
      return SignalDirection.neutral;
    }

    try {
      // Calculer l'EMA rapide et lente
      final fastEMA = _calculateEMA(candles, fastPeriod);
      final slowEMA = _calculateEMA(candles, slowPeriod);

      if (fastEMA.isEmpty || slowEMA.isEmpty) {
        return SignalDirection.neutral;
      }

      // Calculer la ligne MACD (différence entre EMA rapide et lente)
      final macdLine = List<double>.generate(
        candles.length,
        (i) =>
            i < fastPeriod - 1 || i >= fastEMA.length || i >= slowEMA.length
                ? 0
                : fastEMA[i] - slowEMA[i],
      );

      // Calculer la ligne de signal (EMA de la ligne MACD)
      final signalLine = _calculateEMAFromValues(macdLine, signalPeriod);

      // Vérifier les croisements récents
      if (macdLine.length < 2 || signalLine.length < 2) {
        return SignalDirection.neutral;
      }

      // S'assurer que nous accédons à des indices valides
      final lastIndex = signalLine.length - 1;
      final previousIndex = lastIndex - 1;

      if (previousIndex < 0 ||
          lastIndex >= macdLine.length ||
          previousIndex >= macdLine.length) {
        return SignalDirection.neutral;
      }

      // Si MACD croise au-dessus de la ligne de signal -> Signal d'achat
      if (macdLine[previousIndex] < signalLine[previousIndex] &&
          macdLine[lastIndex] > signalLine[lastIndex]) {
        return SignalDirection.buy;
      }

      // Si MACD croise en dessous de la ligne de signal -> Signal de vente
      if (macdLine[previousIndex] > signalLine[previousIndex] &&
          macdLine[lastIndex] < signalLine[lastIndex]) {
        return SignalDirection.sell;
      }

      return SignalDirection.neutral;
    } catch (e) {
      print('Error calculating MACD: $e');
      return SignalDirection.neutral;
    }
  }

  /// Vérifie l'indicateur RSI pour détecter des signaux
  SignalDirection checkRSI(List<Candle> candles) {
    // Paramètres RSI standards
    const period = 14;
    const overboughtThreshold = 70;
    const oversoldThreshold = 30;

    // Vérifier si nous avons suffisamment de données
    if (candles.length < period + 1) {
      print(
        'Insufficient data for RSI: ${candles.length} candles, need ${period + 1}',
      );
      return SignalDirection.neutral;
    }

    try {
      // Calculer les changements de prix
      final priceChanges = List<double>.generate(
        candles.length - 1,
        (i) => candles[i + 1].close - candles[i].close,
      );

      // Calculer les gains et pertes moyens
      double avgGain = 0;
      double avgLoss = 0;

      // Première période
      for (int i = 0; i < period && i < priceChanges.length; i++) {
        if (priceChanges[i] > 0) {
          avgGain += priceChanges[i];
        } else {
          avgLoss += priceChanges[i].abs();
        }
      }

      avgGain /= period;
      avgLoss /= period;

      // Calculer le RSI initial
      double rs =
          avgGain /
          (avgLoss > 0 ? avgLoss : 0.001); // Éviter la division par zéro
      double rsi = 100 - (100 / (1 + rs));

      // Calculer le RSI pour les périodes restantes
      List<double> rsiValues = [rsi];

      for (int i = period; i < priceChanges.length; i++) {
        final double gain = priceChanges[i] > 0 ? priceChanges[i] : 0;
        final double loss = priceChanges[i] < 0 ? priceChanges[i].abs() : 0;

        // Utiliser la formule de lissage exponentiel
        avgGain = (avgGain * (period - 1) + gain) / period;
        avgLoss = (avgLoss * (period - 1) + loss) / period;

        rs = avgGain / (avgLoss > 0 ? avgLoss : 0.001);
        rsi = 100 - (100 / (1 + rs));

        rsiValues.add(rsi);
      }

      // Vérifier les signaux basés sur RSI
      if (rsiValues.isEmpty) {
        return SignalDirection.neutral;
      }

      final currentRSI = rsiValues.last;

      // RSI sous le seuil de survente, signal d'achat potentiel
      if (currentRSI < oversoldThreshold) {
        return SignalDirection.buy;
      }

      // RSI au-dessus du seuil de surachat, signal de vente potentiel
      if (currentRSI > overboughtThreshold) {
        return SignalDirection.sell;
      }

      return SignalDirection.neutral;
    } catch (e) {
      print('Error calculating RSI: $e');
      return SignalDirection.neutral;
    }
  }

  /// Vérifie les moyennes mobiles pour détecter des signaux
  SignalDirection checkMovingAverages(List<Candle> candles) {
    // Paramètres des moyennes mobiles
    const shortPeriod = 10;
    const longPeriod = 50;

    // Vérifier si nous avons suffisamment de données
    if (candles.length < longPeriod) {
      print(
        'Insufficient data for Moving Averages: ${candles.length} candles, need $longPeriod',
      );
      return SignalDirection.neutral;
    }

    try {
      // Calculer les moyennes mobiles
      final shortMA = _calculateSMA(candles, shortPeriod);
      final longMA = _calculateSMA(candles, longPeriod);

      // Vérifier si nous avons réussi à calculer les moyennes mobiles
      if (shortMA.length < 2 || longMA.length < 2) {
        return SignalDirection.neutral;
      }

      // S'assurer que les indices sont valides
      final lastShortIndex = shortMA.length - 1;
      final prevShortIndex = lastShortIndex - 1;
      final lastLongIndex = longMA.length - 1;
      final prevLongIndex = lastLongIndex - 1;

      // Vérifier que tous les indices sont valides
      if (prevShortIndex < 0 ||
          prevLongIndex < 0 ||
          lastShortIndex >= shortMA.length ||
          lastLongIndex >= longMA.length) {
        return SignalDirection.neutral;
      }

      // Si la MA courte croise au-dessus de la MA longue -> Signal d'achat
      if (shortMA[prevShortIndex] < longMA[prevLongIndex] &&
          shortMA[lastShortIndex] > longMA[lastLongIndex]) {
        return SignalDirection.buy;
      }

      // Si la MA courte croise en dessous de la MA longue -> Signal de vente
      if (shortMA[prevShortIndex] > longMA[prevLongIndex] &&
          shortMA[lastShortIndex] < longMA[lastLongIndex]) {
        return SignalDirection.sell;
      }

      // Alternative: vérifier le momentum basé sur la position du prix par rapport aux moyennes
      if (candles.isNotEmpty && shortMA.isNotEmpty && longMA.isNotEmpty) {
        final currentPrice = candles.last.close;

        // Si le prix est bien au-dessus des deux moyennes mobiles -> Tendance haussière
        if (currentPrice > shortMA.last * 1.02 &&
            currentPrice > longMA.last * 1.05) {
          return SignalDirection.buy;
        }

        // Si le prix est bien en dessous des deux moyennes mobiles -> Tendance baissière
        if (currentPrice < shortMA.last * 0.98 &&
            currentPrice < longMA.last * 0.95) {
          return SignalDirection.sell;
        }
      }

      return SignalDirection.neutral;
    } catch (e) {
      print('Error calculating Moving Averages: $e');
      return SignalDirection.neutral;
    }
  }

  /// Calcule la moyenne mobile simple (SMA)
  List<double> _calculateSMA(List<Candle> candles, int period) {
    if (candles.length < period) {
      return [];
    }

    try {
      List<double> sma = [];

      for (int i = period - 1; i < candles.length; i++) {
        double sum = 0;
        for (
          int j = 0;
          j < period && (i - j) >= 0 && (i - j) < candles.length;
          j++
        ) {
          sum += candles[i - j].close;
        }
        sma.add(sum / period);
      }

      return sma;
    } catch (e) {
      print('Error in _calculateSMA: $e');
      return [];
    }
  }

  /// Calcule la moyenne mobile exponentielle (EMA)
  List<double> _calculateEMA(List<Candle> candles, int period) {
    if (candles.length < period) {
      return [];
    }

    try {
      // Calculer le multiplicateur
      final multiplier = 2.0 / (period + 1);

      // Commencer avec une SMA pour la première valeur
      double sum = 0;
      for (int i = 0; i < period && i < candles.length; i++) {
        sum += candles[i].close;
      }

      List<double> ema = [sum / period];

      // Calculer l'EMA pour les valeurs restantes
      for (int i = period; i < candles.length; i++) {
        ema.add((candles[i].close - ema.last) * multiplier + ema.last);
      }

      return ema;
    } catch (e) {
      print('Error in _calculateEMA: $e');
      return [];
    }
  }

  /// Calcule l'EMA à partir d'une liste de valeurs
  List<double> _calculateEMAFromValues(List<double> values, int period) {
    if (values.length < period) {
      return [];
    }

    try {
      // Calculer le multiplicateur
      final multiplier = 2.0 / (period + 1);

      // Commencer avec une SMA pour la première valeur
      double sum = 0;
      for (int i = 0; i < period && i < values.length; i++) {
        sum += values[i];
      }

      List<double> ema = [sum / period];

      // Calculer l'EMA pour les valeurs restantes
      for (int i = period; i < values.length; i++) {
        ema.add((values[i] - ema.last) * multiplier + ema.last);
      }

      return ema;
    } catch (e) {
      print('Error in _calculateEMAFromValues: $e');
      return [];
    }
  }
}
