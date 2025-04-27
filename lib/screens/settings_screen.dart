import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Ajouter cet import pour SystemNavigator
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tradegasy/providers/theme_provider.dart';
import 'package:tradegasy/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:tradegasy/services/api_key_manager.dart';
import 'package:tradegasy/services/api_debugging_tools.dart';
import 'package:tradegasy/screens/help_center_screen.dart';
import 'package:tradegasy/screens/profile_screen.dart';
import 'package:tradegasy/screens/api_diagnostic_screen.dart'; // Importer l'écran de diagnostic

// Helper class for displaying API key configuration information
class ApiKeyConfigInspector {
  static void showApiKeyConfigInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('API Key Information'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Binance API Key',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Required for accessing Binance market data and trading functionality.',
                ),
                SizedBox(height: 12),
                Text(
                  'Binance Secret Key',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Used for authentication with the Binance API.'),
                SizedBox(height: 12),
                Text(
                  'OpenRouter API Key',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Required for accessing AI-powered trading insights and analysis.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settingsScreenTitle)),
      body: ListView(
        children: [
          // Profile Section
          _ProfileCard(),

          // Settings Options
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'PREFERENCES',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // Dark Mode Toggle
          SwitchListTile(
            title: Text(localizations.darkMode),
            subtitle: Text(localizations.darkModeDescription),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: themeProvider.isDarkMode ? Colors.amber : Colors.blueGrey,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),

          const Divider(),

          // Language Toggle
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizations.language),
            subtitle: Text(localizations.languageDescription),
            trailing: DropdownButton<String>(
              value: languageProvider.locale.languageCode,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageProvider.setLocale(Locale(newValue));
                }
              },
              items:
                  <String>['en', 'fr'].map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value == 'en'
                            ? localizations.english
                            : localizations.french,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              languageProvider.locale.languageCode == value
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          const Divider(),

          // API Keys - New Option
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(localizations.apiKeys),
            subtitle: Text(localizations.apiKeysDescription),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiKeysScreen()),
              );
            },
          ),

          const Divider(),

          // Diagnostic des API
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.orange),
            title: Text(localizations.apiDiagnostic),
            subtitle: Text(localizations.apiDiagnosticDescription),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiDiagnosticScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // Help Center
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(localizations.helpCenter),
            subtitle: Text(localizations.helpCenterDescription),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // About App
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(localizations.aboutTradeGasy),
            subtitle: Text('${localizations.version} 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.notAvailable)),
              );
            },
          ),

          const SizedBox(height: 32),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Logout'),
            content: Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Quitter l'application au lieu d'afficher un message
                  SystemNavigator.pop();
                },
                child: Text('Logout', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Trader Account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Text('trader@example.com', overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // Navigate to the ProfileScreen instead of showing a snackbar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  bool _isLoading = true;
  String? _binanceApiKey;
  String? _binanceSecretKey;
  String? _openRouterApiKey;
  String? _huggingfaceApiKey;
  String? _replicateApiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiKeyManager = ApiKeyManager();
      _binanceApiKey = await apiKeyManager.getApiKeyAsync(
        ApiKeyType.binanceApiKey,
      );
      _binanceSecretKey = await apiKeyManager.getApiKeyAsync(
        ApiKeyType.binanceSecretKey,
      );
      _openRouterApiKey = await apiKeyManager.getApiKeyAsync(
        ApiKeyType.openrouterApiKey,
      );
      _huggingfaceApiKey = await apiKeyManager.getApiKeyAsync(
        ApiKeyType.huggingfaceApiKey,
      );
      _replicateApiKey = await apiKeyManager.getApiKeyAsync(
        ApiKeyType.replicateApiKey,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading API keys: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Keys'),
        actions: [
          // Bouton de diagnostic des API
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Diagnostic des API',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApiDiagnosticScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ApiKeyConfigInspector.showApiKeyConfigInfo(context);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure API Keys',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure your API keys for accessing trading data and AI features.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Binance API Key
                    _buildApiKeyItem(
                      context,
                      'Binance API Key',
                      _binanceApiKey,
                      'Required for accessing real-time market data and trading',
                      Icons.bar_chart,
                      Colors.amber,
                      () => _configureApiKey(ApiKeyType.binanceApiKey),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Binance Secret Keyey,
                    // Binance Secret Key
                    _buildApiKeyItem(
                      context,
                      'Binance Secret Key',
                      _binanceSecretKey,
                      'Required for authentication with Binance API',
                      Icons.lock_outline,
                      Colors.blue,
                      () => _configureApiKey(ApiKeyType.binanceSecretKey),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // OpenRouter API Keyey,
                    // OpenRouter API Key
                    _buildApiKeyItem(
                      context,
                      'OpenRouter API Key',
                      _openRouterApiKey,
                      'For DeepSeek R1 AI market analysis',
                      Icons.smart_toy_outlined,
                      Colors.green,
                      () => _configureApiKey(ApiKeyType.openrouterApiKey),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Hugging Face API KeyKey,
                    // Hugging Face API Key
                    _buildApiKeyItem(
                      context,
                      'Hugging Face API Key',
                      _huggingfaceApiKey,
                      'Alternative AI service for market analysis',
                      Icons.psychology,
                      Colors.purple,
                      () => _configureApiKey(ApiKeyType.huggingfaceApiKey),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Replicate API Keyy,
                    // Replicate API Key
                    _buildApiKeyItem(
                      context,
                      'Replicate API Key',
                      _replicateApiKey,
                      'Alternative AI service for market analysis',
                      Icons.auto_awesome,
                      Colors.blue,
                      () => _configureApiKey(ApiKeyType.replicateApiKey),
                    ),

                    const SizedBox(height: 32),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => _testApiConnection(),
                        icon: const Icon(Icons.network_check),
                        label: const Text('Test Connections'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _testApiConnection() async {
    // Check if API keys are available
    bool hasOpenRouterKey =
        _openRouterApiKey != null && _openRouterApiKey!.isNotEmpty;

    if (!hasOpenRouterKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure your OpenRouter API key first'),
        ),
      );
      return;
    }

    // Use the ApiDebuggingTools to test the connection
    final debugTools = ApiDebuggingTools();
    await debugTools.testOpenRouterConnection(context);
  }

  // Helper method to mask API keys for display
  String _maskApiKey(String key) {
    if (key.length <= 8) {
      return '••••••••';
    }
    // Show first 4 and last 4 characters, mask the rest
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  Widget _buildApiKeyItem(
    BuildContext context,
    String title,
    String? apiKey,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final bool isConfigured = apiKey != null && apiKey.isNotEmpty;
    final String maskedKey =
        isConfigured ? _maskApiKey(apiKey) : 'Not configured';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  maskedKey,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color:
                        isConfigured
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: Text(isConfigured ? 'Update' : 'Configure'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _configureApiKey(ApiKeyType type) async {
    String title;
    String? currentValue;
    String placeholder = '';
    String helperText = '';

    switch (type) {
      case ApiKeyType.binanceApiKey:
        title = 'Binance API Key';
        currentValue = _binanceApiKey;
        helperText = 'Paste your Binance API key here';
        break;
      case ApiKeyType.binanceSecretKey:
        title = 'Binance Secret Key';
        currentValue = _binanceSecretKey;
        helperText = 'Paste your Binance Secret key here';
        break;
      case ApiKeyType.openrouterApiKey:
        title = 'OpenRouter API Key';
        currentValue = _openRouterApiKey;
        placeholder = 'sk-or-...';
        helperText = 'Start with sk-or-, get from openrouter.ai';
        break;
      case ApiKeyType.huggingfaceApiKey:
        title = 'Hugging Face API Key';
        currentValue = _huggingfaceApiKey;
        placeholder = 'hf_...';
        helperText = 'Start with hf_, get from huggingface.co/settings/tokens';
        break;
      case ApiKeyType.replicateApiKey:
        title = 'Replicate API Key';
        currentValue = _replicateApiKey;
        placeholder = 'r8_...';
        helperText = 'Get from replicate.com/account/api-tokens';
        break;
    }

    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Configure $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: title,
                    border: const OutlineInputBorder(),
                    helperText: helperText,
                    hintText: placeholder,
                  ),
                  obscureText: type == ApiKeyType.binanceSecretKey,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                if (type == ApiKeyType.openrouterApiKey)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      'OpenRouter API keys must start with "sk-or-"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (type == ApiKeyType.huggingfaceApiKey)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      'Hugging Face API keys must start with "hf_"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (type == ApiKeyType.replicateApiKey)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      'Replicate API keys must start with "r8_"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  Navigator.pop(context, value);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result != null) {
      try {
        final apiKeyManager = ApiKeyManager();
        await apiKeyManager.saveApiKey(type, result);

        setState(() {
          switch (type) {
            case ApiKeyType.binanceApiKey:
              _binanceApiKey = result;
              break;
            case ApiKeyType.binanceSecretKey:
              _binanceSecretKey = result;
              break;
            case ApiKeyType.openrouterApiKey:
              _openRouterApiKey = result;
              break;
            case ApiKeyType.huggingfaceApiKey:
              _huggingfaceApiKey = result;
              break;
            case ApiKeyType.replicateApiKey:
              _replicateApiKey = result;
              break;
          }
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$title updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving API key: $e')));
      }
    }
  }
}
