import 'package:flutter/material.dart';
import 'package:tradegasy/models/signal.dart';
import 'package:tradegasy/screens/market_screen.dart';
import 'package:tradegasy/screens/settings_screen.dart';
import 'package:tradegasy/screens/signal_detail_screen.dart';
import 'package:tradegasy/services/signal_generator.dart';
import 'package:tradegasy/services/signal_service.dart';
import 'package:tradegasy/widgets/signal_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tradegasy/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<TradingSignal> _signals = [];
  SignalGenerator? _signalGenerator;
  bool _isGeneratingSignals = false;
  bool _isInitialLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Use a safe initialization for signal generator
      _signalGenerator = SignalGenerator();
      await _signalGenerator!.initialize();
      setState(() {
        _isInitialized = true;
      });
      _loadInitialSignals();
    } catch (e) {
      print('Error initializing services: $e');
      // Continue with mock data only
      setState(() {
        _isInitialized = true;
        _isInitialLoading = false;
      });
      _loadMockSignals();
    }
  }

  void _loadMockSignals() {
    setState(() {
      _signals.addAll(SignalService.getMockSignals());
      _isInitialLoading = false;
    });
  }

  Future<void> _loadInitialSignals() async {
    setState(() {
      _isInitialLoading = true;
    });

    try {
      _loadMockSignals();

      if (_signalGenerator != null && _isInitialized) {
        final binanceSignals = await _signalGenerator!.generateSignals();

        if (binanceSignals.isNotEmpty) {
          setState(() {
            _signals.insertAll(0, binanceSignals);
          });
        }
      }
    } catch (e) {
      print('Error loading initial signals: $e');
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TradeGasy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Icon(Icons.candlestick_chart),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed: _generateSignals,
                child:
                    _isGeneratingSignals
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.bolt),
              )
              : null,
    );
  }

  Future<void> _generateSignals() async {
    if (_isGeneratingSignals || !_isInitialized || _signalGenerator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for services to initialize')),
      );
      return;
    }

    setState(() {
      _isGeneratingSignals = true;
    });

    try {
      final newSignals = await _signalGenerator!.generateSignals();

      if (newSignals.isNotEmpty) {
        setState(() {
          _signals.insertAll(0, newSignals);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${newSignals.length} new signals'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new signals found at this time')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating signals: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGeneratingSignals = false;
      });
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const MarketScreen();
      case 2:
        return const SettingsScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        try {
          final newSignals = await _signalGenerator!.generateSignals();
          setState(() {
            if (newSignals.isNotEmpty) {
              _signals.insertAll(0, newSignals);
            }
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error refreshing signals: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child:
          _isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(child: _buildSummaryCard()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Signals',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final signal = _signals[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: SignalCard(
                            signal: signal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          SignalDetailScreen(signal: signal),
                                ),
                              );
                            },
                          ),
                        );
                      }, childCount: _signals.length),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSummaryCard() {
    final activeSignals =
        _signals.where((s) => s.status == SignalStatus.active).length;
    final closedSignals =
        _signals.where((s) => s.status == SignalStatus.closed).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signals Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  'Active',
                  activeSignals.toString(),
                  Colors.green,
                ),
                _buildSummaryItem(
                  context,
                  'Closed',
                  closedSignals.toString(),
                  Colors.blue,
                ),
                _buildSummaryItem(context, 'Success Rate', '75%', Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIconForLabel(label), color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Active':
        return Icons.trending_up;
      case 'Closed':
        return Icons.check_circle_outline;
      case 'Success Rate':
        return Icons.insights;
      default:
        return Icons.info_outline;
    }
  }
}
