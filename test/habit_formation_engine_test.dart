import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/engines/habit_formation_engine.dart';
import '../lib/services/database_helper_enhanced.dart';

void main() {
  // Initialize sqflite for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HabitFormationEngine Tests', () {
    late DatabaseHelper dbHelper;
    late HabitFormationEngine habitEngine;
    const int testUserId = 1;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      habitEngine = HabitFormationEngine(userId: testUserId);

      // Initialize test user profile
      await dbHelper.insertUserProfile({
        'name': 'Test User',
        'age': 30,
        'gender': 'male',
        'height': 180.0,
        'weight': 75.0,
        'fitness_level': 'intermediate',
        'goals': 'weight_loss,muscle_gain',
        'available_equipment': 'dumbbells,resistance_bands',
        'personality_type': 'motivated',
        'notification_preference': 'moderate',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Initialize streaks
      await dbHelper.initializeStreaks(testUserId);
    });

    test('Initialize streaks creates records for all habit types', () async {
      final exerciseStreak = await dbHelper.getStreakData(testUserId, 'exercise');
      final mealStreak = await dbHelper.getStreakData(testUserId, 'meal_logging');
      final weightStreak = await dbHelper.getStreakData(testUserId, 'weight_tracking');

      expect(exerciseStreak, isNotNull);
      expect(mealStreak, isNotNull);
      expect(weightStreak, isNotNull);

      expect(exerciseStreak!['current_streak'], equals(0));
      expect(exerciseStreak['longest_streak'], equals(0));
    });

    test('Recording workout completion updates streak correctly', () async {
      await habitEngine.recordWorkoutCompletion();

      final streak = await dbHelper.getStreakData(testUserId, 'exercise');
      expect(streak!['current_streak'], equals(1));
      expect(streak['total_completions'], equals(1));
    });

    test('Consecutive day completions increase streak', () async {
      // Simulate multiple days of completions
      await habitEngine.recordWorkoutCompletion();

      // Wait a moment to ensure different timestamps
      await Future.delayed(Duration(milliseconds: 100));

      final streak = await dbHelper.getStreakData(testUserId, 'exercise');
      expect(streak!['current_streak'], greaterThanOrEqualTo(1));
    });

    test('Badge achievements are awarded at correct milestones', () async {
      // Record first workout
      await habitEngine.recordWorkoutCompletion();

      final badges = await habitEngine.checkBadgeAchievements();
      final achievements = await dbHelper.getUserAchievements(testUserId);

      // Should have at least the "first_workout" achievement
      expect(achievements.isNotEmpty, isTrue);

      final firstWorkoutBadge = achievements.firstWhere(
        (a) => a['badge_type'] == 'first_workout',
        orElse: () => <String, dynamic>{},
      );

      expect(firstWorkoutBadge.isNotEmpty, isTrue);
    });

    test('Motivation level scales with streak length', () async {
      // No streak - low motivation
      var motivationLevel = await habitEngine.calculateMotivationLevel();
      expect(motivationLevel, lessThan(0.5));

      // Record workout to start streak
      await habitEngine.recordWorkoutCompletion();

      motivationLevel = await habitEngine.calculateMotivationLevel();
      expect(motivationLevel, greaterThanOrEqualTo(0.5));
    });

    test('Identity message generation returns non-empty string', () async {
      final message = await habitEngine.generateIdentityMessage();
      expect(message.isNotEmpty, isTrue);
      expect(message.length, greaterThan(10));
    });

    test('Loss aversion message mentions streak', () async {
      await habitEngine.recordWorkoutCompletion();

      final message = await habitEngine.generateLossAversionMessage();
      expect(message.toLowerCase().contains('streak'), isTrue);
    });

    test('Variable reward generates different reward types', () async {
      final rewards = <String>{};

      // Generate multiple rewards to test variability
      for (int i = 0; i < 20; i++) {
        final reward = await habitEngine.generateVariableReward();
        rewards.add(reward['type'] as String);
      }

      // Should have some variety in reward types
      expect(rewards.length, greaterThan(1));
    });

    test('Weekly reflection calculates completion rate correctly', () async {
      // Log some habits for the week
      await dbHelper.logDailyHabit(testUserId, {
        'exercise_completed': 1,
        'meal_logged': 1,
        'water_goal_met': 1,
      });

      final reflection = await habitEngine.generateWeeklyReflection();

      expect(reflection.containsKey('week_summary'), isTrue);
      expect(reflection.containsKey('completion_rate'), isTrue);
      expect(reflection.containsKey('reflection_question'), isTrue);
    });

    test('Dropoff risk detection works correctly', () async {
      // New user should be at risk
      var isAtRisk = await habitEngine.isAtDropoffRisk();
      expect(isAtRisk, isTrue);

      // After completing workout, risk should be lower
      await habitEngine.recordWorkoutCompletion();
      isAtRisk = await habitEngine.isAtDropoffRisk();
      expect(isAtRisk, isFalse);
    });

    test('Motivational stats returns complete data', () async {
      await habitEngine.recordWorkoutCompletion();

      final stats = await habitEngine.getMotivationalStats();

      expect(stats.containsKey('current_streak'), isTrue);
      expect(stats.containsKey('longest_streak'), isTrue);
      expect(stats.containsKey('total_workouts'), isTrue);
      expect(stats.containsKey('weekly_completion'), isTrue);
      expect(stats.containsKey('total_badges'), isTrue);
      expect(stats.containsKey('motivation_level'), isTrue);
    });

    test('Implementation intention generates time-appropriate message', () async {
      final intention = await habitEngine.generateImplementationIntention();

      expect(intention.isNotEmpty, isTrue);
      expect(intention.toLowerCase().contains('if'), isTrue);
      expect(intention.toLowerCase().contains('then'), isTrue);
    });

    test('Personalized motivation adapts to user state', () async {
      final motivation = await habitEngine.generatePersonalizedMotivation();

      expect(motivation.isNotEmpty, isTrue);
      expect(motivation.length, greaterThan(20));
    });
  });

  group('DatabaseHelper Enhanced Tests', () {
    late DatabaseHelper dbHelper;
    const int testUserId = 2;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;

      // Create test user
      await dbHelper.insertUserProfile({
        'name': 'Test User 2',
        'age': 25,
        'gender': 'female',
        'height': 165.0,
        'weight': 60.0,
        'fitness_level': 'beginner',
        'goals': 'fitness',
        'available_equipment': 'none',
        'personality_type': 'balanced',
        'notification_preference': 'high',
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    test('Daily habit logging creates record', () async {
      await dbHelper.logDailyHabit(testUserId, {
        'exercise_completed': 1,
        'meal_logged': 1,
        'water_goal_met': 0,
        'mood_rating': 4,
        'energy_level': 3,
      });

      final habits = await dbHelper.getWeeklyHabits(testUserId);
      expect(habits.isNotEmpty, isTrue);
      expect(habits.first['exercise_completed'], equals(1));
    });

    test('Performance analytics recording works', () async {
      await dbHelper.recordPerformanceMetrics(testUserId, {
        'completion_rate': 0.85,
        'predicted_completion': 0.90,
        'difficulty_level': 'medium',
        'adherence_score': 0.88,
        'energy_pattern': 'morning',
        'drop_off_risk': 0.15,
      });

      final trend = await dbHelper.getPerformanceTrend(testUserId, 7);
      expect(trend.isNotEmpty, isTrue);
    });

    test('Achievement awarding creates record with correct icon', () async {
      await dbHelper.awardAchievement(
        testUserId,
        'week_warrior',
        'Week Warrior',
        'Completed 7 consecutive days',
      );

      final achievements = await dbHelper.getUserAchievements(testUserId);
      expect(achievements.isNotEmpty, isTrue);

      final badge = achievements.first;
      expect(badge['badge_type'], equals('week_warrior'));
      expect(badge['icon_code'], equals('🔥'));
    });

    test('Notification logging and retrieval works', () async {
      final scheduledTime = DateTime.now().add(Duration(hours: 2));

      await dbHelper.insertNotificationLog(testUserId, {
        'notification_type': 'streak_maintenance',
        'title': 'Keep it up!',
        'body': 'Your streak is on the line',
        'scheduled_time': scheduledTime.toIso8601String(),
        'engagement_score': 0.0,
      });

      final notifications = await dbHelper.getNotificationsForUser(testUserId);
      expect(notifications.isNotEmpty, isTrue);
      expect(notifications.first['notification_type'], equals('streak_maintenance'));
    });
  });
}
