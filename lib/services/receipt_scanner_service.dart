import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import '../models/food_item_model.dart';

class ReceiptScannerService {
  static final ReceiptScannerService _instance =
      ReceiptScannerService._internal();
  final ApiService _apiService = ApiService();

  factory ReceiptScannerService() {
    return _instance;
  }

  ReceiptScannerService._internal();

  // Scan receipt image and extract food items
  Future<Map<String, dynamic>> scanReceipt(XFile imageFile) async {
    try {
      debugPrint('📸 Processing receipt image for food item detection');

      // Convert XFile to File
      final File file = File(imageFile.path);

      // Check if file exists and is readable
      if (!file.existsSync()) {
        debugPrint('❌ Image file does not exist: ${file.path}');
        return {'success': false, 'message': 'File gambar tidak ditemukan.'};
      }

      final fileSize = await file.length();
      debugPrint('📸 Receipt image file size: $fileSize bytes');
      debugPrint('📸 Receipt image file path: ${file.path}');

      // Log file extension to help debug MIME type issues
      final fileExtension = file.path.split('.').last.toLowerCase();
      debugPrint('📸 Receipt image file extension: $fileExtension');

      // Call API service with additional debug info
      final result = await _apiService.scanFoodReceipt(file);

      if (!result['success']) {
        debugPrint('❌ Receipt scanning failed: ${result['message']}');

        // Periksa error spesifik untuk masalah parsing Gemini
        final errorMsg = result['message'] ?? '';
        final errorDetails = result['error'] ?? '';

        if (errorDetails.toString().contains('failed to parse Gemini JSON') ||
            errorDetails.toString().contains('no food items listed')) {
          // Berikan pesan yang lebih ramah pengguna
          return {
            'success': false,
            'message':
                'Tidak dapat mendeteksi item makanan pada struk. Pastikan gambar struk jelas dan berisi daftar item makanan.',
            'originalError': errorDetails,
          };
        }

        return {'success': false, 'message': result['message']};
      }

      // Check if data exists in the response
      if (!result.containsKey('data') || result['data'] == null) {
        debugPrint('❌ Receipt scanning response missing data field');
        return {'success': false, 'message': 'Format respons API tidak valid.'};
      }

      final data = result['data'];
      debugPrint('✅ Receipt scanning success: $data');

      // Parse the food item from the API response
      // This assumes the API returns correctly formatted data as per your example
      final foodItem = FoodItem.fromJson(data);

      return {
        'success': true,
        'data': foodItem,
        'message': 'Struk berhasil dipindai.',
      };
    } catch (e) {
      debugPrint('❌ Error in scanReceipt: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat memindai struk: ${e.toString()}',
      };
    }
  }

  // Helper method to get image from camera
  Future<XFile?> getImageFromCamera() async {
    try {
      debugPrint('📸 Getting image from camera...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress to reduce size while keeping quality
      );

      if (pickedFile != null) {
        debugPrint('✅ Image captured from camera: ${pickedFile.path}');
      } else {
        debugPrint('⚠️ No image captured from camera');
      }

      return pickedFile;
    } catch (e) {
      debugPrint('❌ Error capturing image: $e');
      return null;
    }
  }

  // Helper method to get image from gallery
  Future<XFile?> getImageFromGallery() async {
    try {
      debugPrint('📸 Getting image from gallery...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to reduce size while keeping quality
      );

      if (pickedFile != null) {
        debugPrint('✅ Image picked from gallery: ${pickedFile.path}');
      } else {
        debugPrint('⚠️ No image selected from gallery');
      }

      return pickedFile;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }
}
