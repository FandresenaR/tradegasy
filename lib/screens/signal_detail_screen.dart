import 'package:flutter/material.dart';
import 'package:tradegasy/models/signal.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignalDetailScreen extends StatelessWidget {
  final TradingSignal signal;

  const SignalDetailScreen({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.signalPair(signal.pair)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.shareFeature)),
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
    final localizations = AppLocalizations.of(context)!;

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
                  signal.type == SignalType.buy
                      ? localizations.buy
                      : localizations.sell,
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
            localizations.signalId(signal.id),
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            localizations.createdAt(
              DateFormat('dd MMM yyyy, HH:mm').format(signal.timestamp),
            ),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    Color color;
    String label;
    IconData icon;

    switch (signal.status) {
      case SignalStatus.active:
        color = Colors.green;
        label = localizations.activeSignal;
        icon = Icons.trending_up;
        break;
      case SignalStatus.closed:
        color = Colors.blue;
        label = localizations.closedSignal;
        icon = Icons.check_circle;
        break;
      case SignalStatus.pending:
        color = Colors.orange;
        label = localizations.pendingSignal;
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
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.priceLevels,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPriceItem(
                    context,
                    localizations.entry,
                    signal.entryPrice.toString(),
                    Colors.blue,
                  ),
                  _buildPriceItem(
                    context,
                    localizations.takeProfit,
                    signal.takeProfit.toString(),
                    Colors.green,
                  ),
                  _buildPriceItem(
                    context,
                    localizations.stopLoss,
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
                      localizations.closingPrice,
                      signal.closingPrice.toString(),
                      Colors.purple,
                    ),
                    _buildPriceItem(
                      context,
                      localizations.profitLoss,
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
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.signalDetails,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            localizations.signalType,
            signal.type == SignalType.buy ? 'Buy' : 'Sell',
          ),
          _buildDetailRow(localizations.currencyPair, signal.pair),
          _buildDetailRow(
            localizations.entryPrice,
            signal.entryPrice.toString(),
          ),
          _buildDetailRow(
            localizations.takeProfitLevel,
            signal.takeProfit.toString(),
          ),
          _buildDetailRow(
            localizations.stopLossLevel,
            signal.stopLoss.toString(),
          ),
          _buildDetailRow(localizations.status, _getStatusText(context)),
          if (signal.closingPrice != null)
            _buildDetailRow(
              localizations.closingPrice,
              signal.closingPrice.toString(),
            ),
          if (signal.profit != null)
            _buildDetailRow(
              localizations.profitLoss,
              '${signal.profit! > 0 ? '+' : ''}${signal.profit}',
            ),
        ],
      ),
    );
  }

  String _getStatusText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    switch (signal.status) {
      case SignalStatus.active:
        return localizations.active;
      case SignalStatus.closed:
        return localizations.closed;
      case SignalStatus.pending:
        return localizations.pendingSignal;
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
    final localizations = AppLocalizations.of(context)!;

    // Séparation des notes en lignes individuelles pour traduction
    List<String> translatedNotes = [];
    if (signal.notes != null) {
      List<String> noteLines = signal.notes!.split('\n');
      for (String line in noteLines) {
        translatedNotes.add(_translateSignalReason(context, line.trim()));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.analysisNotes, style: theme.textTheme.titleLarge),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  translatedNotes
                      .map(
                        (note) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            note,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _translateSignalReason(BuildContext context, String reason) {
    final localizations = AppLocalizations.of(context)!;

    // Traduction des raisons d'analyse technique
    if (reason.contains("MACD a croisé au-dessus")) {
      return localizations.signalReason_macdBuy;
    } else if (reason.contains("MACD a croisé en dessous")) {
      return localizations.signalReason_macdSell;
    } else if (reason.contains("RSI est sorti de la zone de survente")) {
      return localizations.signalReason_rsiBuy;
    } else if (reason.contains("RSI est entré dans la zone de surachat")) {
      return localizations.signalReason_rsiSell;
    } else if (reason.contains("Prix au-dessus des moyennes mobiles")) {
      return localizations.signalReason_maBuy;
    } else if (reason.contains("Prix en dessous des moyennes mobiles")) {
      return localizations.signalReason_maSell;
    } else if (reason.contains("Le volume en hausse confirme")) {
      return localizations.signalReason_volumeConfirmsBuy;
    } else if (reason.contains("Diminution du volume")) {
      return localizations.signalReason_volumeConfirmsSell;
    }
    // Traduction des notes des signaux mockés
    else if (reason.contains("Strong momentum with bullish trend")) {
      return localizations.signalNote_strongMomentum;
    } else if (reason.contains("Resistance zone rejected price")) {
      return localizations.signalNote_resistanceRejection;
    } else if (reason.contains(
      "Waiting for confirmation at key support level",
    )) {
      return localizations.signalNote_supportConfirmation;
    } else if (reason.contains("Bearish trend continuation pattern")) {
      return localizations.signalNote_bearishContinuation;
    }

    // Si aucune correspondance n'est trouvée, retourner la raison telle quelle
    return reason;
  }

  Widget _buildActionButtons(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.closeSignalFeature)),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(localizations.markAsClosed),
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
                  SnackBar(content: Text(localizations.editSignalFeature)),
                );
              },
              icon: const Icon(Icons.edit),
              label: Text(localizations.editSignal),
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
