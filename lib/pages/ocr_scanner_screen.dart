import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/ocr_service.dart';
import '../services/camera_permission_service.dart';
import '../services/food_scanner_service.dart';
import '../theme/app_theme.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({Key? key}) : super(key: key);

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  Map<String, dynamic>? _dateResult;

  final CameraPermissionService _permissionService = CameraPermissionService();
  final FoodScannerService _scannerService = FoodScannerService();
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before camera was initialized
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final hasPermission = await _permissionService.requestCameraPermission();

    if (!hasPermission) {
      if (mounted) {
        final shouldShowSettings = await _permissionService.showPermissionDialog(
          context,
          'Izin Kamera Diperlukan',
          'Fitur ini memerlukan akses kamera untuk memindai teks pada kemasan makanan. Izinkan akses kamera untuk melanjutkan.',
        );

        if (shouldShowSettings) {
          await _permissionService.openSettings();
        }
      }
      return;
    }

    final cameraController = await _scannerService.initializeCamera();

    if (cameraController != null && mounted) {
      setState(() {
        _controller = cameraController;
        _isCameraInitialized = true;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menginisialisasi kamera')),
      );
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_isCameraInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageFile = await _scannerService.takePicture(_controller!);

      if (imageFile != null) {
        // Process the image with OCR
        final text = await _ocrService.processImage(imageFile);

        // Extract expiration date
        final dateResult = _ocrService.extractExpirationDate(text);

        if (mounted) {
          setState(() {
            _recognizedText = text;
            _dateResult = dateResult;
            _isProcessing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil gambar')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _retryScanning() async {
    setState(() {
      _recognizedText = '';
      _dateResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemindai Tanggal Kadaluarsa'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _recognizedText.isNotEmpty ? _buildResultView() : _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menginisialisasi kamera...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CameraPreview(_controller!),
                ),
              ),
              // Overlay target area
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Text overlay
              Positioned(
                bottom: 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Arahkan ke label tanggal kadaluarsa',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isProcessing ? null : _takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isProcessing ? Colors.grey : AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        _isProcessing
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 32,
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final dateResult = _dateResult!;
    final bool isSuccess = dateResult['status'] == 'success';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result card with drop shadow
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              isSuccess
                                  ? AppTheme.primaryColor.withOpacity(0.1)
                                  : AppTheme.warningColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isSuccess
                                ? Icons.check_circle
                                : Icons.warning_amber,
                            color:
                                isSuccess
                                    ? AppTheme.primaryColor
                                    : AppTheme.warningColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hasil OCR',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              isSuccess
                                  ? 'Tanggal kadaluarsa terdeteksi'
                                  : 'Tanggal kadaluarsa tidak ditemukan',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // OCR information
                  if (isSuccess) ...[
                    _buildResultItem(
                      'Tanggal Kadaluarsa',
                      dateResult['expiration_date'],
                    ),
                    _buildResultItem(
                      'Sisa Hari',
                      dateResult['days_remaining'].toString(),
                    ),
                    _buildResultItem(
                      'Status',
                      dateResult['is_expired']
                          ? 'Sudah Kadaluarsa'
                          : 'Belum Kadaluarsa',
                    ),
                  ] else if (dateResult.containsKey('message')) ...[
                    _buildResultItem('Pesan', dateResult['message']),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Show recognized text
                  Text(
                    'Teks Terdeteksi:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    width: double.infinity,
                    child: Text(
                      _recognizedText.isEmpty
                          ? 'Tidak ada teks terdeteksi'
                          : _recognizedText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _retryScanning,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pindai Ulang'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textLightColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
