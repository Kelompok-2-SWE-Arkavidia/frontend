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

      // Call API service
      final result = await _apiService.detectFoodAge(file);

      if (!result['success']) {
        debugPrint('❌ Food age detection failed: ${result['message']}');
        return {'status': 'error', 'message': result['message']};
      }

      final data = result['data'];
      debugPrint('✅ Food age detection success: $data');

      // Transform API response to match the UI's expected format
      return {
        'status': 'success',
        'food_type': data['foodType'] ?? 'Unknown',
        'estimated_age': '${data['estimatedAgeDays'] ?? 0} days',
        'freshness': _getFreshnessFromAge(data['estimatedAgeDays'] ?? 0),
        'expires_in': _getExpiresInText(data['estimatedAgeDays'] ?? 0),
        'confidence': data['confidenceScore'] ?? 0.0,
        'raw_data': data, // Include the original data for debugging
      };
    } catch (e) {
      debugPrint('❌ Error in detectFoodAge: $e');
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan saat menganalisis gambar.',
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
        return null;
      }

      // Use the first back camera
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

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
      return controller;
    } on CameraException catch (e) {
      debugPrint('Camera initialization error: ${e.description}');
      return null;
    }
  }

  // Helper method to take a picture
  Future<XFile?> takePicture(CameraController controller) async {
    try {
      final imageFile = await controller.takePicture();
      return imageFile;
    } on CameraException catch (e) {
      debugPrint('Error taking picture: ${e.description}');
      return null;
    }
  }

  // Helper method to get image from gallery
  Future<XFile?> getImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      return pickedFile;
    } on PlatformException catch (e) {
      debugPrint('Error picking image: ${e.message}');
      return null;
    }
  }
}
