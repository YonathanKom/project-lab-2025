import 'package:flutter/material.dart';
import '../../models/prediction.dart';

class PredictionTile extends StatelessWidget {
  final ItemPrediction prediction;
  final VoidCallback? onAdd;
  final bool isAdding;

  const PredictionTile({
    super.key,
    required this.prediction,
    this.onAdd,
    this.isAdding = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildConfidenceIndicator(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            prediction.itemName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (prediction.currentPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              prediction.priceDisplay,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getReasonIcon(prediction.reason),
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            prediction.reasonDetail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (prediction.lastPurchased != null) ...[
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            prediction.lastPurchasedDisplay,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.shopping_basket,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${prediction.suggestedQuantity}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (prediction.storeDisplay.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              prediction.storeDisplay,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAddButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (prediction.confidenceScore * 100).round();
    final color = _getConfidenceColor(prediction.confidenceScore, theme);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: prediction.confidenceScore,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 3,
          ),
        ),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final theme = Theme.of(context);

    if (isAdding) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        Icons.add_shopping_cart,
        color: theme.colorScheme.primary,
      ),
      onPressed: onAdd,
      tooltip: 'Add to list',
    );
  }

  IconData _getReasonIcon(PredictionReason reason) {
    switch (reason) {
      case PredictionReason.frequentlyBought:
        return Icons.trending_up;
      case PredictionReason.householdFavorite:
        return Icons.group;
      case PredictionReason.recentlyPurchased:
        return Icons.refresh;
      case PredictionReason.seasonal:
        return Icons.calendar_today;
      case PredictionReason.complementary:
        return Icons.link;
    }
  }

  Color _getConfidenceColor(double confidence, ThemeData theme) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return theme.colorScheme.onSurfaceVariant;
    }
  }
}
