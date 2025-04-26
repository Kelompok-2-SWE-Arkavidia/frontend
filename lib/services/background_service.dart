import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._();
  static BackgroundService get instance => _instance;

  static const String _lastSyncKey = 'last_notification_sync';
  static const String _testModeKey = 'notification_test_mode';
  static const String _hourlyTriggerKey = 'hourly_trigger_active';
  Timer? _syncTimer;
  Timer? _testTimer;
  Timer? _hourlyTimer;
  bool _isRunning = false;
  bool _isTestModeActive = false;
  bool _isHourlyTriggerActive = false;

  BackgroundService._();

  // Initialize and start the service
  Future<void> initialize() async {
    try {
      // Initialize notification service
      await NotificationService.instance.initialize();

      // Check saved state
      final prefs = await SharedPreferences.getInstance();
      final testModeActive = prefs.getBool(_testModeKey) ?? false;
      final hourlyTriggerActive =
          prefs.getBool(_hourlyTriggerKey) ?? true; // Default to true

      if (testModeActive) {
        // Resume test mode if it was active
        await startTestMode();
      } else {
        // Start normal periodic sync
        startPeriodicSync();
      }

      // Start hourly notifications (on by default)
      if (hourlyTriggerActive) {
        startHourlyNotifications();
      }

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

  // Start hourly notifications
  Future<void> startHourlyNotifications() async {
    if (_isHourlyTriggerActive) {
      debugPrint('⚠️ Hourly notifications already running');
      return;
    }

    try {
      debugPrint('🔄 Starting hourly notification trigger');

      // Store state in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hourlyTriggerKey, true);

      _isHourlyTriggerActive = true;

      // Run immediately first
      await _processHourlyNotification();

      // Set up hourly timer
      _hourlyTimer = Timer.periodic(const Duration(hours: 1), (_) async {
        await _processHourlyNotification();
      });

      debugPrint('✅ Hourly notifications started - will run every hour');
    } catch (e) {
      debugPrint('❌ Error starting hourly notifications: $e');
    }
  }

  // Stop hourly notifications
  Future<void> stopHourlyNotifications() async {
    if (!_isHourlyTriggerActive) {
      debugPrint('⚠️ Hourly notifications not running');
      return;
    }

    try {
      _hourlyTimer?.cancel();
      _hourlyTimer = null;
      _isHourlyTriggerActive = false;

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hourlyTriggerKey, false);

      debugPrint('✅ Hourly notifications stopped');
    } catch (e) {
      debugPrint('❌ Error stopping hourly notifications: $e');
    }
  }

  // Process hourly notification
  Future<void> _processHourlyNotification() async {
    try {
      debugPrint('🕒 Processing hourly notification');

      // Sync with API to get latest data
      await forceSyncNow();

      // Show notification with current expiring items
      await NotificationService.instance.showHourlySummaryNotification();

      debugPrint('✅ Hourly notification processed');
    } catch (e) {
      debugPrint('❌ Error processing hourly notification: $e');
    }
  }

  // Stop the service
  void stopService() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _testTimer?.cancel();
    _testTimer = null;
    _hourlyTimer?.cancel();
    _hourlyTimer = null;
    _isRunning = false;
    _isTestModeActive = false;
    _isHourlyTriggerActive = false;
    debugPrint('✅ Background service stopped');
  }

  // Check if sync is needed and perform it
  Future<void> _checkAndPerformSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if 4 hours have passed since last sync (reduced from 6 hours)
      final fourHoursInMillis = 4 * 60 * 60 * 1000;
      if (now - lastSync >= fourHoursInMillis) {
        debugPrint('🔄 Time for notification sync');

        // Sync notifications with API data
        await NotificationService.instance.syncNotificationsWithApi();

        // Schedule daily check notification
        await NotificationService.instance.scheduleDailyCheck();

        // Update last sync time
        await prefs.setInt(_lastSyncKey, now);
        debugPrint('✅ Notification sync completed and recorded');
      } else {
        final timeUntilNextSync = fourHoursInMillis - (now - lastSync);
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

  // Start test mode with recurring notifications
  Future<void> startTestMode() async {
    if (_isTestModeActive) {
      debugPrint('⚠️ Test mode is already active');
      return;
    }

    try {
      // Stop regular sync timer
      _syncTimer?.cancel();

      // Sync data from API first to ensure we have the latest data
      await forceSyncNow();

      // Start notification test mode
      await NotificationService.instance.startRecurringTestNotifications();

      // Set test mode flag in SharedPreferences to persist across app restarts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testModeKey, true);

      _isTestModeActive = true;

      // Create a backup timer that ensures notifications continue
      // This helps in case the notification service's internal scheduling fails
      _testTimer = Timer.periodic(const Duration(seconds: 35), (_) async {
        if (_isTestModeActive) {
          debugPrint('🔄 Backup test timer triggered');

          // Check if we need to refresh data from API (every 10 minutes)
          final now = DateTime.now().millisecondsSinceEpoch;
          final lastSync = prefs.getInt(_lastSyncKey) ?? 0;
          final tenMinutesInMillis = 10 * 60 * 1000;

          if (now - lastSync >= tenMinutesInMillis) {
            debugPrint('🔄 Refreshing data from API during test mode');
            await forceSyncNow();
          }

          await NotificationService.instance.startRecurringTestNotifications();
        }
      });

      debugPrint(
        '✅ Test mode started - notifications will occur every 30 seconds',
      );
    } catch (e) {
      debugPrint('❌ Error starting test mode: $e');
    }
  }

  // Stop test mode
  Future<void> stopTestMode() async {
    if (!_isTestModeActive) {
      debugPrint('⚠️ Test mode is not active');
      return;
    }

    try {
      // Cancel test timer
      _testTimer?.cancel();
      _testTimer = null;

      // Stop notification test mode
      await NotificationService.instance.stopRecurringTestNotifications();

      // Clear test mode flag in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testModeKey, false);

      _isTestModeActive = false;

      // Restart regular sync
      startPeriodicSync();

      debugPrint('✅ Test mode stopped, returned to normal operation');
    } catch (e) {
      debugPrint('❌ Error stopping test mode: $e');
    }
  }

  // Check if test mode is active
  bool isTestModeActive() {
    return _isTestModeActive;
  }
}
