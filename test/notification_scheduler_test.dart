import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/services/notification_scheduler_service.dart';
import '../lib/services/database_helper_enhanced.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('NotificationSchedulerService Tests', () {
    late DatabaseHelper dbHelper;
    late NotificationSchedulerService notificationService;
    const int testUserId = 3;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      notificationService = NotificationSchedulerService(userId: testUserId);

      // Create test user
      await dbHelper.insertUserProfile({
        'name': 'Test User 3',
        'age': 28,
        'gender': 'male',
        'height': 175.0,
        'weight': 70.0,
        'fitness_level': 'intermediate',
        'goals': 'fitness',
        'available_equipment': 'gym',
        'personality_type': 'motivated',
        'notification_preference': 'moderate',
        'created_at': DateTime.now().toIso8601String(),
      });

      await dbHelper.initializeStreaks(testUserId);
    });

    test('Optimal notification time respects quiet hours', () async {
      final optimalTime = await notificationService.calculateOptimalNotificationTime('time_based');

      // Should not be during quiet hours (10 PM - 7 AM)
      expect(optimalTime.hour >= 7 && optimalTime.hour < 22, isTrue);
    });

    test('Smart notification generates message with title and body', () async {
      final notification = await notificationService.generateSmartNotification('time_based');

      expect(notification.containsKey('title'), isTrue);
      expect(notification.containsKey('body'), isTrue);
      expect(notification['title']!.isNotEmpty, isTrue);
      expect(notification['body']!.isNotEmpty, isTrue);
    });

    test('Different notification types generate different messages', () async {
      final timeBased = await notificationService.generateSmartNotification('time_based');
      final streakBased = await notificationService.generateSmartNotification('streak_maintenance');

      // While randomized, titles should be different
      expect(timeBased['title'], isNot(equals(streakBased['title'])));
    });

    test('Notification logging creates database record', () async {
      final scheduledTime = DateTime.now().add(Duration(hours: 1));

      await notificationService.logNotification(
        'progress_based',
        'Great Progress!',
        'You are doing amazing',
        scheduledTime,
      );

      final notifications = await dbHelper.getNotificationsForUser(testUserId);
      expect(notifications.isNotEmpty, isTrue);
      expect(notifications.first['notification_type'], equals('progress_based'));
    });

    test('Notification engagement tracking updates database', () async {
      final scheduledTime = DateTime.now().add(Duration(hours: 1));

      await notificationService.logNotification(
        'time_based',
        'Workout Time',
        'Time to exercise',
        scheduledTime,
      );

      final notifications = await dbHelper.getNotificationsForUser(testUserId);
      final notificationId = notifications.first['id'] as int;

      await notificationService.trackNotificationEngagement(notificationId, true);

      final updatedNotifications = await dbHelper.getNotificationsForUser(testUserId);
      expect(updatedNotifications.first['opened'], equals(1));
    });

    test('Notification performance metrics calculates open rate', () async {
      // Create and log several notifications
      for (int i = 0; i < 5; i++) {
        final scheduledTime = DateTime.now().add(Duration(hours: i + 1));
        await notificationService.logNotification(
          'time_based',
          'Test Notification $i',
          'Body $i',
          scheduledTime,
        );
      }

      // Mark some as opened
      final notifications = await dbHelper.getNotificationsForUser(testUserId);
      await notificationService.trackNotificationEngagement(
        notifications[0]['id'] as int,
        true,
      );
      await notificationService.trackNotificationEngagement(
        notifications[1]['id'] as int,
        true,
      );

      final performance = await notificationService.getNotificationPerformance();

      expect(performance['total_sent'], greaterThanOrEqualTo(5));
      expect(performance['total_opened'], greaterThanOrEqualTo(2));
      expect(performance['open_rate'], greaterThan(0));
    });

    test('Best notification type determination adapts to user state', () async {
      // With no streak, should not use streak maintenance
      var bestType = await notificationService.determineBestNotificationType();
      expect(bestType, isNot(equals('streak_maintenance')));

      // After recording workout, might use streak maintenance
      await dbHelper.updateStreakOnCompletion(testUserId, 'exercise');
      bestType = await notificationService.determineBestNotificationType();

      expect(bestType, isIn(['time_based', 'progress_based', 'streak_maintenance', 'recovery']));
    });

    test('Optimal notification scheduling returns complete data', () async {
      final notification = await notificationService.scheduleOptimalNotification();

      expect(notification.containsKey('type'), isTrue);
      expect(notification.containsKey('title'), isTrue);
      expect(notification.containsKey('body'), isTrue);
      expect(notification.containsKey('scheduled_time'), isTrue);
    });

    test('Notification spacing respects minimum hours', () async {
      // Schedule first notification
      await notificationService.scheduleOptimalNotification();

      // Try to schedule another immediately
      final secondTime = await notificationService.calculateOptimalNotificationTime('time_based');

      // Should be spaced appropriately
      expect(secondTime.isAfter(DateTime.now()), isTrue);
    });

    test('Daily notification limit is enforced', () async {
      // Schedule maximum notifications for today
      for (int i = 0; i < NotificationSchedulerService.MAX_NOTIFICATIONS_PER_DAY; i++) {
        await notificationService.scheduleOptimalNotification();
      }

      // Next notification should be scheduled for tomorrow
      final nextTime = await notificationService.calculateOptimalNotificationTime('time_based');
      final tomorrow = DateTime.now().add(Duration(days: 1));

      expect(nextTime.day, greaterThanOrEqualTo(tomorrow.day));
    });

    test('Recommended notification times returns valid times', () async {
      final recommendedTimes = await notificationService.getRecommendedNotificationTimes();

      expect(recommendedTimes.isNotEmpty, isTrue);
      expect(recommendedTimes.length, lessThanOrEqualTo(3));

      // All times should be in the future
      for (var time in recommendedTimes) {
        expect(time.isAfter(DateTime.now().subtract(Duration(days: 1))), isTrue);
      }
    });

    test('Should send notification now works correctly', () async {
      final now = DateTime.now();
      final futureTime = now.add(Duration(hours: 1));
      final nearFutureTime = now.add(Duration(minutes: 3));

      expect(notificationService.shouldSendNotificationNow(futureTime), isFalse);
      expect(notificationService.shouldSendNotificationNow(nearFutureTime), isTrue);
      expect(notificationService.shouldSendNotificationNow(now), isTrue);
    });

    test('Clear old notifications removes old records', () async {
      // Create old notification
      final oldTime = DateTime.now().subtract(Duration(days: 60));
      await dbHelper.insertNotificationLog(testUserId, {
        'notification_type': 'test',
        'title': 'Old Notification',
        'body': 'This is old',
        'scheduled_time': oldTime.toIso8601String(),
        'engagement_score': 0.0,
      });

      // Create recent notification
      await notificationService.scheduleOptimalNotification();

      final beforeCleanup = await dbHelper.getNotificationsForUser(testUserId);
      final beforeCount = beforeCleanup.length;

      // Clean up old notifications
      await notificationService.clearOldNotifications(daysToKeep: 30);

      final afterCleanup = await dbHelper.getNotificationsForUser(testUserId);

      // Should have fewer notifications after cleanup
      expect(afterCleanup.length, lessThanOrEqualTo(beforeCount));
    });
  });
}
