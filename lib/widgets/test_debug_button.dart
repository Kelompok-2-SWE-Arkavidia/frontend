import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';

class TestDebugButton extends ConsumerStatefulWidget {
  const TestDebugButton({Key? key}) : super(key: key);

  @override
  ConsumerState<TestDebugButton> createState() => _TestDebugButtonState();
}

class _TestDebugButtonState extends ConsumerState<TestDebugButton> {
  bool _isVisible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    // Tampilkan tombol pertama kali
    setState(() {
      _isVisible = true;
    });

    // Timer untuk mengatur visibilitas setiap 30 detik
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        _isVisible = true;
      });

      // Tombol akan menghilang setelah 5 detik
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    });
  }

  void _resetOnboarding() async {
    final appStateNotifier =
        ref.read(appStateProvider.notifier) as AppStateNotifier;
    await appStateNotifier.forceResetOnboardingStatus();

    // Tampilkan snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Status onboarding direset! Restart aplikasi untuk melihat perubahan.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Positioned(
      bottom: 120,
      right: 20,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: FloatingActionButton(
            onPressed: _resetOnboarding,
            backgroundColor: Colors.red,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
