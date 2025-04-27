import 'package:flutter/material.dart';
import 'package:tradegasy/services/api_key_manager.dart';
import 'package:tradegasy/services/api_debugging_tools.dart';
import 'package:tradegasy/widgets/custom_button.dart';
import 'package:tradegasy/widgets/custom_card.dart';

class ApiDiagnosticScreen extends StatefulWidget {
  const ApiDiagnosticScreen({Key? key}) : super(key: key);

  @override
  _ApiDiagnosticScreenState createState() => _ApiDiagnosticScreenState();
}

class _ApiDiagnosticScreenState extends State<ApiDiagnosticScreen> {
  final ApiDebuggingTools _apiDebuggingTools = ApiDebuggingTools();
  final ApiKeyManager _apiKeyManager = ApiKeyManager();
  Map<String, dynamic> _diagnosticResults = {};
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final results = await _apiDebuggingTools.runFullDiagnostics();
      if (mounted) {
        setState(() {
          _diagnosticResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du diagnostic: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic des API')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultats du diagnostic',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildServiceStatusCards(),
                    const SizedBox(height: 20),
                    CustomButton(
                      onPressed: _runDiagnostics,
                      text: 'Relancer le diagnostic',
                      icon: Icons.refresh,
                    ),
                    const SizedBox(height: 30),
                    _buildTroubleshootingGuide(),
                  ],
                ),
              ),
    );
  }

  Widget _buildServiceStatusCards() {
    if (_diagnosticResults.isEmpty) {
      return const Center(
        child: Text('Aucun résultat de diagnostic disponible.'),
      );
    }

    List<Widget> cards = [];

    if (_diagnosticResults.containsKey('openrouter')) {
      cards.add(
        _buildServiceCard(
          'OpenRouter',
          _diagnosticResults['openrouter'],
          Icons.cloud,
        ),
      );
    }

    if (_diagnosticResults.containsKey('huggingface')) {
      cards.add(
        _buildServiceCard(
          'Hugging Face',
          _diagnosticResults['huggingface'],
          Icons.face,
        ),
      );
    }

    if (_diagnosticResults.containsKey('replicate')) {
      cards.add(
        _buildServiceCard(
          'Replicate',
          _diagnosticResults['replicate'],
          Icons.repeat,
        ),
      );
    }

    if (_diagnosticResults.containsKey('binance')) {
      cards.add(
        _buildServiceCard(
          'Binance',
          _diagnosticResults['binance'],
          Icons.currency_bitcoin,
        ),
      );
    }

    return Column(children: cards);
  }

  Widget _buildServiceCard(
    String serviceName,
    Map<String, dynamic> status,
    IconData icon,
  ) {
    bool isValid = status['isValid'] ?? false;
    String statusMessage = status['message'] ?? 'Statut inconnu';
    String errorCode = status['errorCode'] ?? '';

    // Détection spécifique de l'erreur 405 Method Not Allowed
    bool is405Error =
        errorCode == '405' || statusMessage.contains('405 Method Not Allowed');

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isValid ? Colors.green : Colors.red, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isValid ? 'Connecté' : 'Non connecté',
                      style: TextStyle(
                        color: isValid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Statut: $statusMessage', style: const TextStyle(fontSize: 14)),
          if (!isValid && is405Error) ...[
            const SizedBox(height: 8),
            const Text(
              'Erreur 405 détectée: Problème avec l\'URL de l\'API.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Une mise à jour de l\'application est recommandée. Si vous venez d\'installer la dernière version, veuillez nous contacter.',
              style: TextStyle(fontSize: 13),
            ),
          ],
          const SizedBox(height: 8),
          if (!isValid)
            TextButton(
              onPressed: () async {
                Navigator.pushNamed(context, '/api_keys');
              },
              child: const Text('Mettre à jour la clé API'),
            ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guide de dépannage',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. Vérifiez que vos clés API sont correctement saisies',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '2. Assurez-vous que votre connexion internet est stable',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '3. Si vous recevez une erreur 405, veuillez mettre à jour l\'application',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '4. Pour les clés OpenRouter, vérifiez que votre compte dispose de crédits suffisants',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                '5. Vous pouvez utiliser les clés de démonstration pour tester l\'application',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
