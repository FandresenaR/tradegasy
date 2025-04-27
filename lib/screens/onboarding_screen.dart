import 'package:flutter/material.dart';
import 'package:tradegasy/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Welcome to TradeGasy',
      description:
          'Your intelligent cryptocurrency trading assistant powered by AI analysis and real-time market data.',
      iconData: Icons.waving_hand,
      secondaryIconData: Icons.currency_bitcoin,
      color: Colors.blue.shade800,
    ),
    OnboardingData(
      title: 'Smart Trading Signals',
      description:
          'Receive actionable trading signals based on technical analysis and market trends to optimize your trading strategy.',
      iconData: Icons.trending_up,
      secondaryIconData: Icons.signal_cellular_alt,
      color: Colors.green.shade800,
    ),
    OnboardingData(
      title: 'AI-Powered Analysis',
      description:
          'Ask questions about any cryptocurrency chart and receive expert analysis from our advanced AI assistant.',
      iconData: Icons.psychology,
      secondaryIconData: Icons.smart_toy,
      color: Colors.purple.shade800,
    ),
    OnboardingData(
      title: 'Real-Time Market Data',
      description:
          'Stay informed with real-time price charts, trends, and comprehensive market information for better decision making.',
      iconData: Icons.candlestick_chart,
      secondaryIconData: Icons.bar_chart,
      color: Colors.orange.shade800,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient that changes with page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _pages[_currentPage].color,
                  _pages[_currentPage].color.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Content pages
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () => _navigateToHome(context),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),

                // Page indicators and navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicators
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => _buildDotIndicator(index),
                        ),
                      ),

                      // Next/Get Started button
                      _currentPage == _pages.length - 1
                          ? _buildStartButton(context)
                          : _buildNextButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Utiliser des icônes au lieu d'images pour éviter les erreurs
          SizedBox(
            height: 160, // Hauteur fixe pour éviter le débordement
            child: _buildIconDisplay(data),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          // Utilise un Container avec constraints pour éviter le débordement
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                data.description,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconDisplay(OnboardingData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(data.iconData, size: 60, color: Colors.white.withOpacity(0.9)),
        const SizedBox(height: 20),
        Container(
          width: 160,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(data.secondaryIconData, size: 60, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color:
            _currentPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _pages[_currentPage].color,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      child: const Icon(Icons.arrow_forward),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigateToHome(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _pages[_currentPage].color,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text(
        "Let's Begin",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData iconData;
  final IconData secondaryIconData;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.iconData,
    required this.secondaryIconData,
    required this.color,
  });
}
