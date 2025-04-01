class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromBinanceData(List<dynamic> data) {
    return Candle(
      time: DateTime.fromMillisecondsSinceEpoch(data[0] as int),
      open: double.parse(data[1] as String),
      high: double.parse(data[2] as String),
      low: double.parse(data[3] as String),
      close: double.parse(data[4] as String),
      volume: double.parse(data[5] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.millisecondsSinceEpoch,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}

class Balance {
  final String asset;
  final double free;
  final double locked;

  Balance({required this.asset, required this.free, required this.locked});

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      asset: json['asset'] as String,
      free: double.parse(json['free'] as String),
      locked: double.parse(json['locked'] as String),
    );
  }
}

class AccountInfo {
  final List<Balance> balances;
  final bool canTrade;
  final bool canWithdraw;
  final bool canDeposit;

  AccountInfo({
    required this.balances,
    required this.canTrade,
    required this.canWithdraw,
    required this.canDeposit,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      balances:
          (json['balances'] as List<dynamic>)
              .map((e) => Balance.fromJson(e as Map<String, dynamic>))
              .toList(),
      canTrade: json['canTrade'] as bool,
      canWithdraw: json['canWithdraw'] as bool,
      canDeposit: json['canDeposit'] as bool,
    );
  }
}

class TickerPrice {
  final String symbol;
  final double price;

  TickerPrice({required this.symbol, required this.price});

  factory TickerPrice.fromJson(Map<String, dynamic> json) {
    return TickerPrice(
      symbol: json['symbol'] as String,
      price: double.parse(json['price'] as String),
    );
  }
}

class TickerStats {
  final String symbol;
  final double priceChange;
  final double priceChangePercent;
  final double lastPrice;
  final double volume;

  TickerStats({
    required this.symbol,
    required this.priceChange,
    required this.priceChangePercent,
    required this.lastPrice,
    required this.volume,
  });

  factory TickerStats.fromJson(Map<String, dynamic> json) {
    return TickerStats(
      symbol: json['symbol'] as String,
      priceChange: double.parse(json['priceChange'] as String),
      priceChangePercent: double.parse(json['priceChangePercent'] as String),
      lastPrice: double.parse(json['lastPrice'] as String),
      volume: double.parse(json['volume'] as String),
    );
  }
}
