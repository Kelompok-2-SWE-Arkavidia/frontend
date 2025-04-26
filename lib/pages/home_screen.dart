import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_header.dart';
import '../widgets/stock_item.dart';
import '../widgets/recipe_card.dart';
import '../widgets/donation_card.dart';
import '../widgets/barter_card.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/dashboard_stats_card.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';
import '../providers/food_provider.dart';
import '../models/food_item_model.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _loadHomeDataTimer;
  bool _initialLoadDone = false;
  bool _isTestModeActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen to tab changes to filter items by status
    _tabController.addListener(_handleTabChange);

    // Fetch food items for the initial tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(foodItemsProvider.notifier)
          .fetchFoodItems(status: 'active', refresh: true, limit: 3);

      // Check if test mode is active
      _isTestModeActive = BackgroundService.instance.isTestModeActive();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _loadHomeDataTimer?.cancel();
    super.dispose();
  }

  // Handle tab changes
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      String status;
      switch (_tabController.index) {
        case 1:
          status = 'active'; // API status untuk makanan aman
          break;
        case 2:
          status =
              'expiring_soon'; // API status untuk makanan segera kadaluarsa
          break;
        case 3:
          status = 'expired'; // API status untuk makanan kadaluarsa
          break;
        case 0:
        default:
          status = 'all'; // API status untuk semua makanan
          break;
      }
      // Fetch only 3 items for preview
      _fetchFoodItemsForTab(status);
    }
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddItemDialog());
  }

  void _navigateToStockPage(BuildContext context) {
    // Navigate to MainScreen with stock tab (index 1) active
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'tabIndex': 1},
    );
  }

  // Fungsi untuk menampilkan notifikasi test
  void _showTestNotification(BuildContext context) async {
    await NotificationService.instance.showImmediateTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifikasi kadaluarsa akan muncul dalam beberapa detik'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Toggle recurring test notifications
  void _toggleRecurringNotifications(BuildContext context) async {
    if (_isTestModeActive) {
      // Stop test mode
      await BackgroundService.instance.stopTestMode();
      setState(() {
        _isTestModeActive = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mode pengujian notifikasi dihentikan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Start test mode
      await BackgroundService.instance.startTestMode();
      setState(() {
        _isTestModeActive = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mode pengujian notifikasi diaktifkan - notifikasi akan muncul setiap 30 detik',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _fetchFoodItemsForTab(String status) {
    final currentStatus = ref.read(foodItemsProvider).currentStatus;
    if (status != currentStatus) {
      debugPrint(
        '🔄 Home screen fetching items for tab with status: $status (was: $currentStatus)',
      );
      ref
          .read(foodItemsProvider.notifier)
          .fetchFoodItems(status: status, refresh: true, limit: 3);
    } else {
      debugPrint(
        'ℹ️ Home screen tab status unchanged: $status, skipping API call',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodItemsState = ref.watch(foodItemsProvider);

    return Scaffold(
      appBar: const AppHeader(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test Notification Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Uji Notifikasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showTestNotification(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _isTestModeActive
                            ? Icons.notifications_off
                            : Icons.notifications_on_outlined,
                      ),
                      label: Text(
                        _isTestModeActive
                            ? 'Hentikan Tes 30 Detik'
                            : 'Mulai Tes 30 Detik',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isTestModeActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _toggleRecurringNotifications(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dashboard stats
              const DashboardStatsCard(),
              const SizedBox(height: 20),

              // Stock Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stok Makanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _navigateToStockPage(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Tambah Item',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _showAddItemDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    tabs: const [
                      Tab(text: 'Semua'),
                      Tab(
                        child: Text(
                          'Aman',
                          style: TextStyle(color: Color(0xFF22C55E)),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Segera',
                          style: TextStyle(color: Color(0xFFF59E0B)),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Kadaluarsa',
                          style: TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // All Tab - showing all items
                        _buildFoodItemsList(foodItemsState.items, 'all'),

                        // Safe Tab - filter items with 'active' status
                        _buildFoodItemsList(
                          foodItemsState.items
                              .where((item) => item.status == 'active')
                              .toList(),
                          'active',
                        ),

                        // Warning Tab - filter items with 'expiring_soon' status
                        _buildFoodItemsList(
                          foodItemsState.items
                              .where((item) => item.status == 'expiring_soon')
                              .toList(),
                          'expiring_soon',
                        ),

                        // Expired Tab - filter items with 'expired' status
                        _buildFoodItemsList(
                          foodItemsState.items
                              .where((item) => item.status == 'expired')
                              .toList(),
                          'expired',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recipe Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rekomendasi Resep',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/recipes');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 340,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 220,
                      child: RecipeCard(
                        title: 'Tumis Bayam Tomat',
                        ingredients: const ['Bayam', 'Tomat', 'Bawang'],
                        missingIngredients: const [],
                        imageUrl: 'https://picsum.photos/300/200?food=1',
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 220,
                      child: RecipeCard(
                        title: 'Telur Dadar Spesial',
                        ingredients: const ['Telur', 'Tomat'],
                        missingIngredients: const ['Daun Bawang'],
                        imageUrl: 'https://picsum.photos/300/200?food=2',
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 220,
                      child: RecipeCard(
                        title: 'Sandwich Telur',
                        ingredients: const ['Telur', 'Roti'],
                        missingIngredients: const ['Selada', 'Mayones'],
                        imageUrl: 'https://picsum.photos/300/200?food=3',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Donation Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Donasi Makanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/donate');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 260,
                      child: DonationCard(
                        name: 'Panti Asuhan Kasih',
                        distance: '1.2 km',
                        openHours: '08:00 - 17:00',
                        imageUrl: 'https://picsum.photos/300/150?charity=1',
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 260,
                      child: DonationCard(
                        name: 'Rumah Singgah Harapan',
                        distance: '2.5 km',
                        openHours: '09:00 - 16:00',
                        imageUrl: 'https://picsum.photos/300/150?charity=2',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Barter Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Barter Makanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/barter');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    child: const Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 200,
                      child: BarterCard(
                        title: 'Mie Instan (5 pcs)',
                        owner: 'Ahmad',
                        distance: '0.8 km',
                        expiryDate: DateTime(2025, 6, 10),
                        imageUrl: 'https://picsum.photos/200/150?barter=1',
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 200,
                      child: BarterCard(
                        title: 'Beras 2kg',
                        owner: 'Siti',
                        distance: '1.5 km',
                        expiryDate: DateTime(2025, 8, 15),
                        imageUrl: 'https://picsum.photos/200/150?barter=2',
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 200,
                      child: BarterCard(
                        title: 'Minyak Goreng 1L',
                        owner: 'Budi',
                        distance: '2.1 km',
                        expiryDate: DateTime(2025, 7, 20),
                        imageUrl: 'https://picsum.photos/200/150?barter=3',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build food items list for Home page preview
  Widget _buildFoodItemsList(List<FoodItem> items, String status) {
    // Check if food items are still loading
    final foodState = ref.watch(foodItemsProvider);
    if (foodState.state == FoodItemsState.loading && items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      String emptyMessage;
      switch (status) {
        case 'active':
          emptyMessage = 'Belum ada makanan aman';
          break;
        case 'expiring_soon':
          emptyMessage = 'Belum ada makanan segera kadaluarsa';
          break;
        case 'expired':
          emptyMessage = 'Belum ada makanan kadaluarsa';
          break;
        default:
          emptyMessage = 'Belum ada makanan';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: items.length > 3 ? 3 : items.length, // Limit to 3 items
      itemBuilder: (context, index) {
        final item = items[index];
        final itemStatus = item.getUIStatus();

        return StockItem(
          item: item,
          onEdit: () {
            _showAddItemDialog(context);
          },
        );
      },
    );
  }
}
