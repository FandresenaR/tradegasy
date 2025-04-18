import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart' as candlesticks;
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/services/binance_service.dart';
import 'package:tradegasy/services/openrouter_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late BinanceService _binanceService;
  late OpenRouterService _openRouterService;
  bool _servicesInitialized = false;
  List<TickerStats>? _tickers;
  List<Candle>? _candles;
  String? _selectedPair;
  String _selectedInterval = '1h';
  bool _isLoading = true;

  // Chat state
  final List<String> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isAnalyzing = false;

  // Expanded interval options
  final Map<String, String> _intervalMap = {
    '1m': '1 minute',
    '5m': '5 minutes',
    '15m': '15 minutes',
    '30m': '30 minutes',
    '1h': '1 hour',
    '4h': '4 hours',
    '1d': '1 day',
    '7d': '7 days',
    '1M': '1 month',
    '6M': '6 months',
    '1y': '1 year',
    '5y': '5 years',
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      _binanceService = BinanceService();
      _openRouterService = OpenRouterService();

      await Future.wait([
        _binanceService.initialize(),
        _openRouterService.initialize(),
      ]);

      setState(() {
        _servicesInitialized = true;
      });

      _loadData();
    } catch (e) {
      print('Error initializing services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing services: $e')),
      );
    }
  }

  Future<void> _loadData() async {
    if (!_servicesInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for services to initialize')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tickers = await _binanceService.get24hTickers();
      final filteredTickers =
          tickers
              .where(
                (ticker) =>
                    ticker.symbol.endsWith('USDT') ||
                    ticker.symbol.endsWith('BUSD'),
              )
              .toList();

      filteredTickers.sort((a, b) => b.volume.compareTo(a.volume));

      final tickersToShow = filteredTickers.take(30).toList();

      String selectedPair = 'BTCUSDT';

      if (tickersToShow.any((t) => t.symbol == 'BTCUSDT')) {
        selectedPair = 'BTCUSDT';
      } else if (tickersToShow.isNotEmpty) {
        selectedPair = tickersToShow.first.symbol;
      }

      setState(() {
        _tickers = tickersToShow;
        _selectedPair = selectedPair;
      });

      await _loadCandles();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCandles() async {
    if (_selectedPair == null) return;

    try {
      final candlesData = await _binanceService.getKlines(
        symbol: _selectedPair!,
        interval: _selectedInterval,
        limit: 100,
      );

      setState(() {
        _candles = candlesData;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading candles: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Data'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    _buildPairSelector(),
                    _buildIntervalSelector(),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: Theme.of(context).colorScheme.primary,
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.candlestick_chart),
                                  text: "Chart",
                                ),
                                Tab(
                                  icon: Icon(Icons.smart_toy),
                                  text: "AI Analysis",
                                ),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildCandlestickChart(),
                                  _buildAIAnalysisSection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPairSelector() {
    if (_tickers == null || _tickers!.isEmpty || _selectedPair == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No trading pairs available')),
      );
    }

    bool pairExists = _tickers!.any((ticker) => ticker.symbol == _selectedPair);
    if (!pairExists && _tickers!.isNotEmpty) {
      _selectedPair = _tickers![0].symbol;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedPair,
        isExpanded: true,
        underline: const SizedBox(),
        items:
            _tickers!.map((ticker) {
              return DropdownMenuItem<String>(
                value: ticker.symbol,
                child: Row(
                  children: [
                    Text(ticker.symbol),
                    const Spacer(),
                    Text(
                      '${ticker.priceChangePercent > 0 ? '+' : ''}${ticker.priceChangePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color:
                            ticker.priceChangePercent > 0
                                ? Colors.green
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedPair = value;
            });
            _loadCandles();
          }
        },
      ),
    );
  }

  Widget _buildIntervalSelector() {
    final intervals = [
      '1m',
      '5m',
      '15m',
      '30m',
      '1h',
      '4h',
      '1d',
      '7d',
      '1M',
      '6M',
      '1y',
      '5y',
    ];

    final theme = Theme.of(context);

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: intervals.length,
        itemBuilder: (context, index) {
          final interval = intervals[index];
          final isSelected = interval == _selectedInterval;

          final text =
              MediaQuery.of(context).size.width < 600
                  ? interval
                  : (_intervalMap[interval] ?? interval);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedInterval = interval;
              });
              _loadCandles();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  color:
                      isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandlestickChart() {
    if (_candles == null || _selectedPair == null) {
      return const Center(child: Text('No chart data available'));
    }

    final formattedCandles =
        _candles!.map((candle) {
          return candlesticks.Candle(
            open: candle.open,
            high: candle.high,
            low: candle.low,
            close: candle.close,
            volume: candle.volume,
            date: candle.time,
          );
        }).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: candlesticks.Candlesticks(candles: formattedCandles),
    );
  }

  Widget _buildAIAnalysisSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child:
                _chatHistory.isEmpty
                    ? _buildEmptyAnalysisState()
                    : _buildChatMessages(),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalysisState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask DeepSeek R1 about the current chart',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Example: "What\'s the trend for $_selectedPair?" or "Identify support and resistance levels"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    final ScrollController scrollController = ScrollController(
      initialScrollOffset: 999999,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: _chatHistory.length,
      shrinkWrap: false,
      key: Key('chat_messages_${_chatHistory.length}'),
      controller: scrollController,
      itemBuilder: (context, index) {
        final isUser = index % 2 == 0;
        final message = _chatHistory[index];

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isUser
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                      : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
              border:
                  !isUser
                      ? Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                      )
                      : null,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                SelectableText(
                  message,
                  style: TextStyle(
                    color:
                        isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                  textAlign: isUser ? TextAlign.right : TextAlign.left,
                ),
                if (!isUser) ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          _copyToClipboard(message);
                        },
                        child: Text(
                          "Copy",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Ask about this chart...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon:
                  _isAnalyzing
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
              onPressed:
                  _isAnalyzing
                      ? null
                      : () => _sendMessage(_chatController.text),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final currentPair = _selectedPair;
    final currentInterval = _selectedInterval;

    setState(() {
      _chatHistory.add(message);
      _isAnalyzing = true;
      _chatController.clear();
    });

    if (_candles == null || _selectedPair == null) {
      setState(() {
        _chatHistory.add(
          "I can't analyze the chart because no data is available. Please try refreshing the data.",
        );
        _isAnalyzing = false;
      });
      return;
    }

    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _chatHistory.add(
            "API key missing. Please set up a valid OpenRouter API key in your .env file.",
          );
          _isAnalyzing = false;
        });
        return;
      }

      final response = await _openRouterService.generateMarketAnalysis(
        symbol: currentPair!,
        interval: currentInterval,
        candles: _candles!,
        conversationHistory: _chatHistory,
        userQuestion: message,
      );

      setState(() {
        _chatHistory.add(response);
        _isAnalyzing = false;
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add(
          "Error: $e. Please check your API configuration and try again.",
        );
        _isAnalyzing = false;
      });
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analysis copied to clipboard')));
    });
  }
}
