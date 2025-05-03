import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../widgets/app_header.dart';
import '../widgets/stock_item.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/dashboard_stats_card.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';
import '../providers/food_provider.dart';
import '../models/food_item_model.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isTestModeActive = false;

  // Debounce timer untuk pencarian
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();

      // Check if test mode is active
      _isTestModeActive = BackgroundService.instance.isTestModeActive();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }

    // Map tab index to status
    final statuses = ['all', 'active', 'expiring_soon', 'expired'];
    final newStatus = statuses[_tabController.index];

    // Update status filter provider
    ref.read(statusFilterProvider.notifier).state = newStatus;

    // Filter items by new status
    ref.read(foodItemsProvider.notifier).filterByStatus(newStatus);
  }

  void _loadItems() {
    final status = ref.read(statusFilterProvider);
    ref.read(foodItemsProvider.notifier).fetchFoodItems(status: status);
  }

  // Method untuk melakukan pencarian dengan debounce
  void _onSearchChanged(String query) {
    // Reset timer setiap kali pengguna mengetik
    _debounceTimer?.cancel();

    // Update search query provider
    ref.read(searchQueryProvider.notifier).state = query;

    // Setelah pengguna berhenti mengetik selama 500ms, lakukan pencarian
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Use local filtering instead of API call
      ref.read(foodItemsProvider.notifier).filterItemsLocally(query);
    });
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddItemDialog());
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

  @override
  Widget build(BuildContext context) {
    // Watch the food items provider dan search query provider
    final foodItemsData = ref.watch(foodItemsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Pastikan text field menampilkan query saat ini
    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
    }

    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard stats yang lebih kompak
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: const DashboardStatsCard(),
          ),

          // Search bar tanpa judul Stok Makanan
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari item...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 8,
                ),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Tab bar dengan styling yang lebih kompak
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 2,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              padding: EdgeInsets.zero,
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
            ),
          ),

          // Tab view content - menggunakan 70% dari ruang halaman
          if (foodItemsData.state == FoodItemsState.loading &&
              foodItemsData.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              flex: 7, // Memberikan 70% dari ruang yang tersisa untuk list stok
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All items tab
                  _buildItemsList(foodItemsData),
                  // Safe items tab
                  _buildItemsList(foodItemsData),
                  // Warning items tab
                  _buildItemsList(foodItemsData),
                  // Expired items tab
                  _buildItemsList(foodItemsData),
                ],
              ),
            ),
        ],
      ),
      // Floating action button for adding items
      floatingActionButton: Container(
        height: 56.0,
        width: 56.0,
        margin: const EdgeInsets.only(
          bottom: 72.0,
        ), // Increased bottom margin to avoid bottom nav bar
        child: FloatingActionButton(
          heroTag: 'home_screen_fab',
          backgroundColor: AppTheme.primaryColor, // Use theme color
          elevation: 8.0,
          onPressed: () => _showAddItemDialog(context),
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildItemsList(FoodItemsData foodItemsData) {
    // Show loading indicator if loading
    if (foodItemsData.state == FoodItemsState.loading &&
        foodItemsData.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message if there was an error
    if (foodItemsData.state == FoodItemsState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              foodItemsData.errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadItems,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Show empty state if no items
    if (foodItemsData.items.isEmpty) {
      final searchQuery = ref.watch(searchQueryProvider);
      String emptyMessage = 'Belum ada item';

      if (searchQuery.isNotEmpty) {
        emptyMessage = 'Tidak ada hasil untuk "$searchQuery"';
      } else {
        switch (ref.read(statusFilterProvider)) {
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
      }

      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (searchQuery.isEmpty)
                  Text(
                    'Tambahkan item pertama Anda',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                if (searchQuery.isEmpty)
                  ElevatedButton(
                    onPressed: () => _showAddItemDialog(context),
                    child: const Text('Tambah Item'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: const Text('Hapus Pencarian'),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    // Show list of items dengan padding yang lebih kecil
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RefreshIndicator(
        onRefresh: () async {
          final searchQuery = ref.read(searchQueryProvider);
          // First refresh the food items from API
          await ref.read(foodItemsProvider.notifier).refreshFoodItems();

          // Then apply any active search filter
          if (searchQuery.isNotEmpty) {
            ref
                .read(foodItemsProvider.notifier)
                .filterItemsLocally(searchQuery);
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount:
              foodItemsData.items.length +
              (foodItemsData.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the end if loading more
            if (foodItemsData.isLoadingMore &&
                index == foodItemsData.items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final item = foodItemsData.items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: StockItem(
                item: item,
                onEdit: () {
                  _showAddItemDialog(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
