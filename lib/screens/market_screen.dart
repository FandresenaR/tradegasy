import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart' as candlesticks;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tradegasy/models/binance_models.dart';
import 'package:tradegasy/services/binance_service.dart';
import 'package:tradegasy/services/openrouter_service.dart';
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
    '1w': '1 week',
    '1M': '1 month',
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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.marketScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: localizations.refresh,
          ),
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
                              tabs: [
                                Tab(
                                  icon: const Icon(Icons.candlestick_chart),
                                  text: localizations.chart,
                                ),
                                Tab(
                                  icon: const Icon(Icons.smart_toy),
                                  text: localizations.aiAnalysis,
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
    final localizations = AppLocalizations.of(context)!;

    if (_tickers == null || _tickers!.isEmpty || _selectedPair == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text(localizations.noTradingPairs)),
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
              // Fonction pour
              String friendlyName = _getFriendlyName(ticker.symbol);

              return DropdownMenuItem<String>(
                value: ticker.symbol,
                child: Row(
                  children: [
                    // Ajouter une icône représentative
                    _getAssetIcon(ticker.symbol),
                    const SizedBox(width: 8),
                    // Afficher le nom convivial et le symbole technique
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            friendlyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ticker.symbol,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  // Obtenir une icône représentative pour chaque type d'actif
  Widget _getAssetIcon(String symbol) {
    IconData iconData;
    Color iconColor;

    if (symbol.startsWith('BTC')) {
      iconData = Icons.currency_bitcoin;
      iconColor = Colors.orange;
    } else if (symbol.startsWith('ETH')) {
      iconData = Icons.diamond_outlined;
      iconColor = Colors.purple;
    } else if (symbol.contains('OIL') ||
        symbol.contains('XTI') ||
        symbol.contains('BRENT')) {
      iconData = Icons.oil_barrel;
      iconColor = Colors.black;
    } else if (symbol.contains('GOLD') || symbol.contains('XAU')) {
      iconData = Icons.monetization_on;
      iconColor = Colors.amber;
    } else if (symbol.contains('SILVER') || symbol.contains('XAG')) {
      iconData = Icons.brightness_6;
      iconColor = Colors.grey;
    } else if (symbol.contains('EUR') ||
        symbol.contains('USD') ||
        symbol.contains('JPY') ||
        symbol.contains('GBP')) {
      iconData = Icons.attach_money;
      iconColor = Colors.green;
    } else if (symbol.contains('SOL')) {
      iconData = Icons.solar_power;
      iconColor = Colors.purpleAccent;
    } else if (symbol.contains('DOT')) {
      iconData = Icons.blur_circular;
      iconColor = Colors.pinkAccent;
    } else if (symbol.contains('DOGE') ||
        symbol.contains('SHIB') ||
        symbol.contains('PEPE')) {
      iconData = Icons.pets;
      iconColor = Colors.amber;
    } else {
      iconData = Icons.bar_chart;
      iconColor = Colors.blue;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 18),
    );
  }

  // Convertir le symbole technique en nom convivial pour débutants
  String _getFriendlyName(String symbol) {
    // Table de correspondance pour les noms conviviaux
    final Map<String, String> friendlyNames = {
      'BTCUSDT': 'Bitcoin',
      'ETHUSDT': 'Ethereum',
      'SOLUSDT': 'Solana',
      'DOGEUSDT': 'Dogecoin',
      'SHIBUSDT': 'Shiba Inu',
      'ADAUSDT': 'Cardano',
      'XRPUSDT': 'Ripple',
      'DOTUSDT': 'Polkadot',
      'AVAXUSDT': 'Avalanche',
      'MATICUSDT': 'Polygon',
      'LINKUSDT': 'Chainlink',
      'UNIUSDT': 'Uniswap',
      'AAVEUSDT': 'Aave',
      'ATOMUSDT': 'Cosmos',
      'TRXUSDT': 'Tron',
      'LTCUSDT': 'Litecoin',
      'EOSUSDT': 'EOS',
      'BNBUSDT': 'Binance Coin',
      'BCHUSDT': 'Bitcoin Cash',
      'FILUSDT': 'Filecoin',
      'VETUSDT': 'VeChain',
      'THETAUSDT': 'Theta',
      'XTZUSDT': 'Tezos',
      'ICPUSDT': 'Internet Computer',
      'XLMUSDT': 'Stellar',
      'AXSUSDT': 'Axie Infinity',
      'NEARUSDT': 'NEAR Protocol',
      'ALGOUSDT': 'Algorand',
      'FTMUSDT': 'Fantom',
      'SANDUSDT': 'The Sandbox',
      'MANAUSDT': 'Decentraland',
      'GALAUSDT': 'Gala',
      'PEPECOINUSDT': 'Pepe',
      'PEPEUSDT': 'Pepe',
      'EURUSDT': 'Euro',
      'GBPUSDT': 'British Pound',
      'JPYUSDT': 'Japanese Yen',
      'AUDUSDT': 'Australian Dollar',
      'CADUSDT': 'Canadian Dollar',
      'CHFUSDT': 'Swiss Franc',
      'XAUUSDT': 'Or (Gold)',
      'XAGUSDT': 'Argent (Silver)',
      'XTIUSDT': 'Pétrole WTI (Oil)',
      'BRENTUSDT': 'Pétrole Brent (Oil)',
    };

    // Si le symbole est dans notre table, retourner le nom convivial
    if (friendlyNames.containsKey(symbol)) {
      return friendlyNames[symbol]!;
    }

    // Sinon, essayer de déduire un nom convivial
    if (symbol.endsWith('USDT')) {
      String base = symbol.replaceAll('USDT', '');
      return base; // Retourner juste le nom de base
    }

    return symbol; // Retour par défaut si aucune règle ne s'applique
  }

  Widget _buildIntervalSelector() {
    // Modifions les intervalles disponibles pour éviter l'erreur avec 5y
    final intervals = ['1m', '5m', '15m', '30m', '1h', '4h', '1d', '1w', '1M'];

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
    final localizations = AppLocalizations.of(context)!;

    if (_candles == null || _selectedPair == null) {
      return Center(child: Text(localizations.noChartData));
    }

    try {
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

      // Envelopper le widget Candlesticks dans un try-catch pour gérer les exceptions
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            formattedCandles.isNotEmpty
                ? candlesticks.Candlesticks(
                  candles: formattedCandles,
                  onLoadMoreCandles: () async {
                    // Charger plus de bougies si nécessaire
                    return;
                  },
                )
                : Center(
                  child: Text(localizations.noCandleData(_selectedPair!)),
                ),
      );
    } catch (e) {
      // En cas d'erreur, afficher un message d'erreur plutôt que de planter
      print('Error rendering candlestick chart: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(localizations.errorRenderingChart(e.toString())),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCandles,
              child: Text(localizations.tryAgain),
            ),
          ],
        ),
      );
    }
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
    final localizations = AppLocalizations.of(context)!;

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
            localizations.askDeepSeek,
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
              localizations.exampleQuestion(_selectedPair ?? ''),
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
    final localizations = AppLocalizations.of(context)!;

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
                          localizations.copy,
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
    final localizations = AppLocalizations.of(context)!;

    // Pre-formed questions about trading analysis
    final List<String> preformedQuestions = [
      localizations.trendQuestion(_selectedPair ?? ''),
      localizations.supportResistanceQuestion,
      localizations.entryPointQuestion(_selectedPair ?? ''),
      localizations.exitPositionQuestion,
      localizations.technicalIndicatorsQuestion,
      localizations.volumePatternQuestion,
      localizations.marketSentimentQuestion(_selectedPair ?? ''),
      localizations.bitcoinComparisonQuestion,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: preformedQuestions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ActionChip(
                  label: Text(
                    preformedQuestions[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  onPressed: () => _sendMessage(preformedQuestions[index]),
                ),
              );
            },
          ),
        ),
        Container(
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
          child:
              _isAnalyzing
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localizations.analyzingChart,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder:
                            (context) =>
                                _buildQuestionSelector(preformedQuestions),
                      );
                    },
                    icon: const Icon(Icons.question_answer),
                    label: Text(localizations.selectQuestion),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildQuestionSelector(List<String> questions) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.selectAQuestion(_selectedPair ?? ''),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(questions[index]),
                  leading: Icon(
                    _getQuestionIcon(questions[index]),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(questions[index]);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getQuestionIcon(String question) {
    if (question.contains('trend')) {
      return Icons.trending_up;
    } else if (question.contains('support') ||
        question.contains('resistance')) {
      return Icons.line_axis;
    } else if (question.contains('entry')) {
      return Icons.login;
    } else if (question.contains('exit')) {
      return Icons.logout;
    } else if (question.contains('indicators')) {
      return Icons.analytics;
    } else if (question.contains('volume')) {
      return Icons.bar_chart;
    } else if (question.contains('sentiment')) {
      return Icons.mood;
    } else if (question.contains('compare')) {
      return Icons.compare_arrows;
    } else {
      return Icons.question_answer;
    }
  }

  void _sendMessage(String message) async {
    final localizations = AppLocalizations.of(context)!;
    final locale =
        Localizations.localeOf(
          context,
        ).toString(); // Récupérer la locale actuelle

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
        _chatHistory.add(localizations.noChartData);
        _isAnalyzing = false;
      });
      return;
    }

    try {
      // Supprimer la vérification d'API key qui génère une erreur si manquante
      // L'OpenRouterService gère maintenant le fallback automatiquement

      final response = await _openRouterService.generateMarketAnalysis(
        symbol: currentPair!,
        interval: currentInterval,
        candles: _candles!,
        conversationHistory: _chatHistory,
        userQuestion: message,
        locale: locale, // Passer la locale actuelle
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
        _chatHistory.add(localizations.errorLoadingData(e.toString()));
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
    final localizations = AppLocalizations.of(context)!;

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.analysisCopied)));
    });
  }
}
