import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardStatsCard extends ConsumerStatefulWidget {
  const DashboardStatsCard({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardStatsCard> createState() => _DashboardStatsCardState();
}

class _DashboardStatsCardState extends ConsumerState<DashboardStatsCard> {
  @override
  void initState() {
    super.initState();

    // Fetch dashboard stats when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the dashboard stats provider
    final dashboardStatsData = ref.watch(dashboardStatsProvider);
    final stats = dashboardStatsData.stats;

    // Show loading or error state if needed
    if (dashboardStatsData.state == DashboardStatsState.loading) {
      return _buildLoadingCard();
    }

    if (dashboardStatsData.state == DashboardStatsState.error) {
      return _buildErrorCard(
        dashboardStatsData.errorMessage ?? 'Failed to load stats',
      );
    }

    // Build the stats card
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ringkasan Stok',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    ref
                        .read(dashboardStatsProvider.notifier)
                        .fetchDashboardStats();
                  },
                  tooltip: 'Perbarui statistik',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  count: stats.totalItems,
                  label: 'Total',
                  icon: Icons.inventory_2_outlined,
                  backgroundColor: const Color(0xFFE0E7FF),
                  iconColor: const Color(0xFF4F46E5),
                ),
                _buildStatItem(
                  count: stats.safeItems,
                  label: 'Aman',
                  icon: Icons.check_circle_outline,
                  backgroundColor: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF059669),
                ),
                _buildStatItem(
                  count: stats.warningItems,
                  label: 'Segera',
                  icon: Icons.watch_later_outlined,
                  backgroundColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                ),
                _buildStatItem(
                  count: stats.expiredItems,
                  label: 'Kadaluarsa',
                  icon: Icons.error_outline,
                  backgroundColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 28)),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Stok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat statistik...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ringkasan Stok',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    ref
                        .read(dashboardStatsProvider.notifier)
                        .fetchDashboardStats();
                  },
                  tooltip: 'Coba lagi',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat statistik',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorMessage,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(dashboardStatsProvider.notifier)
                          .fetchDashboardStats();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
