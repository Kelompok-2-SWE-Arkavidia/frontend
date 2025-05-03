import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';

class StorageService {
  static const String _foodItemsKey = 'foodItems';
  static const String _userKey = 'user';
  static const String _tokenKey = 'token';

  // Save a food item
  Future<void> saveFoodItem(FoodItem item) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing food items
    final List<FoodItem> items = await getFoodItems();

    // Check if item already exists
    final existingIndex = items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      // Update existing item
      items[existingIndex] = item;
    } else {
      // Add new item
      items.add(item);
    }

    // Save all items
    await _saveFoodItems(items);
  }

  // Get all food items
  Future<List<FoodItem>> getFoodItems() async {
    final prefs = await SharedPreferences.getInstance();

    // Get stored JSON string
    final String itemsJsonString = prefs.getString(_foodItemsKey) ?? '[]';

    // Parse the JSON string into a List
    final List<dynamic> itemsJson = jsonDecode(itemsJsonString);

    // Convert to list of food items
    return itemsJson.map((json) => FoodItem.fromJson(json)).toList();
  }

  // Delete a food item
  Future<void> deleteFoodItem(String id) async {
    // Get existing food items
    final List<FoodItem> items = await getFoodItems();

    // Remove item with matching ID
    items.removeWhere((item) => item.id == id);

    // Save updated list
    await _saveFoodItems(items);
  }

  // Helper to save the full list of food items
  Future<void> _saveFoodItems(List<FoodItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert items to JSON array string
    final String itemsJsonString = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );

    // Save to SharedPreferences
    await prefs.setString(_foodItemsKey, itemsJsonString);
  }

  // Get food items sorted by expiry date (earliest first)
  Future<List<FoodItem>> getFoodItemsSortedByExpiry() async {
    final items = await getFoodItems();
    items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return items;
  }

  // Get expired food items
  Future<List<FoodItem>> getExpiredFoodItems() async {
    final items = await getFoodItems();
    final now = DateTime.now();
    return items.where((item) => item.expiryDate.isBefore(now)).toList();
  }

  // Get food items that will expire soon (within the next 3 days)
  Future<List<FoodItem>> getExpiringFoodItems() async {
    final items = await getFoodItems();
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));

    return items.where((item) {
      return item.expiryDate.isAfter(now) &&
          item.expiryDate.isBefore(threeDaysLater);
    }).toList();
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    debugPrint('💾 StorageService: Saving user data to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
    debugPrint('✅ StorageService: User data saved successfully');
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    debugPrint(
      '🔍 StorageService: Retrieving user data from SharedPreferences',
    );
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      final userData = jsonDecode(userString) as Map<String, dynamic>;
      debugPrint('✅ StorageService: User data retrieved successfully');
      return userData;
    }
    debugPrint('ℹ️ StorageService: No user data found');
    return null;
  }

  // Save authentication token
  Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      debugPrint('ℹ️ StorageService: Empty token provided, clearing token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      return;
    }

    debugPrint('🔑 StorageService: Saving auth token to SharedPreferences');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    debugPrint('✅ StorageService: Token saved successfully');
  }

  // Get authentication token
  Future<String?> getToken() async {
    debugPrint(
      '🔍 StorageService: Retrieving auth token from SharedPreferences',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null && token.isNotEmpty) {
      debugPrint('✅ StorageService: Token retrieved successfully');
      return token;
    }

    debugPrint('ℹ️ StorageService: No valid token found');
    return null;
  }

  // Clear user authentication data (for logout)
  Future<void> clearAuthData() async {
    debugPrint('🗑️ StorageService: Clearing all authentication data');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    debugPrint('✅ StorageService: Auth data cleared successfully');
  }

  // Reset only the authentication data while keeping onboarding state
  Future<void> resetOnlyAuthData() async {
    debugPrint(
      '🔄 StorageService: Resetting only auth data, keeping onboarding state',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    debugPrint(
      '✅ StorageService: Auth data reset successfully, onboarding state preserved',
    );
  }

  // Check if token exists and is valid (not empty)
  Future<bool> hasValidToken() async {
    final token = await getToken();
    final isValid = token != null && token.isNotEmpty;
    debugPrint('🔍 StorageService: Token validity check: $isValid');
    return isValid;
  }
}
