enum SignalType { buy, sell }

enum SignalStatus { active, closed, pending }

class TradingSignal {
  final String id;
  final String pair;
  final SignalType type;
  final double entryPrice;
  final double takeProfit;
  final double stopLoss;
  final DateTime timestamp;
  final SignalStatus status;
  final double? closingPrice;
  final double? profit;
  final String? notes;

  TradingSignal({
    required this.id,
    required this.pair,
    required this.type,
    required this.entryPrice,
    required this.takeProfit,
    required this.stopLoss,
    required this.timestamp,
    required this.status,
    this.closingPrice,
    this.profit,
    this.notes,
  });
}
