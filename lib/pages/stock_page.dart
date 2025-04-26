import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_header.dart';
import '../widgets/stock_item.dart';
import '../widgets/add_item_dialog.dart';
import '../providers/food_provider.dart';
import '../providers/auth_provider.dart';
import '../models/food_item_model.dart';
import '../theme/app_theme.dart';
import '../services/background_service.dart';
import 'dart:async';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Listen to tab changes to filter items by status
    _tabController.addListener(_handleTabChange);

    // Fetch food items when screen loads only if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if data is already loaded from home screen
      final foodState = ref.read(foodItemsProvider);
      debugPrint(
        '📋 Initial foodState - currentStatus: ${foodState.currentStatus}, items count: ${foodState.items.length}',
      );

      // Sync tab controller with current status if data is already loaded
      if (!foodState.items.isEmpty) {
        debugPrint(
          '🔄 Syncing tab with existing status: ${foodState.currentStatus}',
        );
        _syncTabWithCurrentStatus(foodState.currentStatus);
      }

      // Only fetch if we have no items or if the currentStatus doesn't match the tab we want
      if (foodState.items.isEmpty || foodState.currentStatus != 'all') {
        debugPrint('🔄 Initial food items fetch - all items');
        ref
            .read(foodItemsProvider.notifier)
            .fetchFoodItems(status: 'all', limit: 10);
      } else {
        debugPrint('✅ Food items already loaded, skipping initial fetch');
        // If we already have the data but potentially not enough, we can still check if we need more
        if (foodState.totalItems > foodState.items.length &&
            !foodState.isLoadingMore) {
          debugPrint('🔄 Loading more items to complete the set');
          ref.read(foodItemsProvider.notifier).loadMore();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    // Cancel debounce timer if active
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Handle tab changes
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      String status;
      switch (_tabController.index) {
        case 1:
          status = 'active'; // API status for safe food
          debugPrint(
            '🔄 Tab changed to: Aman (status: active) - This should filter for active items only',
          );

          // Run diagnostic check when switching to the Aman tab
          _checkForStatusMappingIssues();
          break;
        case 2:
          status = 'expiring_soon'; // API status for expiring soon food
          debugPrint('🔄 Tab changed to: Segera (status: expiring_soon)');
          break;
        case 3:
          status = 'expired'; // API status for expired food
          debugPrint('🔄 Tab changed to: Kadaluarsa (status: expired)');
          break;
        case 0:
        default:
          status = 'all'; // API status for all food
          debugPrint('🔄 Tab changed to: Semua (status: all)');
          break;
      }

      // Debug all items in current filter
      final allItems = ref.read(foodItemsProvider).items;
      debugPrint('📊 All items count before filtering: ${allItems.length}');

      if (_tabController.index == 1) {
        // Extra debugging for the Aman tab specifically
        debugPrint('🔍 DEBUGGING AMAN TAB:');
        for (var item in allItems) {
          final uiStatus = item.getUIStatus();
          final match = uiStatus == 'safe';
          debugPrint(
            '📄 Item: ${item.name}, API Status: ${item.status}, UI Status: $uiStatus, Matches Safe: $match',
          );
        }

        // Count items that should appear in this tab
        final safeItems =
            allItems.where((item) => item.getUIStatus() == 'safe').toList();
        debugPrint(
          '🔢 Items that should appear in Aman tab: ${safeItems.length}',
        );
      }

      // Only filter items if the status has changed
      final currentStatus = ref.read(foodItemsProvider).currentStatus;
      if (status != currentStatus) {
        debugPrint(
          '🔄 Filtering items by status: $status (was: $currentStatus)',
        );
        ref.read(foodItemsProvider.notifier).filterByStatus(status, limit: 10);
      } else {
        debugPrint('ℹ️ Tab status unchanged: $status, skipping API call');
      }
    }
  }

  // Pencarian makanan berdasarkan kata kunci
  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });

    // Debounce search untuk menghindari terlalu banyak request API
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length >= 2) {
        // Jika query lebih dari 2 karakter, cari melalui API
        debugPrint('🔍 Searching via API for: $query');
        ref.read(foodItemsProvider.notifier).searchItems(query);
      } else if (query.isEmpty) {
        // Jika query kosong, kembali ke tampilan semua sesuai tab yang aktif
        debugPrint('🔍 Search cleared, restoring items');
        _handleTabChange();
      }
    });
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddItemDialog());
  }

  // Filter items based on search query (untuk lokal search saja)
  List<FoodItem> _filterItems(List<FoodItem> items, String query) {
    // Jika pencarian kurang dari 2 karakter, lakukan filter lokal
    if (query.isEmpty || query.length < 2) {
      return items;
    }

    // Jika query 2 karakter atau lebih, API search akan digunakan
    // Fungsi ini hanya untuk fallback atau pencarian lokal
    return items;
  }

  // Get status string from item
  String _getItemStatus(FoodItem item) {
    // Gunakan metode getUIStatus dari model FoodItem
    return item.getUIStatus();
  }

  // Handle unauthorized status
  void _handleUnauthorized() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Sesi Berakhir'),
              ],
            ),
            content: const Text(
              'Sesi anda telah berakhir. Silakan login kembali untuk melanjutkan.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Logout user
                  ref.read(authProvider.notifier).logout();

                  // Navigate to login screen (no changes needed here)
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                child: const Text(
                  'Login Kembali',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
    );
  }

  // Sync tab controller with current status
  void _syncTabWithCurrentStatus(String status) {
    int tabIndex;
    switch (status) {
      case 'active':
        tabIndex = 1; // Aman tab
        break;
      case 'expiring_soon':
        tabIndex = 2; // Segera tab
        break;
      case 'expired':
        tabIndex = 3; // Kadaluarsa tab
        break;
      default:
        tabIndex = 0; // Semua tab
    }

    // Update tab controller if needed
    if (_tabController.index != tabIndex) {
      debugPrint(
        '🔄 Syncing tab controller to match current status: $status (tab: $tabIndex)',
      );
      _tabController.animateTo(tabIndex);
    }
  }

  // Sync notifications with latest food items
  Future<void> _syncNotifications() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menyinkronkan notifikasi...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Force sync notifications
      await BackgroundService.instance.forceSyncNow();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Debug method to check for status mapping issues
  void _checkForStatusMappingIssues() {
    debugPrint('🔍 CHECKING FOR STATUS MAPPING ISSUES:');

    final items = ref.read(foodItemsProvider).items;
    debugPrint('📋 Total items in state: ${items.length}');

    // Count by API status
    int activeCount = 0;
    int expiringSoonCount = 0;
    int expiredCount = 0;
    int unknownCount = 0;

    // Count by UI status
    int safeCount = 0;
    int warningCount = 0;
    int expiredUICount = 0;

    for (var item in items) {
      // Count by API status
      switch (item.status.toLowerCase()) {
        case 'active':
          activeCount++;
          break;
        case 'expiring_soon':
          expiringSoonCount++;
          break;
        case 'expired':
          expiredCount++;
          break;
        default:
          unknownCount++;
          break;
      }

      // Count by UI status
      switch (item.getUIStatus()) {
        case 'safe':
          safeCount++;
          break;
        case 'warning':
          warningCount++;
          break;
        case 'expired':
          expiredUICount++;
          break;
      }

      // Check for inconsistencies
      if (item.status.toLowerCase() == 'active' &&
          item.getUIStatus() != 'safe') {
        debugPrint(
          '⚠️ INCONSISTENCY: Item ${item.name} has status "active" but UI status "${item.getUIStatus()}"',
        );
        debugPrint('   - Expiry date: ${item.expiryDate}');
        debugPrint(
          '   - Days until expiry: ${item.expiryDate.difference(DateTime.now()).inDays}',
        );
      }
    }

    debugPrint('📊 COUNT BY API STATUS:');
    debugPrint('   - active: $activeCount');
    debugPrint('   - expiring_soon: $expiringSoonCount');
    debugPrint('   - expired: $expiredCount');
    debugPrint('   - unknown: $unknownCount');

    debugPrint('📊 COUNT BY UI STATUS:');
    debugPrint('   - safe: $safeCount');
    debugPrint('   - warning: $warningCount');
    debugPrint('   - expired: $expiredUICount');
  }

  @override
  Widget build(BuildContext context) {
    // Get food items state from provider
    final foodItemsState = ref.watch(foodItemsProvider);

    // Check if unauthorized
    if (foodItemsState.state == FoodItemsState.unauthorized) {
      // Use Future.microtask to avoid calling setState during build
      Future.microtask(() => _handleUnauthorized());
    }

    // Filtered items based on search query
    final filteredItems = _filterItems(foodItemsState.items, _searchQuery);

    return Scaffold(
      appBar: AppHeader(
        title: 'Stok Makanan',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _syncNotifications,
            tooltip: 'Sinkronkan Notifikasi',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari item...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: _handleSearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // All Tab - menampilkan semua makanan
                        _buildFoodItemsList(foodItemsState, filteredItems),

                        // Safe Tab - hanya menampilkan makanan dengan status active
                        _buildFoodItemsList(
                          foodItemsState,
                          filteredItems.where((item) {
                            final uiStatus = item.getUIStatus();
                            debugPrint(
                              '🔍 Filtering: ${item.name}, UI Status: $uiStatus, API Status: ${item.status}, Match: ${uiStatus == 'safe'}',
                            );
                            return uiStatus == 'safe';
                          }).toList(),
                        ),

                        // Warning Tab - hanya menampilkan makanan dengan status expiring_soon
                        _buildFoodItemsList(
                          foodItemsState,
                          filteredItems
                              .where((item) => item.getUIStatus() == 'warning')
                              .toList(),
                        ),

                        // Expired Tab - hanya menampilkan makanan dengan status expired
                        _buildFoodItemsList(
                          foodItemsState,
                          filteredItems
                              .where((item) => item.getUIStatus() == 'expired')
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFoodItemsList(
    FoodItemsData foodItemsState,
    List<FoodItem> items,
  ) {
    // Debug the filtered items
    String currentTab = "unknown";
    if (_tabController.index == 0)
      currentTab = "All";
    else if (_tabController.index == 1)
      currentTab = "Safe/Aman";
    else if (_tabController.index == 2)
      currentTab = "Warning/Segera";
    else if (_tabController.index == 3)
      currentTab = "Expired/Kadaluarsa";

    debugPrint(
      '📊 Building food items list for tab "$currentTab" with ${items.length} items',
    );
    debugPrint('📊 Current provider status: ${foodItemsState.currentStatus}');

    if (_tabController.index == 1) {
      // Extra debug for Aman tab
      debugPrint('🧐 AMAN TAB ITEMS BEING DISPLAYED:');
      for (var item in items) {
        debugPrint(
          '📄 Item in Safe tab: ${item.name}, API Status: ${item.status}, UI Status: ${item.getUIStatus()}',
        );
      }
    }

    if (foodItemsState.state == FoodItemsState.loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty && _searchQuery.length >= 2
                  ? 'Tidak ada makanan dengan nama "$_searchQuery"'
                  : 'Belum ada makanan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty && _searchQuery.length >= 2
                  ? 'Coba cari dengan kata kunci yang berbeda'
                  : 'Tambahkan makanan ke stok Anda',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () {
                    _showAddItemDialog(context);
                  },
                  child: const Text('Tambah Item'),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(foodItemsProvider.notifier).refreshFoodItems(limit: 10);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16),
        itemCount: items.length + (foodItemsState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final item = items[index];

          // Determine item status
          final status = _getItemStatus(item);

          return StockItem(
            item: item,
            onEdit: () {
              _showAddItemDialog(context);
            },
          );
        },
        // Load more items when reaching the bottom
        controller:
            ScrollController()..addListener(() {
              if (foodItemsState.items.length < foodItemsState.totalItems &&
                  !foodItemsState.isLoadingMore) {
                ref.read(foodItemsProvider.notifier).loadMore();
              }
            }),
      ),
    );
  }
}
