import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/stock_item.dart';
import '../widgets/add_item_dialog.dart';
import '../providers/food_provider.dart';
import '../models/food_item_model.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }

    // Map tab index to status
    final statuses = ['all', 'active', 'expiring_soon', 'expired'];
    final newStatus = statuses[_tabController.index];

    // Only update if status changed
    if (newStatus != _currentStatus) {
      setState(() {
        _currentStatus = newStatus;
      });

      // Filter items by new status
      ref.read(foodItemsProvider.notifier).filterByStatus(newStatus);
    }
  }

  void _loadItems() {
    ref.read(foodItemsProvider.notifier).fetchFoodItems(status: _currentStatus);
  }

  void _searchItems() {
    if (_searchQuery.isNotEmpty) {
      ref.read(foodItemsProvider.notifier).searchItems(_searchQuery);
    } else {
      _loadItems();
    }
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddItemDialog());
  }

  @override
  Widget build(BuildContext context) {
    // Watch the food items provider
    final foodItemsData = ref.watch(foodItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stok Makanan')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (_) => _searchItems(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchItems,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            controller: _tabController,
            tabs: const [
              Tab(text: 'Semua'),
              Tab(
                child: Text('Aman', style: TextStyle(color: Color(0xFF22C55E))),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        child: const Icon(Icons.add),
      ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada item',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan item pertama Anda',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddItemDialog(context),
              child: const Text('Tambah Item'),
            ),
          ],
        ),
      );
    }

    // Show list of items
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(foodItemsProvider.notifier).refreshFoodItems();
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
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
            return StockItem(
              item: item,
              onEdit: () {
                // Handle edit (implement later)
              },
            );
          },
        ),
      ),
    );
  }
}
