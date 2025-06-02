import 'package:flutter/material.dart';
import '../../models/shopping_list.dart';

class ItemTile extends StatelessWidget {
  final ShoppingItem item;
  final Function(ShoppingItem)? onToggle;
  final Function(ShoppingItem)? onEdit;
  final Function(ShoppingItem)? onDelete;

  const ItemTile({
    super.key,
    required this.item,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: onToggle != null ? (_) => onToggle!(item) : null,
          activeColor: colorScheme.primary,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased
                ? colorScheme.onSurface.withValues(alpha: 0.6)
                : colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity: ${item.quantity}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: item.isPurchased
                    ? colorScheme.onSurface.withValues(alpha: 0.5)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: item.isPurchased
                      ? colorScheme.onSurface.withValues(alpha: 0.5)
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit?.call(item);
                break;
              case 'delete':
                onDelete?.call(item);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18, color: colorScheme.onSurface),
                  const SizedBox(width: 8),
                  const Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
