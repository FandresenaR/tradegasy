import 'package:tradegasy/models/signal.dart';

class SignalService {
  static List<TradingSignal> getMockSignals() {
    return [
      TradingSignal(
        id: '1',
        pair: 'EUR/USD',
        type: SignalType.buy,
        entryPrice: 1.0865,
        takeProfit: 1.0920,
        stopLoss: 1.0820,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        status: SignalStatus.active,
        notes: 'Strong momentum with bullish trend',
      ),
      TradingSignal(
        id: '2',
        pair: 'BTC/USD',
        type: SignalType.sell,
        entryPrice: 35750.45,
        takeProfit: 35200.00,
        stopLoss: 36100.00,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        status: SignalStatus.closed,
        closingPrice: 35180.20,
        profit: 570.25,
        notes: 'Resistance zone rejected price',
      ),
      TradingSignal(
        id: '3',
        pair: 'GBP/JPY',
        type: SignalType.buy,
        entryPrice: 186.23,
        takeProfit: 187.50,
        stopLoss: 185.70,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        status: SignalStatus.pending,
        notes: 'Waiting for confirmation at key support level',
      ),
      TradingSignal(
        id: '4',
        pair: 'USD/CAD',
        type: SignalType.sell,
        entryPrice: 1.3720,
        takeProfit: 1.3650,
        stopLoss: 1.3770,
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        status: SignalStatus.active,
        notes: 'Bearish trend continuation pattern',
      ),
    ];
  }
}
