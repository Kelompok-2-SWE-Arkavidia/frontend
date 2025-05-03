import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';
import 'auth_handler_service.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  final StorageService _storageService = StorageService();
  final AuthHandlerService _authHandlerService = AuthHandlerService();

  static const String baseUrl = 'http://103.196.154.75:3000/';

  factory OcrService() {
    return _instance;
  }

  OcrService._internal();

  // Get auth token from storage
  Future<String?> _getAuthToken() async {
    final token = await _storageService.getToken();
    return token;
  }

  // Create headers with auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    final headers = {'Authorization': 'Bearer $token'};
    return headers;
  }

  // Process image and extract text using API
  Future<String> processImage(XFile imageFile) async {
    try {
      debugPrint('🔍 Sending image to OCR API');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${baseUrl}api/v1/ocr/process'),
      );

      // Get auth headers
      final authHeaders = await _getAuthHeaders();
      request.headers.addAll(authHeaders);

      // Add file to request
      final fileStream = http.ByteStream(File(imageFile.path).openRead());
      final fileLength = await File(imageFile.path).length();

      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: 'ocr_image.jpg',
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check for unauthorized response
      if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        final message =
            responseData['message'] ?? 'Sesi habis. Silakan login kembali.';
        _authHandlerService.handleUnauthorized(message);
        return '';
      }

      // Parse response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return responseData['data']['text'] ?? '';
      } else {
        debugPrint('❌ OCR API error: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('❌ Error processing image for OCR: $e');
      return '';
    }
  }

  // Extract expiration date from the recognized text
  Map<String, dynamic> extractExpirationDate(String text) {
    // This function remains the same
    // In a real implementation, this would be handled by the API
    final lowerText = text.toLowerCase();

    // Check for common expiration date formats
    if (lowerText.contains('exp') ||
        lowerText.contains('best before') ||
        lowerText.contains('bb') ||
        lowerText.contains('use by')) {
      // Mock data - in a real app, this would parse the actual date from the text
      return {
        'status': 'success',
        'expiration_date': '2024-08-15',
        'days_remaining': 45,
        'is_expired': false,
      };
    }

    return {
      'status': 'not_found',
      'message': 'Expiration date not detected in the image',
    };
  }

  // No need to dispose anything now that we're not using ML Kit
  void dispose() {
    // Nothing to dispose
  }
}
