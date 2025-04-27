import 'package:flutter/material.dart';
import 'package:tradegasy/services/api_key_manager.dart';

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  final _binanceApiKeyController = TextEditingController();
  final _binanceSecretKeyController = TextEditingController();
  final _openRouterApiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  final ApiKeyManager _apiKeyManager = ApiKeyManager();

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  @override
  void dispose() {
    _binanceApiKeyController.dispose();
    _binanceSecretKeyController.dispose();
    _openRouterApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKeys() async {
    setState(() {
      _isLoading = true;
    });

    // Set values if they exist (will show as masked)
    final binanceApiKey = _apiKeyManager.getApiKey(ApiKeyType.binanceApiKey);
    final binanceSecretKey = _apiKeyManager.getApiKey(
      ApiKeyType.binanceSecretKey,
    );
    final openRouterApiKey = _apiKeyManager.getApiKey(
      ApiKeyType.openrouterApiKey,
    );

    if (binanceApiKey != null) {
      _binanceApiKeyController.text = '••••••••••••••••••';
    }

    if (binanceSecretKey != null) {
      _binanceSecretKeyController.text = '••••••••••••••••••';
    }

    if (openRouterApiKey != null) {
      _openRouterApiKeyController.text = '••••••••••••••••••';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Keys')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'Configure your API keys for accessing market data and AI features.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      _buildKeySection(
                        title: 'Binance API Key',
                        subtitle: 'Required for detailed market data',
                        controller: _binanceApiKeyController,
                        icon: Icons.currency_bitcoin,
                        keyType: ApiKeyType.binanceApiKey,
                      ),
                      const SizedBox(height: 16),
                      _buildKeySection(
                        title: 'Binance Secret Key',
                        subtitle: 'Required for authenticated Binance requests',
                        controller: _binanceSecretKeyController,
                        icon: Icons.key,
                        keyType: ApiKeyType.binanceSecretKey,
                      ),
                      const SizedBox(height: 16),
                      _buildKeySection(
                        title: 'OpenRouter API Key',
                        subtitle: 'Required for AI-powered market analysis',
                        controller: _openRouterApiKeyController,
                        icon: Icons.psychology,
                        keyType: ApiKeyType.openrouterApiKey,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saveAllKeys,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save All Keys'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _clearAllKeys,
                        child: const Text(
                          'Clear All Keys',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Note: Your API keys are securely stored on your device and are never sent to our servers.',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildKeySection({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
    required ApiKeyType keyType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveSingleKey(keyType),
              tooltip: 'Save this key',
            ),
          ),
          obscureText: true,
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                value == '••••••••••••••••••') {
              return 'Please enter a valid API key';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _saveSingleKey(ApiKeyType keyType) async {
    String value;

    switch (keyType) {
      case ApiKeyType.binanceApiKey:
        value = _binanceApiKeyController.text;
        break;
      case ApiKeyType.binanceSecretKey:
        value = _binanceSecretKeyController.text;
        break;
      case ApiKeyType.openrouterApiKey:
        value = _openRouterApiKeyController.text;
        break;
      case ApiKeyType.huggingfaceApiKey:
        // Handle Hugging Face API key when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hugging Face API key not yet supported'),
          ),
        );
        return;
      case ApiKeyType.replicateApiKey:
        // Handle Replicate API key when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Replicate API key not yet supported')),
        );
        return;
    }

    // Don't save placeholder masked text
    if (value == '••••••••••••••••••') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new key value')),
      );
      return;
    }

    await _apiKeyManager.saveApiKey(keyType, value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved successfully')),
      );
    }
  }

  Future<void> _saveAllKeys() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_binanceApiKeyController.text != '••••••••••••••••••') {
      await _apiKeyManager.saveApiKey(
        ApiKeyType.binanceApiKey,
        _binanceApiKeyController.text,
      );
    }

    if (_binanceSecretKeyController.text != '••••••••••••••••••') {
      await _apiKeyManager.saveApiKey(
        ApiKeyType.binanceSecretKey,
        _binanceSecretKeyController.text,
      );
    }

    if (_openRouterApiKeyController.text != '••••••••••••••••••') {
      await _apiKeyManager.saveApiKey(
        ApiKeyType.openrouterApiKey,
        _openRouterApiKeyController.text,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All API keys saved successfully')),
      );
    }
  }

  Future<void> _clearAllKeys() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Clear All Keys?'),
                content: const Text(
                  'This will remove all your API keys from secure storage. '
                  'You will need to re-enter them to use the app\'s features.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      await _apiKeyManager.clearAllKeys();

      if (mounted) {
        setState(() {
          _binanceApiKeyController.clear();
          _binanceSecretKeyController.clear();
          _openRouterApiKeyController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All API keys have been cleared')),
        );
      }
    }
  }
}
