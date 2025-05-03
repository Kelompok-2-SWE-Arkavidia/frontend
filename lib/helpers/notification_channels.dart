import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Konfigurasi channel notifikasi untuk memastikan notifikasi berfungsi
/// pada berbagai versi Android dan ketika aplikasi ditutup
class NotificationChannels {
  // Food expiry notifications (normal)
  static final AndroidNotificationChannel foodExpiryChannel =
      AndroidNotificationChannel(
        'food_expiry_channel',
        'Food Expiry Notifications',
        description: 'Notifications for food expiry dates',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

  // Periodic notifications (must run in background)
  static final AndroidNotificationChannel periodicChannel =
      AndroidNotificationChannel(
        'periodic_notification_channel',
        'Periodic Notifications',
        description: 'Notifications sent every 30 seconds',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        showBadge: true,
      );

  // Summary notifications (hourly)
  static final AndroidNotificationChannel hourlySummaryChannel =
      AndroidNotificationChannel(
        'hourly_summary_channel',
        'Hourly Food Summary',
        description: 'Hourly reminders for expiring food items',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

  // Emergency/critical notifications
  static final AndroidNotificationChannel criticalChannel =
      AndroidNotificationChannel(
        'critical_expiry_channel',
        'Critical Expiry Notifications',
        description: 'Notifications for food items nearing expiry',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

  // Test channel
  static final AndroidNotificationChannel testChannel =
      AndroidNotificationChannel(
        'test_channel',
        'Test Notifications',
        description: 'Channel for test notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  // List of all channels to register
  static List<AndroidNotificationChannel> getAllChannels() {
    return [
      foodExpiryChannel,
      periodicChannel,
      hourlySummaryChannel,
      criticalChannel,
      testChannel,
    ];
  }
}
