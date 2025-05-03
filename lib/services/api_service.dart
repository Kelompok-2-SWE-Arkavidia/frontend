import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../models/food_item_model.dart';
import '../models/receipt_item.dart';
import 'storage_service.dart';
import 'auth_handler_service.dart';

class ApiService {
  static const String baseUrl = 'http://103.196.154.75:3000/';
  final StorageService _storageService = StorageService();
  final AuthHandlerService _authHandlerService = AuthHandlerService();

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
        // Login failed - use a user-friendly message
        String errorMessage = responseData['message'] ?? 'Login gagal';

        // Replace technical error messages with user-friendly ones
        if (errorMessage.contains('Unauthorized') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('Failed to process request')) {
          errorMessage =
              'Email atau kata sandi salah. Silakan periksa dan coba lagi.';
        }

        return {'success': false, 'message': errorMessage};
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

      final responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);

      // Check for unauthorized response first
      if (response.statusCode == 401) {
        // Unauthorized - token invalid or expired
        debugPrint('🚨 Unauthorized response detected (401)');

        // Use the auth handler service to handle the unauthorized status
        final message =
            responseData['message'] ?? 'Sesi habis. Silakan login kembali.';
        _authHandlerService.handleUnauthorized(message);

        return {'success': false, 'message': message, 'unauthorized': true};
      }

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

      return _handleApiResponse(response, 'Gagal memperoleh profil');
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

      return _handleApiResponse(response, 'Gagal menambahkan item makanan');
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

  // Delete a food item - protected endpoint (token needed)
  Future<Map<String, dynamic>> deleteFoodItem(String itemId) async {
    final endpoint = 'api/v1/food-items/$itemId';
    try {
      final headers = await _getAuthHeaders();

      _logRequest('DELETE', endpoint, headers);

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      // Handle response appropriately even if it's empty
      String responseBody = response.body.isEmpty ? '{}' : response.body;
      final Map<String, dynamic> responseData =
          response.body.isEmpty
              ? {'message': 'Makanan berhasil dihapus'}
              : jsonDecode(responseBody);

      _logResponse('DELETE', endpoint, response.statusCode, responseData);

      return _handleApiResponse(response, 'Gagal menghapus makanan');
    } catch (e) {
      debugPrint('❌ Delete food item error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat menghapus makanan. Silakan coba lagi.',
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

      final responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);

      // Check for unauthorized response first
      if (response.statusCode == 401) {
        // Unauthorized - token invalid or expired
        debugPrint('🚨 Unauthorized response detected (401)');

        // Use the auth handler service to handle the unauthorized status
        final message =
            responseData['message'] ?? 'Sesi habis. Silakan login kembali.';
        _authHandlerService.handleUnauthorized(message);

        return {'success': false, 'message': message, 'unauthorized': true};
      }

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

  // Detect food age from image
  Future<Map<String, dynamic>> detectFoodAge(File imageFile) async {
    try {
      debugPrint('🔍 Detecting food age from image');

      // Check if the file exists
      if (!imageFile.existsSync()) {
        debugPrint('❌ Image file does not exist: ${imageFile.path}');
        return {'success': false, 'message': 'File gambar tidak ditemukan.'};
      }

      // Check file size
      final fileSize = await imageFile.length();
      debugPrint('📊 Image file size: $fileSize bytes');

      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        debugPrint('❌ Image file too large: $fileSize bytes');
        return {
          'success': false,
          'message': 'Ukuran gambar terlalu besar. Maksimum 10MB.',
        };
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}api/v1/food-items/detect-age'),
      );

      // Get auth headers but remove content-type as it will be set by multipart
      final authHeaders = await _getAuthHeaders();
      // Remove content-type header as it will be set automatically for multipart request
      authHeaders.remove('Content-Type');
      request.headers.addAll(authHeaders);

      // Add file to request
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      // Get file extension and determine MIME type
      final String fileName = imageFile.path.split('/').last;
      final String mimeType = _getMimeType(fileName);
      debugPrint('📊 Using MIME type: $mimeType for file: $fileName');

      final multipartFile = http.MultipartFile(
        'image', // This should match the field name expected by your API
        fileStream,
        fileLength,
        filename: fileName,
        contentType: MediaType.parse(mimeType), // Specify the correct MIME type
      );

      request.files.add(multipartFile);

      // Log the request
      _logRequest(
        'POST',
        'api/v1/food-items/detect-age',
        request.headers,
        body: 'Image file: ${imageFile.path}, size: ${fileLength} bytes',
      );

      // Send the request with timeout
      debugPrint('🔄 Sending food age detection request...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Food age detection request timed out');
          throw TimeoutException('Permintaan melebihi batas waktu');
        },
      );

      debugPrint(
        '✅ Received response with status: ${streamedResponse.statusCode}',
      );
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      try {
        final responseData = jsonDecode(response.body);
        _logResponse(
          'POST',
          'api/v1/food-items/detect-age',
          response.statusCode,
          responseData,
        );

        // Check for specific MIME type error in Gemini API response
        if (response.statusCode == 400 &&
            responseData['error']?.toString().contains('mimeType') == true) {
          debugPrint('❌ MIME type error detected in Gemini API response');
          return {
            'success': false,
            'message':
                'Format gambar tidak didukung. Coba dengan format gambar lain seperti JPEG atau PNG.',
          };
        }

        return _handleApiResponse(response, 'Failed to detect food age');
      } catch (e) {
        debugPrint('❌ Error parsing response: $e');
        debugPrint('❌ Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Format respons tidak valid dari server.',
        };
      }
    } on TimeoutException {
      debugPrint('❌ Food age detection request timed out');
      return {
        'success': false,
        'message':
            'Permintaan kehabisan waktu. Silakan coba lagi dengan koneksi yang lebih stabil.',
      };
    } catch (e) {
      debugPrint('❌ Detect food age error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat menganalisis makanan. Silakan coba lagi.',
      };
    }
  }

  // Helper method to handle API response and check for unauthorized status
  Map<String, dynamic> _handleApiResponse(
    http.Response response,
    String errorMessage,
  ) {
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      debugPrint('🔍 API Response data structure: $responseData');

      // For food detection API specifically
      if (response.request?.url.toString().contains('detect-age') == true) {
        debugPrint('🔍 Detailed food detection response: $responseData');

        // If the data is directly in the responseData
        if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map && data.containsKey('foodType')) {
            debugPrint('🍎 Found foodType: ${data['foodType']}');
          } else {
            debugPrint('⚠️ No foodType in data: $data');
          }
        } else {
          debugPrint('⚠️ No data field in response');
        }
      }

      return {
        'success': true,
        'data': responseData['data'],
        'message': responseData['message'] ?? 'Berhasil',
      };
    } else if (response.statusCode == 401) {
      // Unauthorized - Token invalid or expired
      debugPrint('🚨 Unauthorized response detected (401)');

      // Use the auth handler service to handle the unauthorized status
      final message =
          responseData['message'] ?? 'Sesi habis. Silakan login kembali.';
      _authHandlerService.handleUnauthorized(message);

      return {'success': false, 'message': message, 'unauthorized': true};
    } else {
      // Other errors
      return {
        'success': false,
        'message': responseData['message'] ?? errorMessage,
      };
    }
  }

  // Additional global response handling method
  Future<Map<String, dynamic>> _processApiResponse(
    http.Response response,
    String endpoint,
    String errorMessage,
  ) async {
    final Map<String, dynamic> responseData = jsonDecode(response.body);
    _logResponse('GET', endpoint, response.statusCode, responseData);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success
      return {
        'success': true,
        'data': responseData['data'],
        'message': responseData['message'] ?? 'Berhasil',
      };
    } else if (response.statusCode == 401) {
      // Unauthorized - token invalid or expired
      debugPrint('🚨 Unauthorized response detected (401)');

      // Use the auth handler service to handle the unauthorized status
      final message =
          responseData['message'] ?? 'Sesi habis. Silakan login kembali.';
      _authHandlerService.handleUnauthorized(message);

      return {'success': false, 'message': message, 'unauthorized': true};
    } else {
      // Failed
      return {
        'success': false,
        'message': responseData['message'] ?? errorMessage,
      };
    }
  }

  // Get dashboard statistics - protected endpoint (token needed)
  Future<http.Response> get({required String endpoint}) async {
    final headers = await _getAuthHeaders();

    _logRequest('GET', endpoint, headers);

    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);
    } else {
      debugPrint('❌ GET request failed: ${response.statusCode}');
    }

    return response;
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    const endpoint = 'api/v1/food-items/dashboard';
    try {
      final headers = await _getAuthHeaders();

      _logRequest('GET', endpoint, headers);

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _processApiResponse(
        response,
        endpoint,
        'Gagal memperoleh statistik',
      );
    } catch (e) {
      debugPrint('❌ Get dashboard stats error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat mengambil statistik. Silakan coba lagi.',
      };
    }
  }

  // Helper method to determine MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg'; // Default to JPEG if unknown
    }
  }

  // Resend email verification link
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    const endpoint = 'api/v1/users/resend-verification';
    try {
      final headers = _getPublicHeaders();
      final body = {'email': email};

      _logRequest('POST', endpoint, headers, body: body);

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('POST', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successfully resent verification email
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Email verifikasi berhasil dikirim ulang',
        };
      } else {
        // Failed to resend
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Gagal mengirim ulang email verifikasi',
        };
      }
    } catch (e) {
      debugPrint('❌ Resend verification error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat mengirim email verifikasi. Silakan coba lagi.',
      };
    }
  }

  // Check email verification status
  Future<Map<String, dynamic>> checkEmailVerificationStatus(
    String email,
  ) async {
    final endpoint = 'api/v1/users/verification-status?email=$email';
    try {
      final headers = _getPublicHeaders();

      _logRequest('GET', endpoint, headers);

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successfully checked status
        return {
          'success': true,
          'isVerified': responseData['isVerified'] ?? false,
          'message':
              responseData['message'] ?? 'Status verifikasi berhasil diperiksa',
        };
      } else {
        // Failed to check status
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Gagal memeriksa status verifikasi email',
        };
      }
    } catch (e) {
      debugPrint('❌ Check verification status error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat memeriksa status verifikasi. Silakan coba lagi.',
      };
    }
  }

  // Verify email with token from callback URL
  Future<Map<String, dynamic>> verifyEmailWithToken(String token) async {
    final endpoint = 'api/v1/users/verify?token=$token';
    try {
      final headers = _getPublicHeaders();

      _logRequest('GET', endpoint, headers);

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _logResponse('GET', endpoint, response.statusCode, responseData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successfully verified email
        final data = responseData['data'] ?? {};
        final isVerified = data['is_verified'] ?? false;
        final email = data['email'] ?? '';

        return {
          'success': true,
          'isVerified': isVerified,
          'email': email,
          'message': responseData['message'] ?? 'Email berhasil diverifikasi',
        };
      } else {
        // Failed to verify
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memverifikasi email',
        };
      }
    } catch (e) {
      debugPrint('❌ Verify email with token error: $e');
      return {
        'success': false,
        'message':
            'Terjadi kesalahan saat verifikasi email. Silakan coba lagi.',
      };
    }
  }

  // Food receipt scanning endpoint - upload receipt image to extract food items
  Future<Map<String, dynamic>> scanFoodReceipt(File imageFile) async {
    const endpoint = 'api/v1/food-items/receipt-scan';
    try {
      debugPrint('📸 Sending receipt image for OCR processing');

      // Get auth headers
      final token = await _getAuthToken();

      // Filename dan MIME type
      final fileName = imageFile.path.split('/').last;
      final mimeType = _getMimeType(fileName);

      debugPrint('📤 File path: ${imageFile.path}');
      debugPrint('📤 Filename: $fileName');
      debugPrint('📤 MIME type: $mimeType');

      // Persiapkan headers
      final Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Coba dengan beberapa nama field yang berbeda secara berurutan
      final fieldNames = [
        'receipt_image',
        'file',
        'image',
        'receipt',
        'img',
        'fileUpload',
      ];

      // Loop through multiple attempts with different field names
      for (int i = 0; i < fieldNames.length; i++) {
        final fieldName = fieldNames[i];
        debugPrint('📤 Attempt #${i + 1}: Using field name: $fieldName');

        // Create multipart request for current attempt
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl$endpoint'),
        );

        // Add headers
        request.headers.addAll(headers);

        // Tambahkan field tambahan yang mungkin diharapkan API
        request.fields['type'] = 'receipt'; // Tipe gambar yang diupload

        // Add file to request
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();

        // Jika ini percobaan pertama, tetap gunakan MIME type dari file
        // Jika tidak, coba dengan Content-Type yang lebih umum seperti
        // multipart/form-data atau application/octet-stream
        MediaType contentType;
        if (i == 0) {
          contentType = MediaType.parse(mimeType);
        } else if (i == 1) {
          // Untuk percobaan kedua, gunakan MIME type untuk semua JPEG
          contentType = MediaType('image', 'jpeg');
        } else {
          // Untuk percobaan selanjutnya, gunakan MIME type yang lebih umum
          contentType = MediaType('application', 'octet-stream');
        }

        final multipartFile = http.MultipartFile(
          fieldName,
          fileStream,
          fileLength,
          filename: fileName,
          contentType: contentType,
        );

        request.files.add(multipartFile);

        // Log request details
        debugPrint(
          '📤 Uploading receipt image (${fileLength / 1024} KB) with field: $fieldName',
        );
        debugPrint('🔗 Endpoint: $baseUrl$endpoint');
        debugPrint('📋 Headers: ${request.headers}');
        debugPrint('📋 ContentType: ${contentType.mimeType}');

        try {
          // Send the request
          final streamedResponse = await request.send().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

          final response = await http.Response.fromStream(streamedResponse);

          // Check for unauthorized response
          if (response.statusCode == 401) {
            final responseData = jsonDecode(response.body);
            final message =
                responseData['message'] ?? 'Sesi habis. Silakan login kembali.';
            _authHandlerService.handleUnauthorized(message);
            return {'success': false, 'message': message};
          }

          final Map<String, dynamic> responseData = jsonDecode(response.body);
          _logResponse('POST', endpoint, response.statusCode, responseData);

          if (response.statusCode >= 200 && response.statusCode < 300) {
            // Receipt scan successful
            debugPrint('✅ Receipt scan successful with field: $fieldName');
            return {
              'success': true,
              'data': responseData['data'],
              'message': 'Gambar berhasil diproses',
            };
          } else if (response.statusCode == 400 &&
              responseData.containsKey('error') &&
              responseData['error'] != null &&
              responseData['error'].toString().contains(
                'there is no uploaded file',
              )) {
            // No file found with this field name, try next one
            debugPrint(
              '⚠️ Field name "$fieldName" didn\'t work, trying next one...',
            );
            continue;
          } else {
            // Other error, return immediately
            debugPrint(
              '❌ Receipt scan failed with field "$fieldName": ${response.statusCode} ${response.body}',
            );
            return {
              'success': false,
              'message':
                  responseData['message'] ?? 'Gagal memproses gambar struk',
              'error': responseData['error'] ?? '',
            };
          }
        } catch (e) {
          // Only throw if this is the last field attempt
          if (i == fieldNames.length - 1) {
            throw e; // Rethrow to be caught by outer try-catch
          }

          debugPrint(
            '⚠️ Error with field "$fieldName": $e - trying next field name',
          );
          continue;
        }
      }

      // If we've tried all field names and none worked
      return {
        'success': false,
        'message':
            'Gagal memproses gambar struk setelah mencoba semua opsi field.',
      };
    } catch (e) {
      debugPrint('❌ Receipt scan error: $e');
      String errorMessage = 'Terjadi kesalahan saat memproses gambar.';

      if (e is TimeoutException) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else if (e is SocketException) {
        errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // Method to scan a receipt and get parsed items
  Future<Map<String, dynamic>> scanReceipt(String receiptImagePath) async {
    // This is a placeholder for actual implementation
    // In a real app, you would upload the image file to your API

    final response = await http.post(
      Uri.parse('$baseUrl/receipts/scan'),
      headers: _getPublicHeaders(),
      body: jsonEncode({'image_path': receiptImagePath}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to scan receipt: ${response.body}');
    }
  }

  // Method to add receipt items to the user's inventory
  Future<void> addReceiptItems(String scanId, List<ReceiptItem> items) async {
    final response = await http.post(
      Uri.parse('$baseUrl/receipts/$scanId/confirm'),
      headers: _getPublicHeaders(),
      body: jsonEncode({'items': items.map((item) => item.toJson()).toList()}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add receipt items: ${response.body}');
    }
  }

  // Method to parse the receipt scan response and convert to ReceiptItem list
  static List<ReceiptItem> parseReceiptItems(Map<String, dynamic> response) {
    try {
      // Pastikan response dan data tidak null
      if (response == null ||
          !response.containsKey('data') ||
          response['data'] == null) {
        debugPrint('❌ Invalid response format: missing data field');
        return [];
      }

      final data = response['data'];

      // Pastikan items array ada
      if (!data.containsKey('items') || data['items'] == null) {
        debugPrint('❌ Invalid data format: missing items array');
        return [];
      }

      final items = data['items'] as List;
      debugPrint('✅ Parsing ${items.length} receipt items');

      // Konversi tiap item dari JSON ke model ReceiptItem
      return items
          .map((item) {
            try {
              return ReceiptItem.fromJson(item);
            } catch (e) {
              debugPrint('❌ Error parsing receipt item: $e');
              debugPrint('❌ Problematic item data: $item');
              // Return null untuk item yang gagal di-parse
              return null;
            }
          })
          .where((item) => item != null)
          .cast<ReceiptItem>()
          .toList();
    } catch (e) {
      debugPrint('❌ Error in parseReceiptItems: $e');
      return [];
    }
  }
}
