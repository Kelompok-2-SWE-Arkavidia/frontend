import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';
import '../models/food_item_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  bool _isInitialized = false;

  // Timer for recurring test notifications
  bool _isTestModeActive = false;
  int _testNotificationCounter = 0;

  // Store items that meet criteria for frequent notifications
  List<Map<String, dynamic>> _criticalExpiryItems = [];

  // Add a field to track the last successful notification time
  DateTime? _lastNotificationTime;
  bool _isNotificationStalled = false;

  NotificationService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Starting notification service initialization');
      tz_init.initializeTimeZones();
      debugPrint('✅ Timezones initialized');

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

      debugPrint('📱 Initializing notification plugin');
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          debugPrint(
            '📱 Notification clicked with response: ${response.payload}',
          );
          _handleNotificationResponse(response);
        },
      );

      // Request notification permission for Android 13+
      debugPrint('🔒 Requesting notification permissions');
      await requestPermissions();

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
      debugPrint('❌ Error stack trace: ${StackTrace.current}');
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
      debugPrint('📆 Scheduling notifications for $itemName (ID: $itemId)');
      debugPrint('📅 Expiry date: ${expiryDate.toString()}');

      // Calculate days difference
      final now = DateTime.now();
      final daysDiff = expiryDate.difference(now).inDays;
      debugPrint('📊 Days until expiry: $daysDiff');

      // Check if this item meets critical expiry criteria
      if (daysDiff <= 6 && daysDiff >= 0) {
        // Add to critical expiry list
        _addCriticalExpiryItem(
          id: itemId,
          name: itemName,
          expiryDate: expiryDate,
          daysDiff: daysDiff,
        );

        // If test mode is active, send an immediate notification for this item
        if (_isTestModeActive) {
          await _sendCriticalExpiryNotification(
            itemId,
            itemName,
            expiryDate,
            daysDiff,
          );
        } else if (daysDiff == 6 || daysDiff == 3 || daysDiff == 1) {
          // Send immediate notification for H-6, H-3, H-1 regardless of test mode
          await _sendCriticalExpiryNotification(
            itemId,
            itemName,
            expiryDate,
            daysDiff,
          );
        }
      }

      // Schedule notifications for specific days before expiry
      final itemHash = itemId.hashCode;

      // 6 days before expiry notification
      if (daysDiff >= 6) {
        final sixDaysBeforeExpiry = expiryDate.subtract(
          const Duration(days: 6),
        );
        // Create unique ID for this notification type
        final sixDaysNotificationId = 1000 + itemHash;

        debugPrint(
          '🔔 Scheduling H-6 notification for $itemName at ${sixDaysBeforeExpiry.toString()}',
        );

        await _scheduleNotification(
          id: sixDaysNotificationId,
          title: 'Perhatian: H-6 Kadaluarsa',
          body: '$itemName akan kadaluarsa dalam 6 hari',
          scheduledDate: sixDaysBeforeExpiry,
          payload: 'expiry:$itemId:6',
        );
      }

      // 3 days before expiry notification
      if (daysDiff >= 3) {
        final threeDaysBeforeExpiry = expiryDate.subtract(
          const Duration(days: 3),
        );
        // Create unique ID for this notification type
        final threeDaysNotificationId = 2000 + itemHash;

        debugPrint(
          '🔔 Scheduling H-3 notification for $itemName at ${threeDaysBeforeExpiry.toString()}',
        );

        await _scheduleNotification(
          id: threeDaysNotificationId,
          title: 'Peringatan: H-3 Kadaluarsa',
          body: '$itemName akan kadaluarsa dalam 3 hari',
          scheduledDate: threeDaysBeforeExpiry,
          payload: 'expiry:$itemId:3',
        );
      }

      // 1 day before expiry notification
      if (daysDiff >= 1) {
        final oneDayBeforeExpiry = expiryDate.subtract(const Duration(days: 1));
        // Create unique ID for this notification type
        final oneDayNotificationId = 3000 + itemHash;

        debugPrint(
          '🔔 Scheduling H-1 notification for $itemName at ${oneDayBeforeExpiry.toString()}',
        );

        await _scheduleNotification(
          id: oneDayNotificationId,
          title: 'Peringatan Penting: H-1 Kadaluarsa',
          body: '$itemName akan kadaluarsa besok',
          scheduledDate: oneDayBeforeExpiry,
          payload: 'expiry:$itemId:1',
        );
      }

      // On expiry day notification
      if (daysDiff >= 0) {
        // Set notification time to 9:00 AM on expiry date
        final expiryDayNotification = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
          9,
          0,
        );

        // Create unique ID for this notification
        final expiryNotificationId = 4000 + itemHash;

        debugPrint(
          '🔔 Scheduling expiry day notification for $itemName at ${expiryDayNotification.toString()}',
        );

        await _scheduleNotification(
          id: expiryNotificationId,
          title: 'Peringatan: Makanan Kadaluarsa Hari Ini',
          body:
              '$itemName kadaluarsa hari ini. Pastikan sudah dikonsumsi atau dibuang!',
          scheduledDate: expiryDayNotification,
          payload: 'expiry:$itemId:0',
        );
      }

      debugPrint('✅ Successfully scheduled all notifications for $itemName');
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
    }
  }

  void _addCriticalExpiryItem({
    required String id,
    required String name,
    required DateTime expiryDate,
    required int daysDiff,
  }) {
    // Remove if already in list
    _criticalExpiryItems.removeWhere((item) => item['id'] == id);

    // Add to critical items list
    _criticalExpiryItems.add({
      'id': id,
      'name': name,
      'expiryDate': expiryDate,
      'daysDiff': daysDiff,
    });

    debugPrint(
      '📝 Added to critical expiry list: $name (expires in $daysDiff days)',
    );
    debugPrint(
      '📋 Critical expiry list now has ${_criticalExpiryItems.length} items',
    );
  }

  Future<void> _sendCriticalExpiryNotification(
    String id,
    String name,
    DateTime expiryDate,
    int daysDiff,
  ) async {
    try {
      // Create unique notification ID based on item ID
      final notificationId = 5000 + id.hashCode;

      // Define title and message based on days remaining
      String title;
      String body;

      if (daysDiff == 0) {
        title = 'Peringatan: Makanan Kadaluarsa Hari Ini';
        body =
            '$name kadaluarsa hari ini. Pastikan sudah dikonsumsi atau dibuang!';
      } else if (daysDiff == 1) {
        title = 'Peringatan Penting: H-1 Kadaluarsa';
        body = '$name akan kadaluarsa besok';
      } else if (daysDiff == 3) {
        title = 'Peringatan: H-3 Kadaluarsa';
        body = '$name akan kadaluarsa dalam 3 hari';
      } else if (daysDiff == 6) {
        title = 'Perhatian: H-6 Kadaluarsa';
        body = '$name akan kadaluarsa dalam 6 hari';
      } else {
        title = 'Peringatan Kadaluarsa';
        body = '$name akan kadaluarsa dalam $daysDiff hari';
      }

      // Set up Android notification details
      final androidDetails = AndroidNotificationDetails(
        'critical_expiry_channel',
        'Critical Expiry Notifications',
        channelDescription: 'Notifications for food items nearing expiry',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        color: const Color.fromARGB(255, 255, 0, 0),
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      // Set up iOS notification details
      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Send the notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: 'critical_expiry:$id:$daysDiff',
      );

      debugPrint('✅ Immediate notification sent for $name: $body');
    } catch (e) {
      debugPrint('❌ Error sending critical expiry notification: $e');
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
      // Cancel all possible notifications for this item (base ID + 0-5)
      for (int i = 0; i <= 5; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
      // Also cancel notifications in the 100+ range used for critical items
      for (int i = 0; i < 100; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + 100 + i);
      }
      // Remove the item from critical expiry list
      _criticalExpiryItems.removeWhere((item) => item['id'] == itemId);

      debugPrint('Cancelled notifications for item $itemId');
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      // Clear the critical expiry items list
      _criticalExpiryItems.clear();
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

      // Save items locally for offline notification use
      await _saveLocalFoodItems(foodItems);
      debugPrint('💾 Saved food items locally for offline notifications');

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

  // Add this new method to schedule the next cycle directly
  Future<void> _directScheduleNextCycle() async {
    try {
      // Call the next notification cycle directly without needing a notification to trigger it
      debugPrint('⏰ Direct scheduling of next notification cycle via timer');

      // Create a delayed future that will trigger after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        // Only continue if test mode is still active
        if (_isTestModeActive) {
          debugPrint('⚡ Timer triggered: initiating next notification cycle');
          _scheduleNextTestNotification();
        } else {
          debugPrint('⛔ Timer triggered but test mode not active, ignoring');
        }
      });
    } catch (e) {
      debugPrint('❌ Error in direct scheduling of next cycle: $e');
    }
  }

  // Modify the startRecurringTestNotifications method to add debug info
  Future<void> startRecurringTestNotifications({
    bool forceRestart = false,
  }) async {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute}:${now.second}';
    debugPrint(
      '🚀 startRecurringTestNotifications called at $timeStr (forceRestart: $forceRestart)',
    );

    // Check if notifications appear to be stalled (no activity for 90 seconds)
    if (_isTestModeActive && _lastNotificationTime != null) {
      final timeSinceLastNotification =
          now.difference(_lastNotificationTime!).inSeconds;
      debugPrint(
        '⏱️ Time since last notification: $timeSinceLastNotification seconds',
      );

      if (timeSinceLastNotification > 90) {
        debugPrint(
          '⚠️ DETECTED STALLED NOTIFICATIONS: No activity for $timeSinceLastNotification seconds',
        );
        _isNotificationStalled = true;
        forceRestart = true; // Force restart if stalled
      }
    }

    if (_isTestModeActive && !forceRestart) {
      debugPrint('⚠️ Test notifications are already running, skipping');

      // If this is a backup timer trigger, check notification status
      if (_lastNotificationTime != null) {
        final timeSinceLastNotification =
            now.difference(_lastNotificationTime!).inSeconds;
        debugPrint(
          '📊 Status check: ${timeSinceLastNotification}s since last notification',
        );
        await debugNotificationStatus();
      }

      return;
    }

    try {
      // If we're forcing a restart, make sure to clean up first
      if (forceRestart && _isTestModeActive) {
        debugPrint('🔄 Force restarting notification system');
        await cancelAllNotifications();
        _isNotificationStalled = false;
      }

      // Cancel any existing notifications first
      debugPrint('🧹 Cancelling any existing notifications');
      await cancelAllNotifications();

      _isTestModeActive = true;
      _testNotificationCounter = 0;
      _lastNotificationTime = now; // Initialize the timestamp
      debugPrint('✅ Test mode activated, counter reset to 0');

      // Add this to verify notification permissions before starting
      final notificationsEnabled = await areNotificationsEnabled();
      debugPrint('🔔 Notifications enabled: $notificationsEnabled');

      if (!notificationsEnabled) {
        debugPrint(
          '⚠️ Notifications are not enabled! Please check permissions',
        );
        // Try to request permissions again
        await requestPermissions();
        final permissionsCheckedAgain = await areNotificationsEnabled();
        debugPrint(
          '🔔 Notifications enabled after request: $permissionsCheckedAgain',
        );
      }

      // Start the cycle immediately
      debugPrint('🔄 Starting first notification cycle');
      await _scheduleNextTestNotification();

      debugPrint(
        '✅ Started recurring test notifications every 30 seconds with continuous detail updates',
      );
    } catch (e) {
      _isTestModeActive = false;
      debugPrint('❌ Error starting test notifications: $e');
      debugPrint('❌ Error stack trace: ${StackTrace.current}');
    }
  }

  // Schedule the next test notification in the sequence
  Future<void> _scheduleNextTestNotification() async {
    if (!_isTestModeActive) {
      debugPrint('⛔ Test mode not active, stopping notification cycle');
      return;
    }

    // Update the last notification time to prevent timeout detection
    _lastNotificationTime = DateTime.now();
    _isNotificationStalled = false;

    final currentTime = DateTime.now();
    final formattedTime =
        '${currentTime.hour}:${currentTime.minute}:${currentTime.second}';
    debugPrint('🕒 CYCLE START: $_testNotificationCounter at $formattedTime');

    try {
      _testNotificationCounter++;
      final now = DateTime.now();

      debugPrint('🔄 Processing notification cycle #$_testNotificationCounter');
      debugPrint('⏱️ Current time: ${now.toString()}');

      // Get list to store expiring items
      List<FoodItem> expiringItems = [];
      bool usingLocalData = false;

      // First try to fetch from API
      debugPrint('📲 Attempting to fetch items from API...');
      try {
        final result = await _apiService.getFoodItems(
          status: 'all',
          limit: 100,
        );

        if (result['success'] && (result['data'] as List).isNotEmpty) {
          final List<FoodItem> foodItems = result['data'];
          debugPrint(
            '✅ Successfully retrieved ${foodItems.length} items from API',
          );

          // Filter for items that are expiring soon (within 6 days)
          expiringItems =
              foodItems.where((item) {
                final daysDiff = item.expiryDate.difference(now).inDays;
                return daysDiff >= 0 && daysDiff <= 6;
              }).toList();

          // Persist the fetched data locally for future use
          await _saveLocalFoodItems(foodItems);
          debugPrint('💾 Food items saved locally for offline use');
        } else {
          throw Exception('API did not return success or empty data');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to fetch from API: $e, using local data');
        usingLocalData = true;

        // Try to load items from local storage instead
        expiringItems = await _getLocalExpiringFoodItems();

        if (expiringItems.isEmpty) {
          debugPrint('⚠️ No local data available, using fallback items');
          await _fallbackToTestItems();

          // Schedule the next cycle and exit
          _directScheduleNextCycle();
          return;
        }
      }

      // If we have expiring items (either from API or local storage)
      if (expiringItems.isNotEmpty) {
        debugPrint(
          '🔔 Found ${expiringItems.length} items meeting expiry criteria ${usingLocalData ? "(from local storage)" : "(from API)"}',
        );

        // Create notification channel details
        debugPrint('📝 Creating notification details');
        final androidDetails = AndroidNotificationDetails(
          'test_recurring_channel',
          'Test Recurring Notifications',
          channelDescription: 'Channel for test recurring notifications',
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

        // Start with a summary notification if there are multiple items
        if (expiringItems.length > 1) {
          final summaryId = 7000 + _testNotificationCounter;
          debugPrint(
            '📊 Sending summary notification for ${expiringItems.length} items',
          );
          await _flutterLocalNotificationsPlugin.show(
            summaryId,
            'Peringatan: ${expiringItems.length} Makanan Menjelang Kadaluarsa',
            'Anda memiliki ${expiringItems.length} makanan yang akan atau sudah kadaluarsa',
            platformDetails,
            payload: 'test_summary:${_testNotificationCounter}',
          );
          debugPrint(
            '✅ Sent summary notification for ${expiringItems.length} expiring items',
          );
        }

        // Process each expiring item and send individual notifications
        debugPrint('🔄 Processing individual item notifications');
        int itemsNotified = 0;
        for (var item in expiringItems) {
          final daysDiff = item.expiryDate.difference(now).inDays;

          // Only send for items that match specific expiry criteria (6, 3, 1, 0 days)
          // This restricts the notifications to items with key expiry points
          if (daysDiff == 6 ||
              daysDiff == 3 ||
              daysDiff == 1 ||
              daysDiff == 0) {
            // Create unique ID for each notification
            final notificationId =
                8000 + _testNotificationCounter + itemsNotified;

            // Prepare notification details based on days until expiry
            String expiryMessage;
            String title;

            if (daysDiff == 6) {
              title = 'Perhatian: H-6 Kadaluarsa';
              expiryMessage = '${item.name} akan kadaluarsa dalam 6 hari';
            } else if (daysDiff == 3) {
              title = 'Peringatan: H-3 Kadaluarsa';
              expiryMessage = '${item.name} akan kadaluarsa dalam 3 hari';
            } else if (daysDiff == 1) {
              title = 'Peringatan Penting: H-1 Kadaluarsa';
              expiryMessage = '${item.name} akan kadaluarsa besok';
            } else if (daysDiff == 0) {
              title = 'Peringatan: Makanan Kadaluarsa Hari Ini';
              expiryMessage =
                  '${item.name} kadaluarsa hari ini. Pastikan sudah dikonsumsi atau dibuang!';
            } else {
              continue; // Skip other days
            }

            debugPrint(
              '📱 Sending notification for ${item.name}: $daysDiff days until expiry',
            );
            // Send individual notification for this item
            await _flutterLocalNotificationsPlugin.show(
              notificationId,
              title,
              expiryMessage,
              platformDetails,
              payload: 'test_recurring:${item.id}',
            );

            itemsNotified++;
            debugPrint('✅ Sent notification for ${item.name}: $expiryMessage');

            // Add small delay between notifications to prevent flooding
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }

        debugPrint('✅ Total items notified in this batch: $itemsNotified');
      } else {
        debugPrint('⚠️ No expiring items found, using fallback');
        await _fallbackToTestItems();
      }

      // Update the last notification time again at the end of the cycle
      _lastNotificationTime = DateTime.now();

      // IMPORTANT: Schedule the next cycle using a direct timer instead of relying on silent notifications
      _directScheduleNextCycle();

      debugPrint(
        '🔄 CYCLE END: $_testNotificationCounter completed at ${DateTime.now().toString()}',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling next test notification: $e');
      debugPrint('❌ Error stack trace: ${StackTrace.current}');

      // Even if there's an error, try to schedule the next cycle directly
      _directScheduleNextCycle();
    }
  }

  // Modify the fallback test items method to also use direct scheduling
  Future<void> _fallbackToTestItems() async {
    try {
      final now = DateTime.now();

      // Create test items with varying expiry dates as fallback
      final List<Map<String, dynamic>> testItems = [
        {
          'id': 'test_item_1',
          'name': 'Apel',
          'expiryDate': now.add(const Duration(days: 6)), // H-6
        },
        {
          'id': 'test_item_2',
          'name': 'Pisang',
          'expiryDate': now.add(const Duration(days: 3)), // H-3
        },
        {
          'id': 'test_item_3',
          'name': 'Susu',
          'expiryDate': now.add(const Duration(days: 1)), // H-1
        },
      ];

      final androidDetails = AndroidNotificationDetails(
        'test_recurring_channel',
        'Test Recurring Notifications',
        channelDescription: 'Channel for test recurring notifications',
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

      // Show notifications for all fallback test items
      int itemsNotified = 0;
      for (var testItem in testItems) {
        // Create unique ID for this notification
        final notificationId = 8000 + _testNotificationCounter + itemsNotified;

        // Calculate days until expiry for message
        final daysDiff = testItem['expiryDate'].difference(now).inDays;
        String expiryMessage;
        String title;

        if (daysDiff == 6) {
          title = 'Perhatian: H-6 Kadaluarsa (Test)';
          expiryMessage = '${testItem['name']} akan kadaluarsa dalam 6 hari';
        } else if (daysDiff == 3) {
          title = 'Peringatan: H-3 Kadaluarsa (Test)';
          expiryMessage = '${testItem['name']} akan kadaluarsa dalam 3 hari';
        } else if (daysDiff == 1) {
          title = 'Peringatan Penting: H-1 Kadaluarsa (Test)';
          expiryMessage = '${testItem['name']} akan kadaluarsa besok';
        } else {
          title = 'Notifikasi Kadaluarsa (Test)';
          expiryMessage =
              '${testItem['name']} akan kadaluarsa dalam $daysDiff hari';
        }

        // This will trigger an immediate notification for testing
        await _flutterLocalNotificationsPlugin.show(
          notificationId,
          title,
          expiryMessage,
          platformDetails,
          payload: 'test_recurring:${testItem['id']}',
        );

        itemsNotified++;
        debugPrint('✅ Fallback test notification sent: $expiryMessage');

        // Add small delay between notifications to prevent flooding
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Update the last notification time
      _lastNotificationTime = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error in fallback test notification: $e');
    }
  }

  // Update the notification callback to automatically continue cycles
  void onBackgroundNotificationResponse(NotificationResponse response) {
    // This will be called when a notification is received in the background
    final payload = response.payload;

    if (payload != null &&
        (payload.startsWith('auto_cycle:') ||
            payload.startsWith('recovery:'))) {
      // Automatically trigger the next cycle when a silent notification is received
      _scheduleNextTestNotification();
    }
  }

  // Handle notification response to maintain the cycle when notifications are tapped
  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute}:${now.second}';

    // Update the notification time when user interacts
    _lastNotificationTime = now;

    debugPrint('📱 Notification tapped at $timeStr with payload: $payload');

    if (payload != null && _isTestModeActive) {
      if (payload.startsWith('cycle_next:') ||
          payload.startsWith('recovery:') ||
          payload.startsWith('test_recurring:') ||
          payload.startsWith('test_summary:')) {
        // When any relevant notification is tapped, trigger next round
        debugPrint(
          '🔄 Notification tapped, triggering next notification cycle',
        );

        // If notifications were stalled, force-restart the system
        if (_isNotificationStalled) {
          debugPrint(
            '🔄 Detected stalled notification system, force-restarting',
          );
          await startRecurringTestNotifications(forceRestart: true);
        } else {
          await _scheduleNextTestNotification();
        }
      } else {
        debugPrint('ℹ️ Other notification tapped with payload: $payload');
      }
    } else {
      debugPrint(
        '⚠️ Notification tapped but test mode is not active or payload is null',
      );
    }
  }

  // Stop the recurring test notifications
  Future<void> stopRecurringTestNotifications() async {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute}:${now.second}';
    debugPrint('🛑 stopRecurringTestNotifications called at $timeStr');

    if (!_isTestModeActive) {
      debugPrint('⚠️ Test notifications are not running, nothing to stop');
      return;
    }

    try {
      _isTestModeActive = false;
      debugPrint('🔕 Test mode deactivated');

      // Cancel all pending notifications
      debugPrint('🧹 Cancelling all pending notifications');
      await cancelAllNotifications();

      debugPrint('✅ Stopped recurring test notifications at $timeStr');
    } catch (e) {
      debugPrint('❌ Error stopping test notifications: $e');
      debugPrint('❌ Error stack trace: ${StackTrace.current}');
    }
  }

  // Add this debugging method to diagnose notification issues
  Future<void> debugNotificationStatus() async {
    final now = DateTime.now();
    final timeStr = '${now.hour}:${now.minute}:${now.second}';
    debugPrint('📊 NOTIFICATION STATUS AT $timeStr 📊');
    debugPrint('🔔 Test mode active: $_isTestModeActive');
    debugPrint('🔢 Current notification counter: $_testNotificationCounter');

    final notificationsEnabled = await areNotificationsEnabled();
    debugPrint('📱 Notifications enabled: $notificationsEnabled');

    debugPrint('📋 Critical expiry items: ${_criticalExpiryItems.length}');

    try {
      final pendingNotifications =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('⏰ Pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Error checking pending notifications: $e');
    }

    debugPrint('📊 END STATUS REPORT 📊');
  }

  // Add a method to handle backup restart logic from UI
  Future<void> checkAndRestartNotificationsIfNeeded() async {
    final now = DateTime.now();
    debugPrint('🔄 Backup test timer triggered');

    if (!_isTestModeActive) {
      debugPrint('⚠️ Test mode not active, starting notifications');
      await startRecurringTestNotifications();
      return;
    }

    if (_lastNotificationTime != null) {
      final timeSinceLastNotification =
          now.difference(_lastNotificationTime!).inSeconds;
      debugPrint(
        '⏱️ Time since last notification activity: $timeSinceLastNotification seconds',
      );

      if (timeSinceLastNotification > 60) {
        debugPrint(
          '⚠️ Notifications appear to be stalled (${timeSinceLastNotification}s), force-restarting',
        );
        _isNotificationStalled = true;
        await startRecurringTestNotifications(forceRestart: true);
      } else {
        debugPrint(
          '✅ Notifications running normally, last activity ${timeSinceLastNotification}s ago',
        );
      }
    } else {
      debugPrint(
        '⚠️ No notification activity recorded, starting notifications',
      );
      await startRecurringTestNotifications();
    }
  }

  // New method to save food items locally for offline use
  Future<void> _saveLocalFoodItems(List<FoodItem> items) async {
    try {
      final storageService = StorageService();

      // Save all items to local storage - we need to convert from FoodItem to the storage format
      for (var item in items) {
        // Convert to the expected format for storage
        final Map<String, dynamic> itemJson = item.toJson();

        // Create storage-compatible item
        final Map<String, dynamic> storageItem = {
          'id': item.id,
          'name': item.name,
          'quantity': item.quantity.toString(),
          'expiryDate': item.expiryDate.toIso8601String(),
          'createdAt': item.createdAt.toIso8601String(),
        };

        // Store in local storage
        await _storeItemLocallyForNotifications(storageItem);
      }

      debugPrint(
        '✅ Saved ${items.length} items to local storage for offline notifications',
      );
    } catch (e) {
      debugPrint('❌ Error saving items to local storage: $e');
    }
  }

  // Helper method to store a single item in SharedPreferences for notifications
  Future<void> _storeItemLocallyForNotifications(
    Map<String, dynamic> item,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Use a specific key prefix for notification items
      final key = 'notification_item_${item['id']}';

      // Store as JSON string
      await prefs.setString(key, jsonEncode(item));
    } catch (e) {
      debugPrint('❌ Error storing item for notifications: $e');
    }
  }

  // New method to get expiring food items from local storage
  Future<List<FoodItem>> _getLocalExpiringFoodItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final List<FoodItem> expiringItems = [];

      // Get all keys that start with our notification prefix
      final allKeys = prefs.getKeys();
      final notificationKeys =
          allKeys.where((key) => key.startsWith('notification_item_')).toList();

      debugPrint(
        '📋 Found ${notificationKeys.length} items stored for notifications',
      );

      // Process each stored item
      for (var key in notificationKeys) {
        try {
          final jsonStr = prefs.getString(key);
          if (jsonStr != null) {
            final itemData = jsonDecode(jsonStr) as Map<String, dynamic>;

            // Parse the expiry date
            final expiryDate = DateTime.parse(itemData['expiryDate']);

            // Check if it's within our expiry window (0-6 days)
            final daysDiff = expiryDate.difference(now).inDays;
            if (daysDiff >= 0 && daysDiff <= 6) {
              // Create a FoodItem from the API model format
              final item = FoodItem(
                id: itemData['id'],
                name: itemData['name'],
                expiryDate: expiryDate,
                category: '',
                quantity: int.tryParse(itemData['quantity'] ?? '0') ?? 0,
                unit: '',
                status: 'active',
                isPackaged: false,
                userId: '',
                createdAt: DateTime.parse(itemData['createdAt']),
              );

              expiringItems.add(item);
            }
          }
        } catch (e) {
          debugPrint('❌ Error processing item $key: $e');
        }
      }

      debugPrint(
        '📋 Found ${expiringItems.length} locally stored items that are expiring soon',
      );
      return expiringItems;
    } catch (e) {
      debugPrint('❌ Error getting expiring items from local storage: $e');
      return [];
    }
  }

  // New method for hourly summary notification
  Future<void> showHourlySummaryNotification() async {
    try {
      debugPrint('🔔 Preparing hourly summary notification');

      // Get expiring items from local storage first
      List<FoodItem> expiringItems = [];

      try {
        // Try to get data from local storage
        expiringItems = await _getLocalExpiringFoodItems();
        debugPrint(
          '📋 Found ${expiringItems.length} expiring items in local storage',
        );
      } catch (e) {
        debugPrint('❌ Error getting expiring items from local storage: $e');
      }

      // Skip if no expiring items
      if (expiringItems.isEmpty) {
        debugPrint('ℹ️ No expiring items, skipping hourly notification');
        return;
      }

      // Count items by expiry timeframe
      int expiredCount = 0;
      int today = 0;
      int tomorrow = 0;
      int thisWeek = 0;

      final now = DateTime.now();

      for (var item in expiringItems) {
        final daysDiff = item.expiryDate.difference(now).inDays;

        if (daysDiff < 0) {
          expiredCount++;
        } else if (daysDiff == 0) {
          today++;
        } else if (daysDiff == 1) {
          tomorrow++;
        } else if (daysDiff <= 6) {
          thisWeek++;
        }
      }

      // Create summary message
      String summaryTitle = 'Pengingat Makanan Kadaluarsa';
      String summaryBody = '';

      if (expiredCount > 0) {
        summaryBody += '$expiredCount item telah kadaluarsa. ';
      }

      if (today > 0) {
        summaryBody += '$today item kadaluarsa hari ini. ';
      }

      if (tomorrow > 0) {
        summaryBody += '$tomorrow item kadaluarsa besok. ';
      }

      if (thisWeek > 0) {
        summaryBody += '$thisWeek item kadaluarsa minggu ini. ';
      }

      summaryBody += 'Periksa stok makanan Anda.';

      // Generate unique ID based on current hour
      final currentHour = DateTime.now().hour;
      final notificationId = 6000 + currentHour;

      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        'hourly_summary_channel',
        'Hourly Food Summary',
        channelDescription: 'Hourly reminders for expiring food items',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          summaryBody,
          contentTitle: summaryTitle,
          summaryText: '${expiringItems.length} items perlu perhatian',
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

      // Show notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        summaryTitle,
        summaryBody,
        platformDetails,
        payload: 'hourly_summary:${currentHour}',
      );

      debugPrint('✅ Hourly summary notification sent');
    } catch (e) {
      debugPrint('❌ Error showing hourly summary notification: $e');
    }
  }
}
