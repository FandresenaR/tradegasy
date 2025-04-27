import 'package:flutter/material.dart';
import 'package:tradegasy/data/market_data_service.dart';

class MarketAnalysisScreen extends StatefulWidget {
  final String symbol;
  final String timeframe;

  const MarketAnalysisScreen({
    super.key,
    required this.symbol,
    this.timeframe = '5y',
  });

  @override
  _MarketAnalysisScreenState createState() => _MarketAnalysisScreenState();
}

class _MarketAnalysisScreenState extends State<MarketAnalysisScreen> {
  final MarketDataService _marketDataService = MarketDataService();
  Future<Map<String, dynamic>>? _dataFuture;
  String _selectedTimeframe = '5y';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedTimeframe = widget.timeframe;
    _loadMarketData();
  }

  void _loadMarketData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _dataFuture = _marketDataService.getHistoricalMarketData(
      widget.symbol,
      '1d', // Daily interval
      _selectedTimeframe,
    );

    _dataFuture!
        .then((_) {
          setState(() {
            _isLoading = false;
          });
        })
        .catchError((e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.symbol} Analysis'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadMarketData),
        ],
      ),
      body: Column(
        children: [
          _buildTimeframeSelector(),
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorView()
                    : _buildMarketDataView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    // Utiliser des timeframes que l'API peut gérer correctement
    List<String> timeframes = ['1d', '1w', '1m', '3m', '6m', '1y'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            timeframes
                .map(
                  (tf) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ChoiceChip(
                      label: Text(tf),
                      selected: _selectedTimeframe == tf,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTimeframe = tf;
                          });
                          _loadMarketData();
                        }
                      },
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(onPressed: _loadMarketData, child: Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildMarketDataView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No data available'));
        }

        final data = snapshot.data!;
        final percentChange = data['percentChange'];
        final trend = data['trend'];
        final isCached = data['cached'] == true;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCached)
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 16),
                    color: Colors.amber.withOpacity(0.2),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing cached data due to connectivity issues. Pull down to refresh when connected.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Based on the chart data, ${widget.symbol} is showing a $trend trend over the $_selectedTimeframe timeframe with a $percentChange% change.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Market appears to be $trend in this timeframe.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                trend == 'bullish' ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Add a chart view here if you have a charting library
                SizedBox(height: 16),
                Text(
                  'Last updated: ${DateTime.parse(data['lastUpdated']).toLocal()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
