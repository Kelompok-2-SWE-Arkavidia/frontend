import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  final TextRecognizer _textRecognizer = TextRecognizer();

  factory OcrService() {
    return _instance;
  }

  OcrService._internal();

  // Process image and extract text using ML Kit
  Future<String> processImage(XFile imageFile) async {
    try {
      // Convert XFile to InputImage
      final inputImage = InputImage.fromFilePath(imageFile.path);

      // Process the image
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      debugPrint('Error processing image for OCR: $e');
      return '';
    }
  }

  // Extract expiration date from the recognized text
  // This is a simple implementation and would need more complex logic for real use
  Map<String, dynamic> extractExpirationDate(String text) {
    // This is a simplified example
    // A real implementation would use regex patterns or NLP to identify dates
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

  void dispose() {
    _textRecognizer.close();
  }
}
