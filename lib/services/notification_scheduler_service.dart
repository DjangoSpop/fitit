import 'dart:math';
import 'database_helper_enhanced.dart';

class NotificationSchedulerService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  static const int MAX_NOTIFICATIONS_PER_DAY = 3;
  static const int MIN_SPACING_HOURS = 4;
  static const int QUIET_HOURS_START = 22; // 10 PM
  static const int QUIET_HOURS_END = 7; // 7 AM

  NotificationSchedulerService({required this.userId});

  // Calculate optimal notification time
  Future<DateTime> calculateOptimalNotificationTime(
    String notificationType,
  ) async {
    final past24Hours = DateTime.now().subtract(Duration(hours: 24));

    // Get today's notification history
    final todayNotifications = await _dbHelper.getNotificationHistory(
      userId,
      past24Hours,
    );

    // Respect quiet hours
    var suggestedTime = DateTime.now().add(Duration(hours: 2));
    if (suggestedTime.hour >= QUIET_HOURS_START ||
        suggestedTime.hour < QUIET_HOURS_END) {
      suggestedTime = DateTime(
        suggestedTime.year,
        suggestedTime.month,
        suggestedTime.day,
        QUIET_HOURS_END + 1,
      );
    }

    // Check notification frequency
    if (todayNotifications.length >= MAX_NOTIFICATIONS_PER_DAY) {
      return suggestedTime.add(Duration(days: 1));
    }

    // Space out notifications
    if (todayNotifications.isNotEmpty) {
      final lastNotification = DateTime.parse(
        todayNotifications.last['scheduled_time'] as String,
      );
      final timeSinceLastNotification =
          suggestedTime.difference(lastNotification).inHours;

      if (timeSinceLastNotification < MIN_SPACING_HOURS) {
        suggestedTime =
            lastNotification.add(Duration(hours: MIN_SPACING_HOURS));
      }
    }

    return suggestedTime;
  }

  // Generate smart notification message
  Future<Map<String, String>> generateSmartNotification(
    String notificationType,
  ) async {
    final messages = {
      'time_based': [
        'It\'s go time. 15 minutes now? You\'ve got this.',
        '${_getTimeOfDayGreeting()} energy check: Ready for a quick workout?',
        'Your body\'s ready. Your mind? Let\'s convince it. 🚀',
      ],
      'progress_based': [
        'You\'ve crushed ${Random().nextInt(5) + 3} workouts this week. One more?',
        '🔥 Your streak is real. Keep it alive today.',
        'The streak gods are watching. Don\'t disappoint them.',
      ],
      'streak_maintenance': [
        'Your ${await _getCurrentStreak()}-day streak doesn\'t end today. Let\'s keep it.',
        'One workout. That\'s it. Keep the streak alive.',
        'Easy choice: Workout or lose the streak? 💪',
      ],
      'recovery': [
        'You\'ve earned a recovery day. Stretch or rest?',
        'Listen to your body. Rest when needed, comeback stronger.',
        'Recovery is part of the process. Good work this week.',
      ],
    };

    final typeMessages = messages[notificationType] ?? messages['time_based']!;
    final random = Random();
    final selectedMessage = typeMessages[random.nextInt(typeMessages.length)];

    return {
      'title': _getTitleForType(notificationType),
      'body': selectedMessage,
    };
  }

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 18) return 'Afternoon';
    return 'Evening';
  }

  Future<int> _getCurrentStreak() async {
    final streak = await _dbHelper.getStreakData(userId, 'exercise');
    return streak?['current_streak'] as int? ?? 0;
  }

  String _getTitleForType(String type) {
    const titles = {
      'time_based': 'Workout Time',
      'progress_based': 'You\'re Killing It',
      'streak_maintenance': 'Streak Alert',
      'recovery': 'Recovery Day',
    };
    return titles[type] ?? 'Fitness Check-In';
  }

  // Log notification delivery and engagement
  Future<void> logNotification(
    String notificationType,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    await _dbHelper.insertNotificationLog(
      userId,
      {
        'notification_type': notificationType,
        'title': title,
        'body': body,
        'scheduled_time': scheduledTime.toIso8601String(),
        'engagement_score': 0.0, // Updated when opened
      },
    );
  }

  // Track notification engagement for learning
  Future<void> trackNotificationEngagement(
    int notificationId,
    bool wasOpened,
  ) async {
    await _dbHelper.updateNotificationEngagement(
      notificationId,
      wasOpened,
      DateTime.now(),
    );
  }

  // Get notification performance metrics
  Future<Map<String, dynamic>> getNotificationPerformance() async {
    final allNotifications = await _dbHelper.getNotificationsForUser(userId);

    final totalSent = allNotifications.length;
    final totalOpened =
        allNotifications.where((n) => n['opened'] == 1).length;

    final openRate = totalSent > 0 ? (totalOpened / totalSent) : 0.0;

    // Group by type for granular analysis
    final performanceByType = <String, Map<String, dynamic>>{};

    for (var notification in allNotifications) {
      final type = notification['notification_type'] as String;

      if (!performanceByType.containsKey(type)) {
        performanceByType[type] = {
          'sent': 0,
          'opened': 0,
          'engagement_score': 0.0,
        };
      }

      performanceByType[type]!['sent'] =
          (performanceByType[type]!['sent'] as int) + 1;
      if (notification['opened'] == 1) {
        performanceByType[type]!['opened'] =
            (performanceByType[type]!['opened'] as int) + 1;
      }
    }

    // Calculate open rates for each type
    performanceByType.forEach((type, data) {
      final sent = data['sent'] as int;
      final opened = data['opened'] as int;
      data['open_rate'] = sent > 0 ? (opened / sent) : 0.0;
    });

    return {
      'total_sent': totalSent,
      'total_opened': totalOpened,
      'open_rate': openRate,
      'performance_by_type': performanceByType,
    };
  }

  // Determine best notification type based on user state
  Future<String> determineBestNotificationType() async {
    final streak = await _dbHelper.getStreakData(userId, 'exercise');
    final currentStreak = streak?['current_streak'] as int? ?? 0;
    final lastCompleted = streak?['last_completed'];

    // If user has a streak and hasn't completed today, use streak maintenance
    if (currentStreak > 0 && lastCompleted != null) {
      final lastDate = DateTime.parse(lastCompleted as String);
      final today = DateTime.now();

      if (lastDate.year != today.year ||
          lastDate.month != today.month ||
          lastDate.day != today.day) {
        return 'streak_maintenance';
      }
    }

    // If user has good weekly completion, use progress-based
    final weeklyHabits = await _dbHelper.getWeeklyHabits(userId);
    final weeklyCompletion = weeklyHabits
        .where((h) => h['exercise_completed'] == 1)
        .length;

    if (weeklyCompletion >= 4) {
      return 'progress_based';
    }

    // Check if it's a designated recovery day
    final dayOfWeek = DateTime.now().weekday;
    if (dayOfWeek == 7) { // Sunday
      return 'recovery';
    }

    // Default to time-based
    return 'time_based';
  }

  // Schedule optimal notification
  Future<Map<String, dynamic>> scheduleOptimalNotification() async {
    final notificationType = await determineBestNotificationType();
    final scheduledTime = await calculateOptimalNotificationTime(notificationType);
    final notification = await generateSmartNotification(notificationType);

    await logNotification(
      notificationType,
      notification['title']!,
      notification['body']!,
      scheduledTime,
    );

    return {
      'type': notificationType,
      'title': notification['title'],
      'body': notification['body'],
      'scheduled_time': scheduledTime.toIso8601String(),
    };
  }

  // Check if notification should be sent now
  bool shouldSendNotificationNow(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now).inMinutes;

    // Send if within 5 minutes of scheduled time
    return difference.abs() <= 5;
  }

  // Get recommended notification times based on user patterns
  Future<List<DateTime>> getRecommendedNotificationTimes() async {
    final notifications = await _dbHelper.getNotificationsForUser(userId);

    // Analyze when user typically opens notifications
    final openedNotifications = notifications.where((n) => n['opened'] == 1);

    final hourCounts = <int, int>{};
    for (var notification in openedNotifications) {
      final openedTime = notification['opened_time'];
      if (openedTime != null) {
        final hour = DateTime.parse(openedTime as String).hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }
    }

    // Find top 3 hours
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topHours = sortedHours.take(3).map((e) => e.key).toList();

    // If no history, use default times
    if (topHours.isEmpty) {
      return [
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 0),
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 14, 0),
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 18, 0),
      ];
    }

    // Create DateTime objects for recommended times
    return topHours.map((hour) {
      final now = DateTime.now();
      var recommendedTime = DateTime(now.year, now.month, now.day, hour, 0);

      // If time has passed today, schedule for tomorrow
      if (recommendedTime.isBefore(now)) {
        recommendedTime = recommendedTime.add(Duration(days: 1));
      }

      return recommendedTime;
    }).toList();
  }

  // Clear old notifications (cleanup function)
  Future<void> clearOldNotifications({int daysToKeep = 30}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    await db.delete(
      'notifications_log',
      where: 'user_id = ? AND scheduled_time < ?',
      whereArgs: [userId, cutoffDate.toIso8601String()],
    );
  }
}
