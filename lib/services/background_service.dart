import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._();
  static BackgroundService get instance => _instance;

  static const String _lastSyncKey = 'last_notification_sync';
  Timer? _syncTimer;
  bool _isRunning = false;

  BackgroundService._();

  // Initialize and start the service
  Future<void> initialize() async {
    try {
      // Initialize notification service
      await NotificationService.instance.initialize();

      // Start periodic sync
      startPeriodicSync();

      debugPrint('✅ Background service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize background service: $e');
    }
  }

  // Start periodic sync with configurable interval
  void startPeriodicSync({Duration interval = const Duration(hours: 6)}) {
    if (_isRunning) return;

    _syncTimer = Timer.periodic(interval, (_) {
      _checkAndPerformSync();
    });

    // Also perform an immediate sync
    _checkAndPerformSync();

    _isRunning = true;
    debugPrint(
      '✅ Started periodic notification sync (interval: ${interval.inHours} hours)',
    );
  }

  // Stop the service
  void stopService() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
    debugPrint('✅ Background service stopped');
  }

  // Check if sync is needed and perform it
  Future<void> _checkAndPerformSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if 6 hours have passed since last sync
      final sixHoursInMillis = 6 * 60 * 60 * 1000;
      if (now - lastSync >= sixHoursInMillis) {
        debugPrint('🔄 Time for notification sync');

        // Sync notifications with API data
        await NotificationService.instance.syncNotificationsWithApi();

        // Schedule daily check notification
        await NotificationService.instance.scheduleDailyCheck();

        // Update last sync time
        await prefs.setInt(_lastSyncKey, now);
        debugPrint('✅ Notification sync completed and recorded');
      } else {
        final timeUntilNextSync = sixHoursInMillis - (now - lastSync);
        debugPrint(
          '⏳ Next notification sync in ${Duration(milliseconds: timeUntilNextSync).inHours} hours',
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking/performing sync: $e');
    }
  }

  // Force an immediate sync regardless of timer
  Future<void> forceSyncNow() async {
    try {
      debugPrint('🔄 Forcing immediate notification sync');

      // Sync notifications with API data
      await NotificationService.instance.syncNotificationsWithApi();

      // Schedule daily check notification
      await NotificationService.instance.scheduleDailyCheck();

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Forced notification sync completed');
    } catch (e) {
      debugPrint('❌ Error during forced sync: $e');
    }
  }
}
