import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/food_scanner_service.dart';
import '../services/camera_permission_service.dart';
import '../theme/app_theme.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({Key? key}) : super(key: key);

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _scanResult;

  final CameraPermissionService _permissionService = CameraPermissionService();
  final FoodScannerService _scannerService = FoodScannerService();

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
          'Fitur ini memerlukan akses kamera untuk memindai makanan. Izinkan akses kamera untuk melanjutkan.',
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
      // Show processing feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memproses gambar...'),
          duration: Duration(seconds: 1),
        ),
      );

      final imageFile = await _scannerService.takePicture(_controller!);

      if (imageFile != null) {
        // Show analyzing feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menganalisis makanan...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        final result = await _scannerService.detectFoodAge(imageFile);

        if (mounted) {
          setState(() {
            _scanResult = result;
            _isProcessing = false;
          });

          // Show success or error feedback
          if (result['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Analisis berhasil!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Analisis gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengambil gambar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _takePicture: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _retryScanning() async {
    setState(() {
      _scanResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Makanan'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _scanResult != null ? _buildResultView() : _buildCameraView(),
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CameraPreview(_controller!),
            ),
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
    final result = _scanResult!;
    final bool isSuccess = result['status'] == 'success';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isSuccess
                  ? _buildSuccessResult(result)
                  : _buildErrorResult(result),
        ),
      ),
    );
  }

  Widget _buildSuccessResult(Map<String, dynamic> result) {
    // Get confidence percentage
    final double confidence =
        (result['confidence'] is double) ? result['confidence'] * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Hasil Analisis',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 4),
            Text(
              'Berhasil',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResultItem(
          'Jenis Makanan',
          result['food_type'] ?? 'Tidak dikenali',
        ),
        const Divider(),
        _buildResultItem(
          'Usia Makanan',
          result['estimated_age'] ?? 'Tidak diketahui',
        ),
        const Divider(),
        _buildResultItem('Kondisi', result['freshness'] ?? 'Tidak diketahui'),
        const Divider(),
        _buildResultItem(
          'Perkiraan Kadaluarsa',
          result['expires_in'] ?? 'Tidak diketahui',
        ),
        const Divider(),
        _buildResultItem(
          'Tingkat Kepercayaan',
          '${confidence.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _scanResult = null;
                });
              },
              child: const Text('Scan Lagi'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorResult(Map<String, dynamic> result) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(
          'Gagal Analisis',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.red),
        ),
        const SizedBox(height: 16),
        Text(
          result['message'] ?? 'Terjadi kesalahan saat menganalisis gambar.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _scanResult = null;
            });
          },
          child: const Text('Coba Lagi'),
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
