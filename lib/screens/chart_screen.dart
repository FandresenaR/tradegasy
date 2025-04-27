import 'package:flutter/material.dart';
import 'package:tradegasy/widgets/fix_chart_overflow.dart';
import 'package:tradegasy/data/market_data_service.dart';

class ChartScreen extends StatefulWidget {
  final String symbol;
  final String timeframe;

  const ChartScreen({super.key, required this.symbol, this.timeframe = '5y'});

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late String _currentTimeframe;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _chartData;
  final MarketDataService _dataService = MarketDataService();

  @override
  void initState() {
    super.initState();
    _currentTimeframe = widget.timeframe;
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dataService.getHistoricalMarketData(
        widget.symbol,
        '1d', // Intervalle journalier
        _currentTimeframe,
      );

      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeTimeframe(String timeframe) {
    if (_currentTimeframe != timeframe) {
      setState(() {
        _currentTimeframe = timeframe;
      });
      _loadChartData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.symbol} Chart'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadChartData),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sélecteur de période avec le timeframe actuel
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 40,
                child: ChartFixOverflowRow(
                  children:
                      ['1d', '1w', '1m', '3m', '6m', '1y', '5y']
                          .map(
                            (tf) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ChoiceChip(
                                label: Text(tf),
                                selected: _currentTimeframe == tf,
                                onSelected: (_) => _changeTimeframe(tf),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),

            // Contenu principal
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? _buildErrorView()
                      : _buildChartView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error'),
            SizedBox(height: 24),
            ElevatedButton(onPressed: _loadChartData, child: Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildChartView() {
    final bool isCached = _chartData?['cached'] == true;
    final String percentChange = _chartData?['percentChange'] ?? '0.00';
    final String trend = _chartData?['trend'] ?? 'neutral';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Afficher un avertissement si les données sont en cache
          if (isCached)
            Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing cached data due to connection issues. Pull to refresh when online.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Placeholder pour le graphique réel
          Container(
            height: 400,
            padding: EdgeInsets.all(8),
            child:
                _chartData != null
                    ? Center(
                      child: Text(
                        'Chart for ${widget.symbol} would be rendered here',
                      ),
                    )
                    : Center(child: Text('No chart data available')),
          ),

          // Analyse du marché
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Analysis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                Text(
                  'Based on the chart data, ${widget.symbol} is showing a $trend trend over the $_currentTimeframe timeframe with a $percentChange% change.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Market appears to be $trend in this timeframe.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        trend == 'bullish'
                            ? Colors.green
                            : (trend == 'bearish' ? Colors.red : Colors.grey),
                  ),
                ),
                SizedBox(height: 16),
                if (_chartData != null &&
                    _chartData!.containsKey('lastUpdated'))
                  Text(
                    'Last updated: ${DateTime.parse(_chartData!['lastUpdated']).toLocal()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
