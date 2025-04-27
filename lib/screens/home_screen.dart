import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tradegasy/models/signal.dart';
import 'package:tradegasy/screens/market_screen.dart';
import 'package:tradegasy/screens/settings_screen.dart';
import 'package:tradegasy/screens/signal_detail_screen.dart';
import 'package:tradegasy/services/signal_generator.dart' as generator;
import 'package:tradegasy/services/signal_service.dart';
import 'package:tradegasy/widgets/signal_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<TradingSignal> _signals = [];
  generator.SignalGenerator? _signalGenerator;
  bool _isGeneratingSignals = false;
  bool _isInitialLoading = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour éviter les problèmes de state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      // Use a safe initialization for signal generator
      _signalGenerator = generator.SignalGenerator();
      await _signalGenerator!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _loadInitialSignals();
      }
    } catch (e) {
      print('Error initializing services: $e');
      // Continue with mock data only
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitialLoading = false;
        });
        _loadMockSignals();
      }
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
            // Explicitly cast to List<TradingSignal> if needed
            _signals.addAll(binanceSignals.cast<TradingSignal>());
            // Sort to ensure newest signals are at the top
            _signals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Use the actual logo image instead of an icon
            Image.asset(
              isDarkMode ? 'assets/icon/TG W.png' : 'assets/icon/TG B.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading logo: $error');
                // Fallback to the icon if image fails to load
                return const Icon(
                  Icons.currency_bitcoin,
                  color: Colors.amber,
                  size: 28,
                );
              },
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.appTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Display localized notification message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.notificationsComingSoon,
                  ),
                ),
              );
            },
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.homeScreenTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            activeIcon: const Icon(Icons.candlestick_chart),
            label: AppLocalizations.of(context)!.marketScreenTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settingsScreenTitle,
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseWaitForServices),
        ),
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
          _signals.insertAll(0, newSignals.cast<TradingSignal>());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.generatedSignals(newSignals.length.toString()),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noNewSignals)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorGeneratingSignals(e.toString()),
          ),
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
    final localizations = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async {
        try {
          final newSignals = await _signalGenerator!.generateSignals();
          setState(() {
            if (newSignals.isNotEmpty) {
              _signals.insertAll(0, newSignals.cast<TradingSignal>());
            }
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.errorRefreshingSignals(e.toString())),
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
                            localizations.recentSignals,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(localizations.seeAll),
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
    final localizations = AppLocalizations.of(context)!;
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
              localizations.signalsSummary,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  localizations.active,
                  activeSignals.toString(),
                  Colors.green,
                ),
                _buildSummaryItem(
                  context,
                  localizations.closed,
                  closedSignals.toString(),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  context,
                  localizations.successRate,
                  '75%',
                  Colors.amber,
                ),
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
