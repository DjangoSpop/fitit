import 'dart:math';
import '../services/database_helper_enhanced.dart';

class HabitFormationEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  HabitFormationEngine({required this.userId});

  // Psychological badge achievement logic
  Future<List<String>> checkBadgeAchievements() async {
    final badges = <String>[];

    // Get current streak data
    final exerciseStreak = await _dbHelper.getStreakData(userId, 'exercise');
    final totalCompletions = exerciseStreak?['total_completions'] as int? ?? 0;
    final currentStreak = exerciseStreak?['current_streak'] as int? ?? 0;

    // Award badges based on milestones
    if (currentStreak == 7) {
      await _dbHelper.awardAchievement(
        userId,
        'consistency_7',
        'Week Warrior',
        'Completed workouts for 7 consecutive days!',
      );
      badges.add('consistency_7');
    }

    if (currentStreak == 30) {
      await _dbHelper.awardAchievement(
        userId,
        'month_master',
        'Month Master',
        'You\'ve built a 30-day habit. You\'re unstoppable!',
      );
      badges.add('month_master');
    }

    if (currentStreak == 100) {
      await _dbHelper.awardAchievement(
        userId,
        'year_champion',
        'Year Champion',
        '100 days of consistency. You\'re a fitness legend.',
      );
      badges.add('year_champion');
    }

    if (totalCompletions == 1) {
      await _dbHelper.awardAchievement(
        userId,
        'first_workout',
        'First Step',
        'Your fitness journey begins here!',
      );
      badges.add('first_workout');
    }

    return badges;
  }

  // Generate identity-based coaching message
  Future<String> generateIdentityMessage() async {
    final streak = await _dbHelper.getStreakData(userId, 'exercise');
    final currentStreak = streak?['current_streak'] as int? ?? 0;

    final messages = [
      "You're an exerciser now. Today's another day to prove it.",
      "Your body remembers the last $currentStreak days. Let's keep the momentum.",
      "Champions don't skip. You're building that identity today.",
      "That $currentStreak-day streak? That's who you are now.",
      "Your future self is grateful for what you're doing today.",
    ];

    final random = Random();
    return messages[random.nextInt(messages.length)];
  }

  // Calculate streak-based motivation level
  Future<double> calculateMotivationLevel() async {
    final streak = await _dbHelper.getStreakData(userId, 'exercise');
    final currentStreak = streak?['current_streak'] as int? ?? 0;

    // Scale: 0.0 (low) to 1.0 (high)
    if (currentStreak >= 30) return 0.95;
    if (currentStreak >= 14) return 0.85;
    if (currentStreak >= 7) return 0.75;
    if (currentStreak >= 3) return 0.65;
    if (currentStreak >= 1) return 0.55;
    return 0.3;
  }

  // Implement Variable Reward Schedule
  Future<Map<String, dynamic>> generateVariableReward() async {
    final random = Random();
    final randomValue = random.nextInt(100);

    if (randomValue < 60) {
      // 60%: Predictable praise
      return {
        'type': 'predictable_praise',
        'message': 'Great work! You\'re building consistency.',
        'intensity': 'low',
      };
    } else if (randomValue < 90) {
      // 30%: Special achievement/badge
      return {
        'type': 'achievement',
        'message': '🎉 You\'ve unlocked a new badge!',
        'intensity': 'medium',
      };
    } else {
      // 10%: Surprise bonus
      return {
        'type': 'surprise_bonus',
        'message': '🏆 BONUS: Double streak today! You\'re crushing it!',
        'intensity': 'high',
      };
    }
  }

  // Generate implementation intention prompts
  Future<String> generateImplementationIntention() async {
    final hour = DateTime.now().hour;

    const intentions = {
      'morning': 'If you finish breakfast, then do 10 minutes of stretching, because flexibility supports your identity.',
      'afternoon': 'If you get home from work, then change into workout clothes, because action creates momentum.',
      'evening': 'If you finish dinner, then complete your workout, because consistency builds champions.',
    };

    String timeCategory = 'afternoon';
    if (hour >= 5 && hour < 12) {
      timeCategory = 'morning';
    } else if (hour >= 12 && hour < 18) {
      timeCategory = 'afternoon';
    } else {
      timeCategory = 'evening';
    }

    return intentions[timeCategory] ?? intentions['afternoon']!;
  }

  // Loss aversion framing
  Future<String> generateLossAversionMessage() async {
    final streak = await _dbHelper.getStreakData(userId, 'exercise');
    final currentStreak = streak?['current_streak'] as int? ?? 0;

    if (currentStreak >= 7) {
      return 'Your $currentStreak-day streak is on the line. One workout keeps it alive.';
    } else if (currentStreak >= 1) {
      return 'Don\'t break your $currentStreak-day streak today. You\'ve got this!';
    } else {
      return 'Today is day 1 of a new streak. Start now.';
    }
  }

  // Weekly reflection prompt
  Future<Map<String, dynamic>> generateWeeklyReflection() async {
    final weeklyHabits = await _dbHelper.getWeeklyHabits(userId);

    final exerciseCompletions = weeklyHabits
        .where((h) => h['exercise_completed'] == 1)
        .length;

    final mealCompletions = weeklyHabits
        .where((h) => h['meal_logged'] == 1)
        .length;

    final completionRate = (exerciseCompletions / 7 * 100).round();

    return {
      'week_summary': 'You completed $exerciseCompletions workouts this week.',
      'meal_adherence': 'Meal logging: $mealCompletions days',
      'completion_rate': '$completionRate%',
      'reflection_question': completionRate >= 80
          ? 'What\'s working? Keep this momentum!'
          : 'What barriers are holding you back? Let\'s problem-solve.',
      'next_week_focus': completionRate < 50
          ? 'Focus on consistency over intensity. Pick 3 days next week.'
          : 'You\'re ready for the next level. Let\'s increase the challenge.',
    };
  }

  // Get all streaks for dashboard display
  Future<Map<String, Map<String, dynamic>>> getAllStreaks() async {
    final habits = ['exercise', 'meal_logging', 'weight_tracking'];
    final streaks = <String, Map<String, dynamic>>{};

    for (String habit in habits) {
      final streak = await _dbHelper.getStreakData(userId, habit);
      if (streak != null) {
        streaks[habit] = streak;
      }
    }

    return streaks;
  }

  // Check if user is at risk of dropping off
  Future<bool> isAtDropoffRisk() async {
    final streak = await _dbHelper.getStreakData(userId, 'exercise');
    final lastCompleted = streak?['last_completed'];

    if (lastCompleted == null) return true;

    final lastDate = DateTime.parse(lastCompleted as String);
    final daysSinceLastWorkout = DateTime.now().difference(lastDate).inDays;

    // User is at risk if they haven't completed a workout in 2+ days
    return daysSinceLastWorkout >= 2;
  }

  // Generate personalized motivation based on user state
  Future<String> generatePersonalizedMotivation() async {
    final isAtRisk = await isAtDropoffRisk();
    final motivationLevel = await calculateMotivationLevel();
    final streak = await _dbHelper.getStreakData(userId, 'exercise');
    final currentStreak = streak?['current_streak'] as int? ?? 0;

    if (isAtRisk && currentStreak > 0) {
      return await generateLossAversionMessage();
    } else if (motivationLevel > 0.7) {
      return await generateIdentityMessage();
    } else {
      return await generateImplementationIntention();
    }
  }

  // Record workout completion and update streaks
  Future<void> recordWorkoutCompletion() async {
    await _dbHelper.updateStreakOnCompletion(userId, 'exercise');

    // Log daily habit
    await _dbHelper.logDailyHabit(userId, {
      'exercise_completed': 1,
      'meal_logged': 0,
      'water_goal_met': 0,
      'mood_rating': null,
      'energy_level': null,
      'notes': null,
    });

    // Check for new badge achievements
    await checkBadgeAchievements();
  }

  // Get motivational stats for display
  Future<Map<String, dynamic>> getMotivationalStats() async {
    final exerciseStreak = await _dbHelper.getStreakData(userId, 'exercise');
    final achievements = await _dbHelper.getUserAchievements(userId);
    final weeklyHabits = await _dbHelper.getWeeklyHabits(userId);

    final currentStreak = exerciseStreak?['current_streak'] as int? ?? 0;
    final longestStreak = exerciseStreak?['longest_streak'] as int? ?? 0;
    final totalWorkouts = exerciseStreak?['total_completions'] as int? ?? 0;

    final weeklyCompletion = weeklyHabits
        .where((h) => h['exercise_completed'] == 1)
        .length;

    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_workouts': totalWorkouts,
      'weekly_completion': weeklyCompletion,
      'total_badges': achievements.length,
      'motivation_level': await calculateMotivationLevel(),
    };
  }
}
