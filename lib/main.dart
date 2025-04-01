import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:tradegasy/providers/theme_provider.dart';
import 'package:tradegasy/utils/storage_adapter.dart';
import 'package:tradegasy/utils/constants.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage adapter first
  final storageAdapter = SharedPrefsAdapter();
  await storageAdapter.initialize();

  // Try to load environment variables, but use fallbacks if it fails
  try {
    await dotenv.load(fileName: ".env");
    print("Environment loaded successfully");
  } catch (e) {
    print('Error loading .env file: $e');
    // Set fallback values when .env loading fails
    await _setFallbackEnvironmentValues();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageAdapter)),
      ],
      child: const TradeGasyApp(),
    ),
  );
}

Future<void> _setFallbackEnvironmentValues() async {
  // Use constants for fallback values
  dotenv.env['BINANCE_API_KEY'] = AppConstants.BINANCE_API_KEY;
  dotenv.env['BINANCE_API_SECRET'] = AppConstants.BINANCE_API_SECRET;
  dotenv.env['OPENROUTER_API_KEY'] = AppConstants.OPENROUTER_API_KEY;
  print("Using fallback environment values");
}

class TradeGasyApp extends StatelessWidget {
  const TradeGasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Show loading indicator if theme isn't initialized yet
        if (!themeProvider.isInitialized) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Remove the problematic image and replace with an icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.currency_bitcoin,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing TradeGasy...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        return MaterialApp(
          title: 'TradeGasy',
          theme: appTheme,
          darkTheme: darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        );
      },
    );
  }
}
