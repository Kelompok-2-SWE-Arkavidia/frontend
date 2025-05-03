import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/receipt_item.dart';
import 'receipt_confirmation_screen.dart';

// Widget untuk bullet point
class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class ReceiptScannerPage extends StatefulWidget {
  const ReceiptScannerPage({Key? key}) : super(key: key);

  @override
  State<ReceiptScannerPage> createState() => _ReceiptScannerPageState();
}

class _ReceiptScannerPageState extends State<ReceiptScannerPage> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  XFile? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Struk'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Scan Struk Belanja',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ambil foto struk belanja untuk mendeteksi item makanan secara otomatis. Pastikan:',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            BulletPoint('Struk terlihat jelas dan tidak buram'),
                            BulletPoint('Nama produk makanan terbaca jelas'),
                            BulletPoint('Seluruh daftar item terlihat'),
                            BulletPoint(
                              'Tanggal kadaluarsa terlihat (jika ada)',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Selected image preview
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hasError ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _hasError ? Colors.red[200]! : Colors.green[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _hasError ? Icons.error : Icons.check_circle,
                          color: _hasError ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color:
                                  _hasError
                                      ? Colors.red[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ambil Foto Struk'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pilih dari Galeri'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memproses gambar...'),
                      ],
                    ),
                  ),
                ),

              // Padding tambahan di bawah untuk scroll area
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Method to take a picture using camera
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        _selectedImage = image;
        setState(() {
          _statusMessage = '';
          _hasError = false;
        });
        _processReceiptImage(image);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal mengambil gambar: ${e.toString()}';
        _hasError = true;
      });
    }
  }

  // Method to pick an image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        _selectedImage = image;
        setState(() {
          _statusMessage = '';
          _hasError = false;
        });
        _processReceiptImage(image);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal memilih gambar: ${e.toString()}';
        _hasError = true;
      });
    }
  }

  // Method to process the receipt image
  Future<void> _processReceiptImage(XFile image) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _hasError = false;
    });

    try {
      // Menggunakan API Service untuk memproses gambar struk dari pengguna
      final File imageFile = File(image.path);

      // Cek apakah file ada dan bisa dibaca
      if (!imageFile.existsSync()) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'File gambar tidak ditemukan. Silakan coba lagi.';
          _hasError = true;
        });
        return;
      }

      // Panggil API untuk memproses struk
      final response = await _apiService.scanFoodReceipt(imageFile);

      if (!response['success']) {
        setState(() {
          _isLoading = false;
          _statusMessage =
              response['message'] ?? 'Gagal memproses gambar struk';
          _hasError = true;
        });
        return;
      }

      // Parse data dari API menjadi list item
      final List<ReceiptItem> items = ApiService.parseReceiptItems(response);
      final String scanId = response['data']['scan_id'] as String;

      setState(() {
        _isLoading = false;
        _statusMessage =
            'Struk berhasil dipindai. Silahkan konfirmasi item yang terdeteksi.';
        _hasError = false;
      });

      // Navigate to confirmation screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ReceiptConfirmationScreen(items: items, scanId: scanId),
        ),
      );

      if (result == true) {
        setState(() {
          _selectedImage = null;
          _statusMessage = 'Data item berhasil disimpan';
          _hasError = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Terjadi kesalahan: ${e.toString()}';
        _hasError = true;
      });
    }
  }
}
