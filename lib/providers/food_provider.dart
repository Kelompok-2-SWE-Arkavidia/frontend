import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item_model.dart';
import '../services/api_service.dart';

// Food items states
enum FoodItemsState { initial, loading, success, error, unauthorized }

// Food items data class
class FoodItemsData {
  final FoodItemsState state;
  final List<FoodItem> items;
  final String? errorMessage;
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final bool isLoadingMore;
  final String currentStatus;

  FoodItemsData({
    required this.state,
    this.items = const [],
    this.errorMessage,
    this.totalItems = 0,
    this.totalPages = 1,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.currentStatus = 'all',
  });

  // Create a copy with some fields modified
  FoodItemsData copyWith({
    FoodItemsState? state,
    List<FoodItem>? items,
    String? errorMessage,
    int? totalItems,
    int? totalPages,
    int? currentPage,
    bool? isLoadingMore,
    String? currentStatus,
  }) {
    return FoodItemsData(
      state: state ?? this.state,
      items: items ?? this.items,
      errorMessage: errorMessage,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }
}

// Food items notifier
class FoodItemsNotifier extends StateNotifier<FoodItemsData> {
  final ApiService _apiService;

  FoodItemsNotifier(this._apiService)
    : super(FoodItemsData(state: FoodItemsState.initial));

  // Fetch food items
  Future<void> fetchFoodItems({
    String status = 'all',
    bool refresh = false,
    int? limit,
  }) async {
    debugPrint(
      '🔄 Fetching food items - status: $status, refresh: $refresh, limit: $limit',
    );

    // If refreshing or initial load, set state to loading
    if (refresh || state.state == FoodItemsState.initial) {
      state = state.copyWith(
        state: FoodItemsState.loading,
        currentStatus: status,
        currentPage: 1, // Reset page pada refresh
      );
      debugPrint('🔄 Set state to LOADING, status: $status');
    } else {
      // Otherwise, we're loading more data
      state = state.copyWith(isLoadingMore: true, currentStatus: status);
      debugPrint('🔄 Loading more items, current page: ${state.currentPage}');
    }

    try {
      // Reset to page 1 if refreshing
      final page = refresh ? 1 : state.currentPage;
      final itemLimit = limit ?? 20;
      debugPrint('📃 Request page: $page, limit: $itemLimit, status: $status');

      final result = await _apiService.getFoodItems(
        status: status,
        page: page,
        limit: itemLimit,
      );

      if (result['success']) {
        // Success
        final List<FoodItem> foodItems = result['data'];
        final int totalItems = result['totalItems'];
        final int totalPages = result['totalPages'];
        final int currentPage = result['currentPage'];

        debugPrint('✅ Food items fetched successfully');
        debugPrint('📊 Retrieved ${foodItems.length} items');
        debugPrint(
          '📚 Total items: $totalItems, Total pages: $totalPages, Current page: $currentPage',
        );

        // If refreshing, replace items, otherwise append
        final List<FoodItem> updatedItems =
            refresh ? foodItems : [...state.items, ...foodItems];

        state = state.copyWith(
          state: FoodItemsState.success,
          items: updatedItems,
          totalItems: totalItems,
          totalPages: totalPages,
          currentPage: currentPage,
          isLoadingMore: false,
          errorMessage: null,
        );
        debugPrint('✅ State updated with fetched items');
      } else if (result.containsKey('unauthorized') &&
          result['unauthorized'] == true) {
        debugPrint('🔒 Unauthorized access detected');
        state = state.copyWith(
          state: FoodItemsState.unauthorized,
          errorMessage: result['message'],
          isLoadingMore: false,
        );
      } else {
        // Other error
        debugPrint('❌ Error fetching food items: ${result['message']}');
        state = state.copyWith(
          state: FoodItemsState.error,
          errorMessage: result['message'],
          isLoadingMore: false,
        );
      }
    } catch (e) {
      // Handle error
      debugPrint('❌ Exception in fetchFoodItems: $e');
      state = state.copyWith(
        state: FoodItemsState.error,
        errorMessage:
            'Terjadi kesalahan saat mengambil data makanan. Silakan coba lagi.',
        isLoadingMore: false,
      );
    }
  }

  // Add a food item
  Future<Map<String, dynamic>> addFoodItem(FoodItem item) async {
    debugPrint('🔄 Adding food item: ${item.name}');
    try {
      final result = await _apiService.addFoodItem(item);

      if (result['success']) {
        debugPrint('✅ Food item added successfully');
        // Refresh the list with current status
        await refreshFoodItems();
        return result;
      } else if (result.containsKey('unauthorized') &&
          result['unauthorized'] == true) {
        debugPrint('🔒 Unauthorized access detected while adding item');
        state = state.copyWith(
          state: FoodItemsState.unauthorized,
          errorMessage: result['message'],
        );
        return result;
      } else {
        debugPrint('❌ Failed to add food item: ${result['message']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Exception in addFoodItem: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat menambahkan item. Silakan coba lagi.',
      };
    }
  }

  // Load more items (next page)
  Future<void> loadMore() async {
    // Only load more if there are more pages to load
    if (state.currentPage < state.totalPages && !state.isLoadingMore) {
      debugPrint(
        '🔄 Loading more items, current page: ${state.currentPage}, loading next page: ${state.currentPage + 1}',
      );
      state = state.copyWith(
        isLoadingMore: true,
        currentPage: state.currentPage + 1,
      );

      await fetchFoodItems(status: state.currentStatus);
    } else {
      debugPrint('ℹ️ No more pages to load or already loading');
    }
  }

  // Refresh food items
  Future<void> refreshFoodItems({int? limit}) async {
    debugPrint(
      '🔄 Refreshing food items with status: ${state.currentStatus}, limit: $limit',
    );
    await fetchFoodItems(
      status: state.currentStatus,
      refresh: true,
      limit: limit,
    );
  }

  // Filter food items by status
  Future<void> filterByStatus(String status, {int? limit}) async {
    if (status != state.currentStatus) {
      debugPrint(
        '🔍 Filtering items by status: $status (was: ${state.currentStatus}), limit: $limit',
      );

      // Add debug logs to show what will be sent to API
      String apiStatusValue = status;
      if (status == 'active') {
        debugPrint('🔄 Sending API status "Active" for safe items');
      } else if (status == 'expiring_soon') {
        debugPrint('🔄 Sending API status "ExpiringSoon" for warning items');
      } else if (status == 'expired') {
        debugPrint('🔄 Sending API status "Expired" for expired items');
      } else if (status == 'all') {
        debugPrint('🔄 Sending API status "all" for all items');
      }

      // Reset state and fetch new items with the selected status
      state = state.copyWith(
        currentPage: 1,
        items: [], // Clear existing items when changing filter
      );
      await fetchFoodItems(status: status, refresh: true, limit: limit);
    } else {
      debugPrint('ℹ️ Status filter unchanged: $status');
    }
  }

  // Search food items by keyword
  Future<void> searchItems(String keyword) async {
    debugPrint('🔍 Searching for food items with keyword: $keyword');

    // Set state to loading
    state = state.copyWith(state: FoodItemsState.loading, currentPage: 1);

    try {
      final result = await _apiService.searchFoodItems(
        keyword: keyword,
        status: state.currentStatus, // Maintain current status filter
        page: 1,
        limit: 20,
      );

      if (result['success']) {
        // Success
        final List<FoodItem> foodItems = result['data'];
        final int totalItems = result['totalItems'];
        final int totalPages = result['totalPages'];

        debugPrint('✅ Search results fetched successfully');
        debugPrint('📊 Found ${foodItems.length} items matching "$keyword"');

        state = state.copyWith(
          state: FoodItemsState.success,
          items: foodItems,
          totalItems: totalItems,
          totalPages: totalPages,
          currentPage: 1,
          isLoadingMore: false,
          errorMessage: null,
        );
      } else if (result.containsKey('unauthorized') &&
          result['unauthorized'] == true) {
        // Unauthorized
        debugPrint('🔒 Unauthorized access detected during search');
        state = state.copyWith(
          state: FoodItemsState.unauthorized,
          errorMessage: result['message'],
        );
      } else {
        // Other error
        debugPrint('❌ Error searching food items: ${result['message']}');
        state = state.copyWith(
          state: FoodItemsState.error,
          errorMessage: result['message'],
        );
      }
    } catch (e) {
      debugPrint('❌ Exception in searchItems: $e');
      state = state.copyWith(
        state: FoodItemsState.error,
        errorMessage:
            'Terjadi kesalahan saat mencari makanan. Silakan coba lagi.',
      );
    }
  }

  // Delete a food item by ID
  Future<Map<String, dynamic>> deleteFoodItem(String itemId) async {
    debugPrint('🗑️ Deleting food item with ID: $itemId');

    try {
      // Call API to delete the item
      final result = await _apiService.deleteFoodItem(itemId);

      if (result['success']) {
        debugPrint('✅ Food item deleted successfully');

        // Remove the item from state if it exists
        final updatedItems =
            state.items.where((item) => item.id != itemId).toList();

        // Update state with the item removed
        state = state.copyWith(
          items: updatedItems,
          // We don't change the state to success because it might be mid-loading other operations
        );

        // Refresh the list to get updated data
        await refreshFoodItems();

        return result;
      } else if (result.containsKey('unauthorized') &&
          result['unauthorized'] == true) {
        debugPrint('🔒 Unauthorized access detected while deleting item');
        state = state.copyWith(
          state: FoodItemsState.unauthorized,
          errorMessage: result['message'],
        );
        return result;
      } else {
        // Other error
        debugPrint('❌ Failed to delete food item: ${result['message']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Exception in deleteFoodItem: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat menghapus makanan. Silakan coba lagi.',
      };
    }
  }

  // Update food item
  Future<Map<String, dynamic>> updateFoodItem(
    String itemId,
    FoodItem updatedItem,
  ) async {
    debugPrint('🔄 Updating food item: ${updatedItem.name} (ID: $itemId)');
    try {
      final result = await _apiService.updateFoodItem(itemId, updatedItem);

      if (result['success']) {
        debugPrint('✅ Food item updated successfully');

        // Update item in local state if it exists
        final itemIndex = state.items.indexWhere((item) => item.id == itemId);
        if (itemIndex >= 0) {
          final updatedItems = [...state.items];
          updatedItems[itemIndex] = updatedItem.copyWith(
            id: itemId,
          ); // Ensure ID is preserved

          state = state.copyWith(items: updatedItems);
        }

        // Refresh the list to get updated data from server
        await refreshFoodItems();
        return result;
      } else if (result.containsKey('unauthorized') &&
          result['unauthorized'] == true) {
        debugPrint('🔒 Unauthorized access detected while updating item');
        state = state.copyWith(
          state: FoodItemsState.unauthorized,
          errorMessage: result['message'],
        );
        return result;
      } else {
        debugPrint('❌ Failed to update food item: ${result['message']}');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Exception in updateFoodItem: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat memperbarui item. Silakan coba lagi.',
      };
    }
  }

  // Filter items locally based on search query
  void filterItemsLocally(String query) {
    debugPrint('🔍 Filtering items locally with query: $query');

    if (query.isEmpty) {
      // If query is empty, just use the current status filter
      final currentStatus = state.currentStatus;
      filterByStatus(currentStatus);
      return;
    }

    // Start with all items that match the current status filter
    List<FoodItem> baseItems = [];

    // Use the most recent state items as the base for filtering
    baseItems = [...state.items];

    // Apply the search filter
    final lowercaseQuery = query.toLowerCase();
    final filteredItems =
        baseItems.where((item) {
          return item.name.toLowerCase().contains(lowercaseQuery);
        }).toList();

    debugPrint(
      '📊 Found ${filteredItems.length} items matching "$query" locally',
    );

    // Update state with filtered items
    state = state.copyWith(
      state: FoodItemsState.success,
      items: filteredItems,
      isLoadingMore: false,
      errorMessage: null,
    );
  }
}

// API service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Food items provider
final foodItemsProvider =
    StateNotifierProvider<FoodItemsNotifier, FoodItemsData>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return FoodItemsNotifier(apiService);
    });

// Tambahkan provider untuk query pencarian
final searchQueryProvider = StateProvider<String>((ref) => '');

// Tambahkan provider untuk debounced search query yang akan melakukan pencarian otomatis
final debouncedSearchProvider = Provider<String>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);

  // Menambahkan debounce effect (kita tidak bisa langsung mengakses efek di sini)
  // Jadi kita akan menggunakan searchQueryProvider di StockScreen dengan debounce
  return searchQuery;
});

// Provider untuk status filter saat ini
final statusFilterProvider = StateProvider<String>((ref) => 'all');

// Provider for storing all fetched food items (unfiltered)
final allFoodItemsProvider = StateProvider<List<FoodItem>>((ref) => []);
