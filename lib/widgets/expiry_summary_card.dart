import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/storage_service.dart';

class ExpirySummaryCard extends StatefulWidget {
  const ExpirySummaryCard({Key? key}) : super(key: key);

  @override
  State<ExpirySummaryCard> createState() => _ExpirySummaryCardState();
}

class _ExpirySummaryCardState extends State<ExpirySummaryCard> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  int _expiredCount = 0;
  int _expiringSoonCount = 0;
  int _safeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<FoodItem> items = await _storageService.getFoodItems();
      final now = DateTime.now();

      int expired = 0;
      int expiringSoon = 0;
      int safe = 0;

      for (final item in items) {
        final daysUntil = item.expiryDate.difference(now).inDays;
        if (daysUntil < 0) {
          expired++;
        } else if (daysUntil <= 3) {
          expiringSoon++;
        } else {
          safe++;
        }
      }

      setState(() {
        _expiredCount = expired;
        _expiringSoonCount = expiringSoon;
        _safeCount = safe;
      });
    } catch (e) {
      debugPrint('Error loading summary: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final totalItems = _expiredCount + _expiringSoonCount + _safeCount;

    if (totalItems == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Text(
                    'Stok Makanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada makanan di stok Anda. Tambahkan item makanan untuk mulai mencatat kadaluarsa.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/home',
                    arguments: {'tabIndex': 1},
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Ringkasan Stok Makanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadSummary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.error_outline,
                    color: Colors.red,
                    count: _expiredCount,
                    label: 'Kadaluarsa',
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                    count: _expiringSoonCount,
                    label: 'Segera',
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    count: _safeCount,
                    label: 'Aman',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/home',
                    arguments: {'tabIndex': 1},
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Lihat Semua'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
