import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/food_item_model.dart';
import '../providers/food_provider.dart';

class StockItem extends ConsumerWidget {
  final FoodItem item;
  final VoidCallback? onEdit;

  const StockItem({Key? key, required this.item, this.onEdit})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get UI status from item
    final status = item.getUIStatus(); // 'safe', 'warning', 'expired'

    Color borderColor;
    Color backgroundColor;
    Color textColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'safe':
        borderColor = const Color(0xFFD1FAE5);
        backgroundColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF047857);
        statusIcon = Icons.check_circle;
        statusText = 'Aman';
        break;
      case 'warning':
        borderColor = const Color(0xFFFEF3C7);
        backgroundColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFB45309);
        statusIcon = Icons.access_time;
        statusText = 'Segera Gunakan';
        break;
      case 'expired':
        borderColor = const Color(0xFFFEE2E2);
        backgroundColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFB91C1C);
        statusIcon = Icons.warning;
        statusText = 'Kadaluarsa';
        break;
      default:
        borderColor = Colors.grey[300]!;
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
        statusIcon = Icons.info;
        statusText = '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${item.quantity} ${item.unit}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Kadaluarsa: ${DateFormat('d MMM yyyy', 'id').format(item.expiryDate)}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Icon(statusIcon, size: 12, color: textColor),
                      const SizedBox(width: 2),
                      Text(
                        statusText,
                        style: TextStyle(color: textColor, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              padding: EdgeInsets.zero,
              onSelected: (value) async {
                if (value == 'edit' && onEdit != null) {
                  onEdit!();
                } else if (value == 'delete') {
                  // Show confirmation dialog
                  final confirmed = await _showDeleteConfirmation(context);
                  if (confirmed == true) {
                    // Use the foodItemsProvider to delete the item
                    final result = await ref
                        .read(foodItemsProvider.notifier)
                        .deleteFoodItem(item.id);

                    if (context.mounted) {
                      // Show a snackbar with the result
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Item dihapus'),
                          backgroundColor:
                              result['success'] ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder:
                  (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        height: 40,
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Hapus',
                            style: TextStyle(fontSize: 14, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus "${item.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
