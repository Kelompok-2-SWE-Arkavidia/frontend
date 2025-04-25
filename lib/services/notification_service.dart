import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_item_model.dart';
import '../services/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  bool _isInitialized = false;

  NotificationService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz_init.initializeTimeZones();

      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Request notification permission for Android 13+
      await requestPermissions();

      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  // Request notification permissions on both platforms
  Future<void> requestPermissions() async {
    try {
      // For Android 13+ (API level 33+)
      final androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        debugPrint('Android notification permission granted: $granted');
      }

      // For iOS
      final iOSImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iOSImplementation != null) {
        final granted = await iOSImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('iOS notification permission granted: $granted');
      }

      debugPrint('Notification permissions requested');
    } catch (e) {
      debugPrint('Failed to request permissions: $e');
    }
  }

  // Schedule expiry notifications for a food item
  Future<void> scheduleExpiryNotifications({
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
  }) async {
    try {
      await cancelItemNotifications(itemId);

      final now = DateTime.now();
      final daysDiff = expiryDate.difference(now).inDays;

      debugPrint(
        'Scheduling notifications for $itemName (expires in $daysDiff days)',
      );

      // Always schedule a test notification regardless of expiry date
      await showTestNotification(
        itemId: itemId,
        itemName: itemName,
        expiryDate: expiryDate,
      );

      // If already expired, no need to schedule other notifications
      if (daysDiff <= 0) {
        debugPrint(
          'Item $itemName is already expired, only test notification scheduled',
        );
        return;
      }

      // Schedule notifications based on how many days until expiry

      // H-3 notification (if applicable)
      if (daysDiff >= 3) {
        final scheduleDate = expiryDate.subtract(const Duration(days: 3));
        await _scheduleNotification(
          id: int.parse(itemId.hashCode.toString().substring(0, 8)) + 1,
          title: 'Makanan Segera Kadaluarsa',
          body: '$itemName akan kadaluarsa dalam 3 hari',
          scheduledDate: scheduleDate,
          payload: 'warning:$itemId:3',
        );
        debugPrint(
          'Scheduled H-3 notification for $itemName on ${scheduleDate.toString()}',
        );
      }

      // H-1 notification (if applicable)
      if (daysDiff >= 1) {
        final scheduleDate = expiryDate.subtract(const Duration(days: 1));
        await _scheduleNotification(
          id: int.parse(itemId.hashCode.toString().substring(0, 8)) + 2,
          title: 'Makanan Hampir Kadaluarsa',
          body: '$itemName akan kadaluarsa besok',
          scheduledDate: scheduleDate,
          payload: 'warning:$itemId:1',
        );
        debugPrint(
          'Scheduled H-1 notification for $itemName on ${scheduleDate.toString()}',
        );
      }

      // Expiry day notification
      await _scheduleNotification(
        id: int.parse(itemId.hashCode.toString().substring(0, 8)) + 3,
        title: 'Makanan Kadaluarsa Hari Ini',
        body: '$itemName kadaluarsa hari ini',
        scheduledDate: expiryDate,
        payload: 'expired:$itemId:0',
      );
      debugPrint(
        'Scheduled expiry day notification for $itemName on ${expiryDate.toString()}',
      );
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  // Show test notification immediately (10 seconds delay for visibility)
  Future<void> showTestNotification({
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
  }) async {
    try {
      final now = DateTime.now();
      final daysDiff = expiryDate.difference(now).inDays;

      // Create message with expiry information
      String expiryMessage;
      if (daysDiff < 0) {
        expiryMessage = '$itemName kadaluarsa ${daysDiff.abs()} hari yang lalu';
      } else if (daysDiff == 0) {
        expiryMessage = '$itemName kadaluarsa hari ini';
      } else if (daysDiff == 1) {
        expiryMessage = '$itemName kadaluarsa besok';
      } else {
        expiryMessage = '$itemName kadaluarsa dalam $daysDiff hari';
      }

      // FOR TESTING: Schedule a notification 10 seconds from now
      await _scheduleNotification(
        id: int.parse(itemId.hashCode.toString().substring(0, 8)) + 4,
        title: 'Notifikasi Kadaluarsa',
        body: expiryMessage,
        scheduledDate: now.add(const Duration(seconds: 10)),
        payload: 'test:$itemId',
      );
      debugPrint(
        'Scheduled test notification for $itemName in 10 seconds with message: $expiryMessage',
      );
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
    }
  }

  // Show an immediate test notification (for manual triggering)
  Future<void> showImmediateTestNotification() async {
    try {
      final now = DateTime.now();
      final testId = now.millisecondsSinceEpoch % 10000;

      // Create sample expiry data (3 days from now for test purposes)
      final exampleExpiryDate = now.add(const Duration(days: 3));
      final daysUntilExpiry = exampleExpiryDate.difference(now).inDays;
      final exampleItemName = "Mie Instan";

      // Create message with expiry information
      String expiryMessage;
      if (daysUntilExpiry < 0) {
        expiryMessage =
            '$exampleItemName kadaluarsa ${daysUntilExpiry.abs()} hari yang lalu';
      } else if (daysUntilExpiry == 0) {
        expiryMessage = '$exampleItemName kadaluarsa hari ini';
      } else if (daysUntilExpiry == 1) {
        expiryMessage = '$exampleItemName kadaluarsa besok';
      } else {
        expiryMessage =
            '$exampleItemName kadaluarsa dalam $daysUntilExpiry hari';
      }

      // Create Android notification details with maximum importance
      final androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for test notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        enableLights: true,
      );

      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        testId,
        'Notifikasi Kadaluarsa',
        expiryMessage,
        platformDetails,
        payload: 'manual_test',
      );

      debugPrint(
        'Manual test notification sent successfully with expiry message: $expiryMessage',
      );
    } catch (e) {
      debugPrint('Error sending manual test notification: $e');
    }
  }

  // Schedule a notification at a specific time
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'food_expiry_channel',
      'Food Expiry Notifications',
      channelDescription: 'Notifications for food expiry dates',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert DateTime to TZDateTime for scheduling
    final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      // For newer versions of flutter_local_notifications
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );

      debugPrint(
        'Notification scheduled successfully for $title on ${scheduledDate.toString()}',
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Cancel all notifications for a specific item
  Future<void> cancelItemNotifications(String itemId) async {
    try {
      final baseId = int.parse(itemId.hashCode.toString().substring(0, 8));
      // Cancel all possible notifications for this item (base ID + 0-4)
      for (int i = 0; i <= 4; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
      debugPrint('Cancelled notifications for item $itemId');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  // Add this helper method to check notification permissions
  Future<bool> areNotificationsEnabled() async {
    try {
      // For Android
      final androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }

      return true; // Default to true for other platforms
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // New method to sync notifications with API data
  Future<void> syncNotificationsWithApi() async {
    try {
      debugPrint('🔄 Starting notification sync with API data');

      // First cancel all existing notifications
      await cancelAllNotifications();

      // Fetch food items that are expiring soon or active
      final result = await _apiService.getFoodItems(
        status: 'all', // Get all items to check their expiry dates
        limit: 100, // Set a reasonable limit
      );

      if (!result['success']) {
        debugPrint(
          '❌ Failed to fetch items for notification sync: ${result['message']}',
        );
        return;
      }

      final List<FoodItem> foodItems = result['data'];
      debugPrint(
        '✅ Retrieved ${foodItems.length} items for notification processing',
      );

      // Schedule notifications for each item based on expiry date
      int expiringCount = 0;
      int expiredCount = 0;

      for (var item in foodItems) {
        final now = DateTime.now();
        final daysUntilExpiry = item.expiryDate.difference(now).inDays;

        // Skip items that expire more than 7 days from now
        if (daysUntilExpiry > 7) continue;

        if (daysUntilExpiry <= 0) {
          expiredCount++;
        } else if (daysUntilExpiry <= 3) {
          expiringCount++;
        }

        await scheduleExpiryNotifications(
          itemId: item.id,
          itemName: item.name,
          expiryDate: item.expiryDate,
        );
      }

      // Show a summary notification if there are items expiring soon
      if (expiringCount > 0 || expiredCount > 0) {
        await _showSummaryNotification(expiringCount, expiredCount);
      }

      debugPrint(
        '✅ Notification sync completed: $expiringCount items expiring soon, $expiredCount expired items',
      );
    } catch (e) {
      debugPrint('❌ Error syncing notifications with API: $e');
    }
  }

  // Show a summary notification of expiring items
  Future<void> _showSummaryNotification(
    int expiringCount,
    int expiredCount,
  ) async {
    try {
      final summaryId = DateTime.now().millisecondsSinceEpoch % 10000;

      // Create summary message
      String summaryMessage = '';
      if (expiredCount > 0) {
        summaryMessage += '$expiredCount item kadaluarsa';
      }

      if (expiringCount > 0) {
        if (summaryMessage.isNotEmpty) {
          summaryMessage += ' dan ';
        }
        summaryMessage += '$expiringCount item akan kadaluarsa dalam 3 hari';
      }

      final androidDetails = AndroidNotificationDetails(
        'food_summary_channel',
        'Food Expiry Summary',
        channelDescription:
            'Summary notifications for food items expiring soon',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          'Periksa stok makanan anda. $summaryMessage.',
          contentTitle: 'Ringkasan Kadaluarsa Makanan',
        ),
      );

      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        summaryId,
        'Ringkasan Kadaluarsa Makanan',
        'Periksa stok makanan anda. $summaryMessage.',
        platformDetails,
        payload: 'summary',
      );

      debugPrint('✅ Summary notification sent: $summaryMessage');
    } catch (e) {
      debugPrint('❌ Error showing summary notification: $e');
    }
  }

  // Daily notification check (call this at app startup or periodically)
  Future<void> scheduleDailyCheck() async {
    try {
      final now = DateTime.now();
      // Schedule for 9 AM tomorrow
      final scheduledTime = DateTime(now.year, now.month, now.day + 1, 9, 0, 0);

      await _scheduleNotification(
        id: 9999, // Use a fixed ID for the daily check
        title: 'Cek Makanan Kadaluarsa',
        body: 'Waktunya mengecek stok makanan Anda hari ini',
        scheduledDate: scheduledTime,
        payload: 'daily_check',
      );

      debugPrint(
        '✅ Daily check notification scheduled for ${scheduledTime.toString()}',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling daily check: $e');
    }
  }
}
