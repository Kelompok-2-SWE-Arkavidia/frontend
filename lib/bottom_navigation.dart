import 'package:flutter/material.dart';
import 'package:foodiav2/pages/food_scanner_screen.dart';
import 'package:foodiav2/pages/receipt_scanner_page.dart';
import 'theme/app_theme.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        BottomAppBar(
          elevation: 8,
          notchMargin: 8,
          shape: const CircularNotch(notchMargin: 8, notchRadius: 36),
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.home_outlined,
                  Icons.home,
                  'Beranda',
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.restaurant_menu_outlined,
                  Icons.restaurant_menu,
                  'Resep',
                ),
                // Empty space for the center camera button
                const SizedBox(width: 64),
                _buildNavItem(
                  context,
                  3,
                  Icons.favorite_outline,
                  Icons.favorite,
                  'Donasi',
                ),
                _buildNavItem(
                  context,
                  4,
                  Icons.swap_horiz_outlined,
                  Icons.swap_horiz,
                  'Barter',
                ),
              ],
            ),
          ),
        ),

        // Floating action button
        _buildFloatingActionButton(context),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Positioned(
      bottom: 16,
      child: FloatingActionButton(
        elevation: 2,
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => _showScanOptions(context),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Mode Pemindaian',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                _buildScanOption(
                  context,
                  icon: Icons.food_bank,
                  title: 'Pindai Makanan',
                  subtitle: 'Deteksi umur dan kesegaran makanan dengan kamera',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FoodScannerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildScanOption(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Pindai Struk Belanja',
                  subtitle: 'Deteksi makanan dari struk belanja',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReceiptScannerPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildScanOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: AppTheme.primaryColor, size: 32),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}

class CircularNotch extends NotchedShape {
  final double notchMargin;
  final double notchRadius;

  const CircularNotch({required this.notchMargin, required this.notchRadius});

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest == null || !host.overlaps(guest)) {
      return Path()..addRect(host);
    }

    final notchRadius = guest.width / 2 + notchMargin;

    return Path()
      ..moveTo(host.left, host.top)
      ..lineTo(host.right, host.top)
      ..lineTo(host.right, host.bottom)
      ..lineTo(host.left, host.bottom)
      ..lineTo(host.left, host.top)
      ..close()
      ..addOval(
        Rect.fromCircle(
          center: Offset(guest.center.dx, guest.center.dy),
          radius: notchRadius,
        ),
      );
  }
}
