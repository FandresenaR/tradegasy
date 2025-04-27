import 'package:flutter/material.dart';
import 'package:tradegasy/models/signal.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignalCard extends StatelessWidget {
  final TradingSignal signal;
  final VoidCallback onTap;

  const SignalCard({super.key, required this.signal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            signal.pair,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTypeChip(),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final localizations = AppLocalizations.of(context)!;

                  if (constraints.maxWidth < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem(
                          context,
                          localizations.entry,
                          signal.entryPrice.toString(),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem(
                          context,
                          localizations.takeProfit,
                          signal.takeProfit.toString(),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem(
                          context,
                          localizations.stopLoss,
                          signal.stopLoss.toString(),
                        ),
                        const SizedBox(height: 4),
                        _buildInfoItem(
                          context,
                          localizations.time,
                          _formatTime(signal.timestamp),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoItem(
                              context,
                              localizations.entry,
                              signal.entryPrice.toString(),
                            ),
                            const SizedBox(height: 4),
                            _buildInfoItem(
                              context,
                              localizations.takeProfit,
                              signal.takeProfit.toString(),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoItem(
                              context,
                              localizations.stopLoss,
                              signal.stopLoss.toString(),
                            ),
                            const SizedBox(height: 4),
                            _buildInfoItem(
                              context,
                              localizations.time,
                              _formatTime(signal.timestamp),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (signal.status) {
      case SignalStatus.active:
        color = Colors.green;
        label = localizations.active;
        break;
      case SignalStatus.closed:
        color = Colors.blue;
        label = localizations.closed;
        break;
      case SignalStatus.pending:
        color = Colors.orange;
        label = localizations.pendingSignal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeChip() {
    final isBuy = signal.type == SignalType.buy;
    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isBuy ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isBuy ? localizations.buy : localizations.sell,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm, d MMM').format(time);
  }
}
