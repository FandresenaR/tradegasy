import 'package:flutter/material.dart';
import 'package:tradegasy/models/signal.dart';
import 'package:intl/intl.dart';

class SignalDetailScreen extends StatelessWidget {
  final TradingSignal signal;

  const SignalDetailScreen({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${signal.pair} Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildPriceSection(context),
            const Divider(height: 32),
            _buildDetailsSection(context),
            if (signal.notes != null) ...[
              const Divider(height: 32),
              _buildNotesSection(context),
            ],
            const SizedBox(height: 24),
            if (signal.status == SignalStatus.active)
              _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color:
          signal.type == SignalType.buy
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                signal.pair,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      signal.type == SignalType.buy ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  signal.type == SignalType.buy ? 'BUY' : 'SELL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatusBadge(context),
          const SizedBox(height: 8),
          Text(
            'Signal ID: ${signal.id}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            'Created: ${DateFormat('dd MMM yyyy, HH:mm').format(signal.timestamp)}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (signal.status) {
      case SignalStatus.active:
        color = Colors.green;
        label = 'Active Signal';
        icon = Icons.trending_up;
        break;
      case SignalStatus.closed:
        color = Colors.blue;
        label = 'Closed Signal';
        icon = Icons.check_circle;
        break;
      case SignalStatus.pending:
        color = Colors.orange;
        label = 'Pending Signal';
        icon = Icons.pending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price Levels',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPriceItem(
                    context,
                    'Entry',
                    signal.entryPrice.toString(),
                    Colors.blue,
                  ),
                  _buildPriceItem(
                    context,
                    'Take Profit',
                    signal.takeProfit.toString(),
                    Colors.green,
                  ),
                  _buildPriceItem(
                    context,
                    'Stop Loss',
                    signal.stopLoss.toString(),
                    Colors.red,
                  ),
                ],
              ),
              if (signal.status == SignalStatus.closed &&
                  signal.closingPrice != null) ...[
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPriceItem(
                      context,
                      'Closing Price',
                      signal.closingPrice.toString(),
                      Colors.purple,
                    ),
                    _buildPriceItem(
                      context,
                      'Profit/Loss',
                      '${signal.profit! > 0 ? '+' : ''}${signal.profit}',
                      signal.profit! > 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Signal Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Signal Type',
            signal.type == SignalType.buy ? 'Buy' : 'Sell',
          ),
          _buildDetailRow('Currency Pair', signal.pair),
          _buildDetailRow('Entry Price', signal.entryPrice.toString()),
          _buildDetailRow('Take Profit Level', signal.takeProfit.toString()),
          _buildDetailRow('Stop Loss Level', signal.stopLoss.toString()),
          _buildDetailRow('Status', _getStatusText()),
          if (signal.closingPrice != null)
            _buildDetailRow('Closing Price', signal.closingPrice.toString()),
          if (signal.profit != null)
            _buildDetailRow(
              'Profit/Loss',
              '${signal.profit! > 0 ? '+' : ''}${signal.profit}',
            ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (signal.status) {
      case SignalStatus.active:
        return 'Active';
      case SignalStatus.closed:
        return 'Closed';
      case SignalStatus.pending:
        return 'Pending';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analysis Notes', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  theme.brightness == Brightness.dark
                      ? theme.colorScheme.surface.withOpacity(0.6)
                      : theme.colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    theme.brightness == Brightness.dark
                        ? theme.colorScheme.onSurface.withOpacity(0.2)
                        : theme.colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Text(
              signal.notes!,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Close signal feature coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Closed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit signal feature coming soon'),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Signal'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
