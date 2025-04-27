import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tradegasy/services/api_key_manager.dart';
import 'package:tradegasy/screens/onboarding_screen.dart';
import 'package:tradegasy/providers/theme_provider.dart';
import 'package:tradegasy/providers/language_provider.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: Couldn't load .env file: $e");
    // Continue execution even if the .env file is missing
  }

  // Initialize API keys
  final apiKeyManager = ApiKeyManager();
  await apiKeyManager.initialize();

  // Run the app with error handling
  runApp(const TradeGasyAppWrapper());
}

// Wrapper to ensure MaterialApp is at the root level
class TradeGasyAppWrapper extends StatelessWidget {
  const TradeGasyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Utilisez MultiProvider pour fournir tous les providers nécessaires
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        // Ajoutez d'autres providers si nécessaire
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'TradeGasy',
            debugShowCheckedModeBanner: false, // Retirer le bandeau de debug
            // Localization settings
            locale: languageProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('fr'), // French
            ],

            theme:
                themeProvider.isDarkMode
                    ? ThemeData.dark().copyWith(
                      primaryColor: Colors.blue,
                      colorScheme: ColorScheme.dark(primary: Colors.blue),
                    )
                    : ThemeData.light().copyWith(
                      primaryColor: Colors.blue,
                      colorScheme: ColorScheme.light(primary: Colors.blue),
                    ),
            // Utiliser la page d'onboarding comme page principale
            home: const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
