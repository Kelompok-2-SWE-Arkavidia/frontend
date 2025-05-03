import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateNotifier extends StateNotifier<bool> {
  static const String _hasShownOnboardingKey = 'has_shown_onboarding';

  AppStateNotifier() : super(false) {
    debugPrint(
      '⚙️ AppStateNotifier dibuat dengan nilai default false (show onboarding)',
    );
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cek apakah kunci ini ada di SharedPreferences, jika tidak ada berarti instalasi pertama
      final bool keyExists = prefs.containsKey(_hasShownOnboardingKey);
      if (!keyExists) {
        debugPrint(
          '🆕 Instalasi pertama terdeteksi! Belum ada status onboarding',
        );
        // Untuk instalasi pertama, kita pastikan nilai default adalah false
        state = false;
        return;
      }

      // Jika key ada, baca nilainya
      final hasShownOnboarding = prefs.getBool(_hasShownOnboardingKey) ?? false;

      // Update state
      state = hasShownOnboarding;

      debugPrint(
        '🔍 Sudah pernah lihat onboarding: $hasShownOnboarding (key exists: $keyExists)',
      );
    } catch (e) {
      debugPrint('❌ Error memeriksa status onboarding: $e');
      // Untuk kasus error, kita anggap belum pernah lihat onboarding
      state = false;
    }
  }

  Future<void> setOnboardingShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownOnboardingKey, true);

      // Update state
      state = true;

      debugPrint('✅ Status onboarding disimpan: true');
    } catch (e) {
      debugPrint('❌ Error menyimpan status onboarding: $e');
    }
  }

  Future<void> resetAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasShownOnboardingKey, false);

      // Update state
      state = false;

      debugPrint('🔄 Status onboarding direset');
    } catch (e) {
      debugPrint('❌ Error mereset status onboarding: $e');
    }
  }

  // Method untuk memaksa refresh nilai onboarding dari SharedPreferences
  Future<void> refreshOnboardingStatus() async {
    debugPrint('🔄 Memaksa refresh status onboarding dari SharedPreferences');
    try {
      final prefs = await SharedPreferences.getInstance();

      // Untuk debugging, periksa apakah kunci ada sebelum membacanya
      final bool keyExists = prefs.containsKey(_hasShownOnboardingKey);
      debugPrint('🔍 Onboarding key exists: $keyExists');

      // Untuk instalasi pertama, pastikan nilai adalah false
      if (!keyExists) {
        debugPrint(
          '🆕 Refresh: Instalasi pertama terdeteksi! Paksa nilai false',
        );
        state = false;
        return;
      }

      // Baca nilai langsung dari SharedPreferences
      final hasShownOnboarding = prefs.getBool(_hasShownOnboardingKey) ?? false;

      // Update state
      state = hasShownOnboarding;

      debugPrint('✅ Refresh: Status onboarding = $hasShownOnboarding');
    } catch (e) {
      debugPrint('❌ Error saat refresh status onboarding: $e');
      // Untuk kasus error, kita anggap belum pernah lihat onboarding
      state = false;
    }
  }

  // Method untuk memaksa reset onboarding status (untuk testing)
  Future<void> forceResetOnboardingStatus() async {
    try {
      debugPrint('🧨 MEMAKSA RESET STATUS ONBOARDING (untuk testing)');
      final prefs = await SharedPreferences.getInstance();

      // Hapus kunci onboarding
      await prefs.remove(_hasShownOnboardingKey);

      // Set state ke false
      state = false;

      debugPrint('✅ Status onboarding berhasil direset paksa');
    } catch (e) {
      debugPrint('❌ Error saat reset paksa status onboarding: $e');
    }
  }
}

// Provider untuk mengakses AppStateNotifier
final appStateProvider = StateNotifierProvider<AppStateNotifier, bool>((ref) {
  return AppStateNotifier();
});

// Convenience provider to check if onboarding has been shown
final hasShownOnboardingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider);
});
