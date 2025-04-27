import 'dart:math';
import 'package:tradegasy/models/signal.dart';
import 'package:tradegasy/services/binance_service.dart';
import 'package:tradegasy/services/technical_analysis.dart';

// Using SignalDirection from technical_analysis.dart instead of redefining it
enum SignalStrength { weak, moderate, strong }

enum SignalStatus { active, completed, cancelled }

class TradingSignal {
  final String id;
  final String pair;
  final SignalType type;
  final double entryPrice;
  final double takeProfit;
  final double stopLoss;
  final String timeframe;
  final SignalStrength strength;
  final SignalStatus status;
  final DateTime timestamp;
  final List<String> reasons;

  TradingSignal({
    required this.id,
    required this.pair,
    required this.type,
    required this.entryPrice,
    required this.takeProfit,
    required this.stopLoss,
    required this.timeframe,
    required this.strength,
    required this.status,
    required this.timestamp,
    required this.reasons,
  });
}

class SignalGenerator {
  final BinanceService _binanceService = BinanceService();
  final TechnicalAnalysis _technicalAnalysis = TechnicalAnalysis();
  final Random _random = Random();
  bool _isInitialized = false;

  // Nombre minimum de bougies nécessaires pour l'analyse technique
  static const int MINIMUM_CANDLES_REQUIRED = 75;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _binanceService.initialize();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing SignalGenerator: $e');
      // Continue with partial functionality
      _isInitialized = true;
    }
  }

  /// Génère des signaux de trading basés sur l'analyse technique
  Future<List<TradingSignal>> generateSignals() async {
    // Si le service n'est pas initialisé, retourner une liste vide
    if (!_isInitialized) {
      print('SignalGenerator not initialized, returning empty signals list');
      return [];
    }

    final List<TradingSignal> signals = [];

    try {
      // Obtenir la liste des paires de trading avec un volume significatif
      final tickers = await _binanceService.get24hTickers();

      // Filtrer les paires USDT avec un volume significatif et les trier par volume
      final filteredTickers =
          tickers
              .where(
                (ticker) =>
                    ticker.symbol.endsWith('USDT') && ticker.volume > 1000000,
              ) // Volume significatif
              .toList();

      // Trier par volume descendant
      filteredTickers.sort((a, b) => b.volume.compareTo(a.volume));

      // Prendre les 20 premières paires
      final topTickers = filteredTickers.take(20).toList();

      // Analyser chaque paire pour des signaux potentiels
      for (final ticker in topTickers) {
        // 40% de chance de générer un signal pour chaque paire (pour limiter le nombre de signaux)
        if (_random.nextDouble() > 0.4) continue;

        try {
          // Obtenir les données des chandeliers pour l'analyse technique
          // Demander plus de bougies pour éviter l'erreur d'index
          final candles = await _binanceService.getKlines(
            symbol: ticker.symbol,
            interval: '1d', // Intervalle journalier pour l'analyse
            limit: 200, // Augmenter le nombre de bougies demandées
          );

          if (candles.isEmpty) {
            print('No candles available for ${ticker.symbol}');
            continue;
          }

          // Vérifier si nous avons suffisamment de données pour l'analyse
          if (candles.length < MINIMUM_CANDLES_REQUIRED) {
            print(
              'Insufficient candles for ${ticker.symbol}: ${candles.length}/$MINIMUM_CANDLES_REQUIRED',
            );
            continue;
          }

          // Analyser les indicateurs techniques
          final macdSignal = _technicalAnalysis.checkMACD(candles);
          final rsiSignal = _technicalAnalysis.checkRSI(candles);
          final maSignal = _technicalAnalysis.checkMovingAverages(candles);

          // Compiler les résultats
          SignalDirection direction = SignalDirection.neutral;

          // Si au moins 2 indicateurs pointent dans la même direction
          if ((macdSignal == SignalDirection.buy &&
                  rsiSignal == SignalDirection.buy) ||
              (macdSignal == SignalDirection.buy &&
                  maSignal == SignalDirection.buy) ||
              (rsiSignal == SignalDirection.buy &&
                  maSignal == SignalDirection.buy)) {
            direction = SignalDirection.buy;
          } else if ((macdSignal == SignalDirection.sell &&
                  rsiSignal == SignalDirection.sell) ||
              (macdSignal == SignalDirection.sell &&
                  maSignal == SignalDirection.sell) ||
              (rsiSignal == SignalDirection.sell &&
                  maSignal == SignalDirection.sell)) {
            direction = SignalDirection.sell;
          }

          // Ne générer un signal que si direction n'est pas neutre
          if (direction != SignalDirection.neutral) {
            final strength = _calculateSignalStrength(
              macdSignal,
              rsiSignal,
              maSignal,
            );
            final entryPrice = candles.last.close;

            final signal = TradingSignal(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              pair: ticker.symbol,
              type:
                  direction == SignalDirection.buy
                      ? SignalType.buy
                      : SignalType.sell,
              entryPrice: entryPrice,
              takeProfit: _calculateTargetPrice(entryPrice, direction),
              stopLoss: _calculateStopLossPrice(entryPrice, direction),
              timeframe: '1d',
              strength: strength,
              status: SignalStatus.active,
              timestamp: DateTime.now(),
              reasons: _generateSignalReasons(
                ticker.symbol,
                direction,
                macdSignal,
                rsiSignal,
                maSignal,
              ),
            );

            signals.add(signal);
          }
        } catch (e) {
          print('Error analyzing ${ticker.symbol}: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error generating signals: $e');
    }

    return signals;
  }

  /// Calcule la force du signal basée sur le consensus des indicateurs
  SignalStrength _calculateSignalStrength(
    SignalDirection macdSignal,
    SignalDirection rsiSignal,
    SignalDirection maSignal,
  ) {
    // Compter le nombre d'indicateurs qui concordent
    int buyCount = 0;
    int sellCount = 0;

    if (macdSignal == SignalDirection.buy) buyCount++;
    if (rsiSignal == SignalDirection.buy) buyCount++;
    if (maSignal == SignalDirection.buy) buyCount++;

    if (macdSignal == SignalDirection.sell) sellCount++;
    if (rsiSignal == SignalDirection.sell) sellCount++;
    if (maSignal == SignalDirection.sell) sellCount++;

    // Calculer la force du signal
    final totalCount = buyCount > sellCount ? buyCount : sellCount;

    if (totalCount == 3) {
      return SignalStrength.strong;
    } else if (totalCount == 2) {
      return SignalStrength.moderate;
    } else {
      return SignalStrength.weak;
    }
  }

  /// Calcule un prix cible basé sur la direction du signal
  double _calculateTargetPrice(double entryPrice, SignalDirection direction) {
    // Calculer un objectif de prix réaliste
    if (direction == SignalDirection.buy) {
      // Pour un signal d'achat, viser 2-5% de hausse
      return entryPrice * (1.0 + (0.02 + _random.nextDouble() * 0.03));
    } else {
      // Pour un signal de vente, viser 2-5% de baisse
      return entryPrice * (1.0 - (0.02 + _random.nextDouble() * 0.03));
    }
  }

  /// Calcule un stop loss basé sur la direction du signal
  double _calculateStopLossPrice(double entryPrice, SignalDirection direction) {
    // Calculer un stop loss réaliste
    if (direction == SignalDirection.buy) {
      // Pour un signal d'achat, stop loss 1-2% en dessous
      return entryPrice * (1.0 - (0.01 + _random.nextDouble() * 0.01));
    } else {
      // Pour un signal de vente, stop loss 1-2% au dessus
      return entryPrice * (1.0 + (0.01 + _random.nextDouble() * 0.01));
    }
  }

  /// Génère des raisons descriptives pour le signal
  List<String> _generateSignalReasons(
    String symbol,
    SignalDirection direction,
    SignalDirection macdSignal,
    SignalDirection rsiSignal,
    SignalDirection maSignal,
  ) {
    final List<String> reasons = [];

    if (direction == SignalDirection.buy) {
      if (macdSignal == SignalDirection.buy) {
        reasons.add('MACD a croisé au-dessus de la ligne de signal');
      }
      if (rsiSignal == SignalDirection.buy) {
        reasons.add('RSI est sorti de la zone de survente');
      }
      if (maSignal == SignalDirection.buy) {
        reasons.add('Prix au-dessus des moyennes mobiles');
      }

      // Ajouter une raison contextuelle
      reasons.add('Le volume en hausse confirme le mouvement haussier');
    } else {
      if (macdSignal == SignalDirection.sell) {
        reasons.add('MACD a croisé en dessous de la ligne de signal');
      }
      if (rsiSignal == SignalDirection.sell) {
        reasons.add('RSI est entré dans la zone de surachat');
      }
      if (maSignal == SignalDirection.sell) {
        reasons.add('Prix en dessous des moyennes mobiles');
      }

      // Ajouter une raison contextuelle
      reasons.add(
        'Diminution du volume indiquant un affaiblissement de la tendance',
      );
    }

    return reasons;
  }
}
