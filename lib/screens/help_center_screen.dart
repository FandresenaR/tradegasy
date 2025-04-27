import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center'), elevation: 0),
      body: ListView(
        children: [
          _buildContactSection(context),
          const Divider(),
          _buildFAQSection(context),
          const Divider(),
          _buildAPILinksSection(context),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Support',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.support_agent, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Technical Support',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'If you encounter any issues or have questions about TradeGasy, please contact our support team:',
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'fandresenar6@gmail.com'),
                      ).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email copied to clipboard'),
                          ),
                        );
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'fandresenar6@gmail.com',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Our typical response time is within 24 hours.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'question': 'What is TradeGasy?',
        'answer':
            'TradeGasy is a cryptocurrency trading assistant that helps you analyze market trends, get AI-powered insights, and receive trading signals. It combines real-time market data with advanced AI to provide you with actionable trading information.',
      },
      {
        'question': 'Do I need an API key to use the app?',
        'answer':
            'Yes, you need to configure at least one API key to use all the features of TradeGasy. For market data, you\'ll need a Binance API key. For AI analysis, you can use OpenRouter, Hugging Face, or Replicate API keys. Check the "API Keys" section in settings to configure them.',
      },
      {
        'question': 'How do trading signals work?',
        'answer':
            'Trading signals are generated based on technical analysis of market data. The app analyzes indicators like MACD, RSI, and Moving Averages to identify potential buy or sell opportunities. The signals include entry price, target price, stop loss, and strength indicators.',
      },
      {
        'question': 'How accurate is the AI analysis?',
        'answer':
            'The AI analysis is provided for informational purposes only and should not be considered as financial advice. While our AI models are trained on market data and trading patterns, cryptocurrency markets are highly volatile and unpredictable. Always do your own research before making trading decisions.',
      },
      {
        'question': 'Which AI provider should I use?',
        'answer':
            'TradeGasy supports multiple AI providers: OpenRouter (DeepSeek R1), Hugging Face (Mistral), and Replicate (Llama). Each provider has its strengths. We recommend trying different providers to see which one provides the most useful insights for your trading style.',
      },
      {
        'question': 'Is my API key information secure?',
        'answer':
            'Yes, your API keys are stored securely on your device using encrypted storage. Your keys are never sent to our servers and are only used to make API calls directly from your device to the respective service providers.',
      },
      {
        'question': 'What should I do if the app stops working?',
        'answer':
            'If you encounter issues, try the following steps: 1) Check your internet connection, 2) Verify your API keys are valid and have sufficient credits, 3) Restart the app, 4) Clear the app cache in your device settings, 5) If the issue persists, contact our support team with details about the problem.',
      },
      {
        'question': 'How often are trading signals generated?',
        'answer':
            'You can generate new trading signals manually by tapping the lightning bolt button on the home screen. The app analyzes the top trading pairs by volume and generates signals when technical indicators align. You can also pull down to refresh on the home screen to check for new signals.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    faqs[index]['question']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(faqs[index]['answer']!),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAPILinksSection(BuildContext context) {
    final List<Map<String, dynamic>> apiServices = [
      {
        'name': 'OpenRouter',
        'description':
            'Used for DeepSeek R1 AI analysis. Create an account and get API keys for advanced market insights.',
        'url': 'https://openrouter.ai/keys',
        'icon': Icons.smart_toy_outlined,
        'color': Colors.green,
      },
      {
        'name': 'Hugging Face',
        'description':
            'Alternative AI provider using Mistral models. Sign up to get API keys for market analysis.',
        'url': 'https://huggingface.co/settings/tokens',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {
        'name': 'Replicate',
        'description':
            'AI provider using Llama models. Create an account to get API keys for market insights.',
        'url': 'https://replicate.com/account/api-tokens',
        'icon': Icons.auto_awesome,
        'color': Colors.blue,
      },
      {
        'name': 'Binance',
        'description':
            'Create API keys to access real-time market data and trading information for cryptocurrencies.',
        'url': 'https://www.binance.com/en/my/settings/api-management',
        'icon': Icons.bar_chart,
        'color': Colors.amber,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('API Services', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Register on these services to obtain API keys for TradeGasy',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apiServices.length,
            itemBuilder: (context, index) {
              final service = apiServices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: service['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(service['icon'], color: service['color']),
                  ),
                  title: Text(
                    service['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(service['description']),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _launchUrl(service['url']),
                        child: Text(
                          'Register/Get API Keys',
                          style: TextStyle(
                            color: service['color'],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Note',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When creating API keys, be sure to set appropriate permissions. For Binance, read-only permissions are sufficient for market data. Never share your API keys with anyone.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}
