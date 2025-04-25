import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/food_item_model.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://103.196.154.75:3000/';
  final StorageService _storageService = StorageService();

  // Helper method to log API requests
  void _logRequest(
    String method,
    String endpoint,
    Map<String, String> headers, {
    dynamic body,
  }) {
    debugPrint('=== API REQUEST ===');
    debugPrint('📲 $method: ${baseUrl + endpoint}');
    debugPrint('📋 Headers: $headers');
    if (body != null) {
      debugPrint('📦 Body: $body');
    }
    debugPrint('=================');
  }

  // Helper method to log API responses
  void _logResponse(
    String method,
    String endpoint,
    int statusCode,
    dynamic responseData,
  ) {
    debugPrint('=== API RESPONSE ===');
    debugPrint('📲 $method: ${baseUrl + endpoint}');
    debugPrint('📊 Status: $statusCode');
    debugPrint('📋 Response: $responseData');
    debugPrint('===================');
  }

  // Get auth token from storage
  Future<String?> _getAuthToken() async {
    final token = await _storageService.getToken();
    debugPrint(
      '🔑 Auth Token: ${token != null ? "${token.substring(0, 10)}..." : "null"}',
    );
    return token;
  }

  // Create headers with auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    return headers;
  }

  // Create common headers for public endpoints (no token)
  Map<String, String> _getPublicHeaders() {
    return {'Content-Type': 'application/json'};
  }

  // User registration endpoint - public endpoint (no token needed)
  Future<Map<String, dynamic>> registerUser(User user) async {
    const endpoint = 'api/v1/users/register';
    try {
      final headers = _getPublicHeaders();
      final body = user.toJson();

      _logRequest('POST', endpoint, headers, body: body);

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('POST', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Registration successful
        return {
          'success': true,
          'data': responseData,
          'message': 'Registrasi berhasil',
        };
      } else {
        // Registration failed
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mendaftar. Silakan coba lagi.',
      };
    }
  }

  // User login endpoint - public endpoint (no token needed)
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    const endpoint = 'api/v1/users/login';
    try {
      final headers = _getPublicHeaders();
      final body = {'email': email, 'password': password};

      _logRequest('POST', endpoint, headers, body: body);

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('POST', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Login successful
        return {
          'success': true,
          'data': responseData['data'],
          'message': 'Login berhasil',
        };
      } else {
        // Login failed
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat login. Silakan coba lagi.',
      };
    }
  }

  // Fetch food items with pagination and filters - protected endpoint (token needed)
  Future<Map<String, dynamic>> getFoodItems({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    // Konversi status parameter untuk API
    String apiStatus = status;
    if (status == 'active') {
      apiStatus = 'Safe';
      debugPrint('🔄 API Call: Converting status "active" to "Safe" for API');
    } else if (status == 'expiring_soon') {
      apiStatus = 'Warning';
      debugPrint(
        '🔄 API Call: Converting status "expiring_soon" to "Warning" for API',
      );
    } else if (status == 'expired') {
      apiStatus = 'Expired';
      debugPrint(
        '🔄 API Call: Converting status "expired" to "Expired" for API',
      );
    }

    final endpoint =
        'api/v1/food-items?status=$apiStatus&page=$page&limit=$limit';
    debugPrint(
      '🔄 API Call: Requesting food items with status: $apiStatus (original: $status), page: $page, limit: $limit',
    );
    try {
      final headers = await _getAuthHeaders();

      _logRequest('GET', endpoint, headers);

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse response structure sesuai format API
        final data = responseData['data'] as Map<String, dynamic>;

        // Ekstrak items dan pagination dengan handling untuk null values
        final items =
            data['items'] ?? []; // Handle null items by using empty list
        final pagination = data['pagination'] as Map<String, dynamic>;

        debugPrint(
          '🔍 Parsed response - items: ${items == null ? "null" : "array with ${(items as List).length} items"}',
        );
        debugPrint('🔍 Pagination: $pagination');

        // Convert ke list FoodItem - handle null case
        List<FoodItem> foodItems = [];
        if (items != null) {
          foodItems =
              (items as List).map((item) => FoodItem.fromJson(item)).toList();
        }

        // Additional debug for status filtering
        if (status == 'active') {
          debugPrint('🔍 CHECKING RETURNED ACTIVE ITEMS:');
          int activeApiCount = 0;
          int safeMappedCount = 0;

          for (var item in foodItems) {
            if (item.status.toLowerCase() == 'active') {
              activeApiCount++;
            }
            if (item.getUIStatus() == 'safe') {
              safeMappedCount++;
            }
            debugPrint(
              '📄 Item: ${item.name}, API status: ${item.status}, UI status: ${item.getUIStatus()}',
            );
          }

          debugPrint('📊 Active API status count: $activeApiCount');
          debugPrint('📊 Safe UI status count: $safeMappedCount');
        }

        return {
          'success': true,
          'data': foodItems,
          'totalItems': pagination['total'] ?? 0,
          'totalPages': pagination['total_pages'] ?? 1,
          'currentPage': pagination['page'] ?? 1,
          'message':
              responseData['message'] ?? 'Data makanan berhasil diperoleh',
        };
      } else if (response.statusCode == 401) {
        // Unauthorized - token invalid or expired
        return {
          'success': false,
          'message': 'Sesi habis. Silakan login kembali.',
          'unauthorized': true,
        };
      } else {
        // Failed
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memperoleh data makanan',
        };
      }
    } catch (e) {
      debugPrint('❌ Get food items error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat mengambil data makanan. Silakan coba lagi.',
      };
    }
  }

  // Get user profile - protected endpoint (token needed)
  Future<Map<String, dynamic>> getUserProfile() async {
    const endpoint = 'api/v1/users/profile';
    try {
      final headers = await _getAuthHeaders();

      _logRequest('GET', endpoint, headers);

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        return {
          'success': true,
          'data': responseData,
          'message': 'Profil berhasil diperoleh',
        };
      } else if (response.statusCode == 401) {
        // Unauthorized - token invalid or expired
        return {
          'success': false,
          'message': 'Sesi habis. Silakan login kembali.',
          'unauthorized': true,
        };
      } else {
        // Failed
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memperoleh profil',
        };
      }
    } catch (e) {
      debugPrint('❌ Get user profile error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat mengambil profil. Silakan coba lagi.',
      };
    }
  }

  // Add a food item - protected endpoint (token needed)
  Future<Map<String, dynamic>> addFoodItem(FoodItem item) async {
    const endpoint = 'api/v1/food-items';
    try {
      final headers = await _getAuthHeaders();
      // Ensure Content-Type is set to application/json
      headers['Content-Type'] = 'application/json';

      // Get the item as JSON
      final body = item.toJson();

      // Log the request details
      _logRequest('POST', endpoint, headers, body: body);

      debugPrint('🔄 Adding food item to API: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      // Try to parse the response body
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
        _logResponse('POST', endpoint, response.statusCode, responseData);
      } catch (e) {
        debugPrint('❌ Failed to parse API response: ${response.body}');
        debugPrint('❌ Parse error: $e');
        responseData = {
          'message': 'Failed to parse server response: ${response.body}',
        };
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Successfully added food item to API');
        // Success
        return {
          'success': true,
          'data': responseData,
          'message':
              responseData['message'] ?? 'Item makanan berhasil ditambahkan',
        };
      } else if (response.statusCode == 401) {
        debugPrint('🔒 Unauthorized error when adding food item');
        // Unauthorized - token invalid or expired
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Sesi habis. Silakan login kembali.',
          'unauthorized': true,
        };
      } else {
        debugPrint(
          '❌ Error adding food item, status: ${response.statusCode}, message: ${responseData['message'] ?? "No message"}, raw response: ${response.body}',
        );
        // Failed
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal menambahkan item makanan',
          'error_code': response.statusCode,
          'raw_response': response.body,
        };
      }
    } catch (e) {
      debugPrint('❌ Exception in addFoodItem: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat menambahkan item. Silakan coba lagi.',
        'error': e.toString(),
      };
    }
  }

  // Update a food item
  Future<Map<String, dynamic>> updateFoodItem(String id, FoodItem item) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('${baseUrl}api/v1/food-items/$id'),
        headers: headers,
        body: jsonEncode(item.toJson()),
      );

      return _handleApiResponse(response, 'Gagal memperbarui item makanan');
    } catch (e) {
      debugPrint('Update food item error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat memperbarui item. Silakan coba lagi.',
      };
    }
  }

  // Delete a food item
  Future<Map<String, dynamic>> deleteFoodItem(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('${baseUrl}api/v1/food-items/$id'),
        headers: headers,
      );

      return _handleApiResponse(response, 'Gagal menghapus item makanan');
    } catch (e) {
      debugPrint('Delete food item error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat menghapus item. Silakan coba lagi.',
      };
    }
  }

  // Get food recipes
  Future<Map<String, dynamic>> getFoodRecipes({
    String query = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '${baseUrl}api/v1/recipes?query=$query&page=$page&limit=$limit',
        ),
        headers: headers,
      );

      return _handleApiResponse(response, 'Gagal memperoleh resep makanan');
    } catch (e) {
      debugPrint('Get recipes error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengambil resep. Silakan coba lagi.',
      };
    }
  }

  // Get donation opportunities
  Future<Map<String, dynamic>> getDonationOpportunities({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${baseUrl}api/v1/donations?page=$page&limit=$limit'),
        headers: headers,
      );

      return _handleApiResponse(response, 'Gagal memperoleh informasi donasi');
    } catch (e) {
      debugPrint('Get donations error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat mengambil data donasi. Silakan coba lagi.',
      };
    }
  }

  // Search food items - protected endpoint (token needed)
  Future<Map<String, dynamic>> searchFoodItems({
    required String keyword,
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    // Konversi status parameter untuk API
    String apiStatus = status;
    if (status == 'active') {
      apiStatus = 'Safe';
      debugPrint(
        '🔄 API Call: Converting status "active" to "Safe" for search',
      );
    } else if (status == 'expiring_soon') {
      apiStatus = 'Warning';
      debugPrint(
        '🔄 API Call: Converting status "expiring_soon" to "Warning" for search',
      );
    } else if (status == 'expired') {
      apiStatus = 'Expired';
      debugPrint(
        '🔄 API Call: Converting status "expired" to "Expired" for search',
      );
    }

    final endpoint =
        'api/v1/food-items/search?q=${Uri.encodeComponent(keyword)}&status=$apiStatus&page=$page&limit=$limit';

    try {
      final headers = await _getAuthHeaders();

      _logRequest('GET', endpoint, headers);

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse response structure sesuai format API
        final data = responseData['data'] as Map<String, dynamic>;

        // Ekstrak items dan pagination dengan handling untuk null values
        final items =
            data['items'] ?? []; // Handle null items by using empty list
        final pagination = data['pagination'] as Map<String, dynamic>;

        debugPrint(
          '🔍 Search results - items: ${items == null ? "null" : "array with ${(items as List).length} items"}',
        );
        debugPrint('🔍 Pagination: $pagination');

        // Convert ke list FoodItem - handle null case
        List<FoodItem> foodItems = [];
        if (items != null) {
          foodItems =
              (items as List).map((item) => FoodItem.fromJson(item)).toList();
        }

        return {
          'success': true,
          'data': foodItems,
          'totalItems': pagination['total'] ?? 0,
          'totalPages': pagination['total_pages'] ?? 1,
          'currentPage': pagination['page'] ?? 1,
          'message': responseData['message'] ?? 'Pencarian makanan berhasil',
        };
      } else if (response.statusCode == 401) {
        // Unauthorized - token invalid or expired
        return {
          'success': false,
          'message': 'Sesi habis. Silakan login kembali.',
          'unauthorized': true,
        };
      } else {
        // Failed
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mencari makanan',
        };
      }
    } catch (e) {
      debugPrint('❌ Search food items error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mencari makanan. Silakan coba lagi.',
      };
    }
  }

  // Handle API response to standardize error handling
  Map<String, dynamic> _handleApiResponse(
    http.Response response,
    String errorMessage,
  ) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      return {
        'success': true,
        'data': responseData,
        'message': responseData['message'] ?? 'Berhasil',
      };
    } else if (response.statusCode == 401) {
      // Unauthorized - Token invalid or expired
      return {
        'success': false,
        'message': 'Sesi habis. Silakan login kembali.',
        'unauthorized': true,
      };
    } else {
      // Other errors
      return {
        'success': false,
        'message': responseData['message'] ?? errorMessage,
      };
    }
  }
}
