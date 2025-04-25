import 'package:flutter/foundation.dart';

class FoodItem {
  final String id;
  final String name;
  final DateTime expiryDate;
  final String category;
  final int quantity;
  final String unit;
  final String status;
  final bool isPackaged;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    this.category = '',
    required this.quantity,
    required this.unit,
    required this.status,
    this.isPackaged = false,
    this.userId = '',
    required this.createdAt,
    DateTime? updatedAt,
  }) : this.updatedAt = updatedAt ?? DateTime.now();

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Log the received JSON for debugging
    debugPrint('🔄 Parsing FoodItem from JSON: $json');

    // Get status from API and normalize it
    String normalizedStatus = 'active';
    if (json['status'] != null) {
      String apiStatus = json['status'].toString().toLowerCase();
      // Complete detailed logging of the raw status value
      debugPrint(
        '📊 Raw status from API: "${json['status']}", type: ${json['status'].runtimeType}',
      );

      // API returns "Safe", "Warning", "Expired"
      if (apiStatus.contains('safe')) {
        normalizedStatus = 'active';
        debugPrint('🔑 Status normalized: Safe -> active (safe in UI)');
      } else if (apiStatus.contains('warning')) {
        normalizedStatus = 'expiring_soon';
        debugPrint(
          '🔑 Status normalized: Warning -> expiring_soon (warning in UI)',
        );
      } else if (apiStatus.contains('expire')) {
        normalizedStatus = 'expired';
        debugPrint('🔑 Status normalized: Expired -> expired (expired in UI)');
      }
      debugPrint(
        '📊 Status from API: ${json['status']}, normalized to: $normalizedStatus',
      );
    } else {
      debugPrint('⚠️ No status in API response, defaulting to "active"');
    }

    // Parse expiry date
    DateTime expiryDate;
    try {
      expiryDate =
          json['expiry_date'] != null
              ? DateTime.parse(json['expiry_date'])
              : DateTime.now();
      debugPrint('📅 Expiry date parsed: ${expiryDate.toString()}');
    } catch (e) {
      debugPrint('⚠️ Error parsing expiry date: ${json['expiry_date']}');
      expiryDate = DateTime.now();
    }

    // Create FoodItem with parsed data
    final item = FoodItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      expiryDate: expiryDate,
      category: json['category'] ?? '',
      quantity:
          json['quantity'] != null ? int.parse(json['quantity'].toString()) : 0,
      unit: json['unit_measure'] ?? '',
      // Use normalized status
      status: normalizedStatus,
      isPackaged: json['is_packaged'] ?? false,
      userId: json['user_id'] ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );

    debugPrint(
      '✅ FoodItem created: ${item.name}, status: ${item.status}, calcUI: ${item.getUIStatus()}',
    );
    return item;
  }

  Map<String, dynamic> toJson() {
    // Debug the conversion process
    debugPrint('🔄 Converting FoodItem to JSON for API');

    // Format date as YYYY-MM-DD
    String formattedExpiryDate =
        "${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";
    debugPrint('📅 Formatted expiry date: $formattedExpiryDate');

    final json = {
      // Only include id if it's not empty (for updates)
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'expiry_date':
          formattedExpiryDate, // Use YYYY-MM-DD format that API expects
      'category':
          category.isNotEmpty ? category : 'lainnya', // Always include category
      'quantity': quantity, // Send as integer, not string
      'unit_measure': unit,
      'status': status.isNotEmpty ? status : 'active', // Always include status
      'is_packaged': isPackaged,
    };

    // Add these fields only if needed
    if (userId.isNotEmpty) {
      json['user_id'] = userId;
    }

    debugPrint('📤 Final JSON payload: $json');
    return json;
  }

  // Konversi status API ke format UI
  String getUIStatus() {
    final now = DateTime.now();

    // Debug the status determination process
    debugPrint(
      '🔄 Determining UI status for item: $name, API status: $status, Status type: ${status.runtimeType}',
    );

    // First check the API-provided status - always normalize to lowercase
    String lowercaseStatus = status.toLowerCase();
    debugPrint('📊 Normalized lowercase status: $lowercaseStatus');

    if (lowercaseStatus == 'expired') {
      debugPrint('📊 Using API status: expired');
      return 'expired';
    } else if (lowercaseStatus == 'expiring_soon') {
      debugPrint('📊 Using API status: warning (from expiring_soon)');
      return 'warning';
    } else if (lowercaseStatus == 'active') {
      // Even with 'active' status, verify against expiry date
      if (expiryDate.isBefore(now)) {
        debugPrint(
          '⚠️ Item marked as active but expiry date is past, marking as expired',
        );
        return 'expired';
      } else if (expiryDate.difference(now).inDays <= 3) {
        debugPrint(
          '⚠️ Item marked as active but expiry date is within 3 days, marking as warning',
        );
        return 'warning';
      } else {
        debugPrint('📊 Using API status: safe (from active)');
        return 'safe';
      }
    }

    // Fallback based on expiry date if API status is not recognized
    debugPrint('⚠️ Unrecognized status: $status, using expiry date instead');
    if (expiryDate.isBefore(now)) {
      debugPrint('📅 Expired based on date: ${expiryDate.toString()}');
      return 'expired';
    } else if (expiryDate.difference(now).inDays <= 3) {
      debugPrint(
        '📅 Warning based on date: ${expiryDate.toString()} (${expiryDate.difference(now).inDays} days left)',
      );
      return 'warning';
    } else {
      debugPrint(
        '📅 Safe based on date: ${expiryDate.toString()} (${expiryDate.difference(now).inDays} days left)',
      );
      return 'safe';
    }
  }
}
