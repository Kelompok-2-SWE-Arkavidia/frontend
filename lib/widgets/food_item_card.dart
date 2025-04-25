import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';


class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const FoodItemCard({
    Key? key,
    required this.item,
    required this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysUntil = item.expiryDate.difference(DateTime.now()).inDays;
    final isExpired = daysUntil < 0;
    final isSoonToExpire = daysUntil >= 0 && daysUntil <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.quantity,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isExpired, isSoonToExpire, daysUntil),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color:
                          isExpired
                              ? Colors.red
                              : (isSoonToExpire ? Colors.orange : Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kadaluarsa: ${DateFormat('d MMM yyyy', 'id').format(item.expiryDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isExpired
                                ? Colors.red
                                : (isSoonToExpire
                                    ? Colors.orange
                                    : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.blue,
                      ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired, bool isSoonToExpire, int daysUntil) {
    String text;
    Color badgeColor;
    Color textColor;

    if (isExpired) {
      text = 'Kadaluarsa';
      badgeColor = Colors.red[50]!;
      textColor = Colors.red;
    } else if (isSoonToExpire) {
      text =
          daysUntil == 0
              ? 'Hari ini'
              : (daysUntil == 1 ? 'Besok' : '$daysUntil hari lagi');
      badgeColor = Colors.orange[50]!;
      textColor = Colors.orange;
    } else {
      text = '$daysUntil hari lagi';
      badgeColor = Colors.green[50]!;
      textColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
