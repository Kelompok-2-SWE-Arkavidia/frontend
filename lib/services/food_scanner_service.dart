import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class FoodScannerService {
  static final FoodScannerService _instance = FoodScannerService._internal();
  final ApiService _apiService = ApiService();

  factory FoodScannerService() {
    return _instance;
  }

  FoodScannerService._internal();

  // Detect food age from image using API
  Future<Map<String, dynamic>> detectFoodAge(XFile imageFile) async {
    try {
      debugPrint('📸 Processing image for food age detection');
      // Convert XFile to File
      final File file = File(imageFile.path);

      // Check if file exists and is readable
      if (!file.existsSync()) {
        debugPrint('❌ Image file does not exist: ${file.path}');
        return {'status': 'error', 'message': 'File gambar tidak ditemukan.'};
      }

      final fileSize = await file.length();
      debugPrint('📸 Image file size: $fileSize bytes');
      debugPrint('📸 Image file path: ${file.path}');

      // Log file extension to help debug MIME type issues
      final fileExtension = file.path.split('.').last.toLowerCase();
      debugPrint('📸 Image file extension: $fileExtension');

      // For camera captures, make sure we have a valid extension
      if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        debugPrint('✅ Valid image format detected: $fileExtension');
      } else {
        debugPrint('⚠️ Potentially problematic file extension: $fileExtension');
      }

      try {
        // Call API service with additional timeout
        final result = await _apiService.detectFoodAge(file);

        if (!result['success']) {
          debugPrint('❌ Food age detection failed: ${result['message']}');
          return {'status': 'error', 'message': result['message']};
        }

        // Check if data exists in the response
        if (!result.containsKey('data') || result['data'] == null) {
          debugPrint('❌ Food age detection response missing data field');
          return {
            'status': 'error',
            'message': 'Format respons API tidak valid.',
          };
        }

        final data = result['data'];
        debugPrint('✅ Food age detection success: $data');

        // Debug the foodType field specifically
        debugPrint('🍎 Food Type from API: ${data['foodType']}');

        // Special handling for foodType to ensure it's not displayed as Unknown
        String foodType = 'Unknown';
        if (data['foodType'] != null) {
          foodType = data['foodType'].toString();
          debugPrint('🍎 Using food type: $foodType');
        } else {
          debugPrint('⚠️ Food type is null in API response');
        }

        // Transform API response to match the UI's expected format
        return {
          'status': 'success',
          'food_type': foodType,
          'estimated_age': '${data['estimatedAgeDays'] ?? 0} days',
          'freshness': _getFreshnessFromAge(data['estimatedAgeDays'] ?? 0),
          'expires_in': _getExpiresInText(data['estimatedAgeDays'] ?? 0),
          'confidence': data['confidenceScore'] ?? 0.0,
        };
      } catch (e) {
        debugPrint('❌ API call error in detectFoodAge: $e');
        return {
          'status': 'error',
          'message':
              'Gagal terhubung ke server. Periksa koneksi internet Anda.',
        };
      }
    } catch (e) {
      debugPrint('❌ Error in detectFoodAge: $e');
      return {
        'status': 'error',
        'message':
            'Terjadi kesalahan saat menganalisis gambar: ${e.toString()}',
      };
    }
  }

  // Helper to determine freshness text from age
  String _getFreshnessFromAge(int ageDays) {
    if (ageDays < 3) return 'Sangat Segar';
    if (ageDays < 7) return 'Segar';
    if (ageDays < 14) return 'Masih Baik';
    return 'Perlu Perhatian';
  }

  // Helper to determine expiration text from age
  String _getExpiresInText(int ageDays) {
    // This is a simplified model - in real life this would depend on the type of food
    final int typicalShelfLife = 14; // Assume typical shelf life of 14 days
    final int daysRemaining = typicalShelfLife - ageDays;

    if (daysRemaining <= 0) return 'Sudah melewati perkiraan kadaluarsa';
    if (daysRemaining == 1) return '1 hari';
    return '$daysRemaining hari';
  }

  // Helper method to initialize camera
  Future<CameraController?> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('❌ No cameras available on device');
        return null;
      }

      debugPrint('📸 Found ${cameras.length} cameras on device');

      // Use the first back camera
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      debugPrint('📸 Using camera: ${camera.name} (${camera.lensDirection})');

      // Initialize controller
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid
                ? ImageFormatGroup.yuv420
                : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      debugPrint('✅ Camera initialized successfully');
      return controller;
    } on CameraException catch (e) {
      debugPrint('❌ Camera initialization error: ${e.description}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected camera error: $e');
      return null;
    }
  }

  // Helper method to take a picture
  Future<XFile?> takePicture(CameraController controller) async {
    try {
      debugPrint('📸 Taking picture...');
      final imageFile = await controller.takePicture();
      debugPrint('✅ Picture taken: ${imageFile.path}');
      return imageFile;
    } on CameraException catch (e) {
      debugPrint('❌ Error taking picture: ${e.description}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error taking picture: $e');
      return null;
    }
  }

  // Helper method to get image from gallery
  Future<XFile?> getImageFromGallery() async {
    try {
      debugPrint('📸 Getting image from gallery...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        debugPrint('✅ Image picked from gallery: ${pickedFile.path}');
      } else {
        debugPrint('⚠️ No image selected from gallery');
      }
      return pickedFile;
    } on PlatformException catch (e) {
      debugPrint('❌ Error picking image: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error picking image: $e');
      return null;
    }
  }
}
