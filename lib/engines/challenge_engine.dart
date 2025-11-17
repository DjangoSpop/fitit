import 'dart:math';
import '../services/database_helper_enhanced.dart';
import 'gamification_engine.dart';

/// Challenge Engine - Daily and Weekly Challenges! 🎯
class ChallengeEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;
  late GamificationEngine _gamificationEngine;

  ChallengeEngine({required this.userId}) {
    _gamificationEngine = GamificationEngine(userId: userId);
  }

  // Challenge Templates
  static const List<Map<String, dynamic>> DAILY_CHALLENGES = [
    {
      'id': 'perfect_day',
      'name': 'Perfect Day',
      'description': 'Complete all 3 daily habits',
      'difficulty': 'medium',
      'xp_reward': 150,
      'icon': '🌟',
      'type': 'completion',
    },
    {
      'id': 'early_bird',
      'name': 'Early Bird',
      'description': 'Complete workout before 10 AM',
      'difficulty': 'medium',
      'xp_reward': 100,
      'icon': '🌅',
      'type': 'time_based',
    },
    {
      'id': 'double_workout',
      'name': 'Double Down',
      'description': 'Complete 2 workouts in one day',
      'difficulty': 'hard',
      'xp_reward': 200,
      'icon': '💪',
      'type': 'quantity',
    },
    {
      'id': 'hydration_hero',
      'name': 'Hydration Hero',
      'description': 'Drink 8 glasses of water',
      'difficulty': 'easy',
      'xp_reward': 75,
      'icon': '💧',
      'type': 'quantity',
    },
    {
      'id': 'meal_master',
      'name': 'Meal Master',
      'description': 'Log all 3 meals today',
      'difficulty': 'easy',
      'xp_reward': 80,
      'icon': '🍽️',
      'type': 'quantity',
    },
    {
      'id': 'speed_demon',
      'name': 'Speed Demon',
      'description': 'Complete workout in under 30 minutes',
      'difficulty': 'hard',
      'xp_reward': 175,
      'icon': '⚡',
      'type': 'performance',
    },
    {
      'id': 'consistency_king',
      'name': 'Consistency King',
      'description': 'Maintain 5+ day streak',
      'difficulty': 'medium',
      'xp_reward': 125,
      'icon': '🔥',
      'type': 'streak',
    },
  ];

  static const List<Map<String, dynamic>> WEEKLY_CHALLENGES = [
    {
      'id': 'workout_warrior',
      'name': 'Workout Warrior',
      'description': 'Complete 7 workouts this week',
      'difficulty': 'hard',
      'xp_reward': 500,
      'icon': '⚔️',
      'target': 7,
      'type': 'workout_count',
    },
    {
      'id': 'perfect_week',
      'name': 'Perfect Week',
      'description': 'Complete all habits every day this week',
      'difficulty': 'legendary',
      'xp_reward': 1000,
      'icon': '👑',
      'type': 'perfect_week',
    },
    {
      'id': 'meal_tracker',
      'name': 'Meal Tracker Pro',
      'description': 'Log meals 21 times (3/day x 7 days)',
      'difficulty': 'medium',
      'xp_reward': 300,
      'icon': '📊',
      'target': 21,
      'type': 'meal_count',
    },
    {
      'id': 'streak_master',
      'name': 'Streak Master',
      'description': 'Maintain streak for entire week',
      'difficulty': 'medium',
      'xp_reward': 350,
      'icon': '🔥',
      'type': 'streak_maintain',
    },
    {
      'id': 'social_butterfly',
      'name': 'Social Butterfly',
      'description': 'Share 3 achievements with friends',
      'difficulty': 'easy',
      'xp_reward': 200,
      'icon': '🦋',
      'target': 3,
      'type': 'social',
    },
  ];

  /// Generate daily challenge
  Future<Map<String, dynamic>> generateDailyChallenge() async {
    final db = await _dbHelper.database;

    // Create table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        challenge_id TEXT,
        challenge_data TEXT,
        date TEXT,
        completed INTEGER DEFAULT 0,
        progress INTEGER DEFAULT 0,
        xp_reward INTEGER,
        completed_at TEXT
      )
    ''');

    // Check if today's challenge exists
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing = await db.query(
      'daily_challenges',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );

    if (existing.isNotEmpty) {
      // Return existing challenge
      final challengeData = existing.first;
      final template = DAILY_CHALLENGES.firstWhere(
        (c) => c['id'] == challengeData['challenge_id'],
        orElse: () => DAILY_CHALLENGES[0],
      );

      return {
        ...template,
        'progress': challengeData['progress'],
        'completed': challengeData['completed'] == 1,
        'db_id': challengeData['id'],
      };
    }

    // Generate new challenge
    final userStats = await _gamificationEngine.getUserGameStats();
    final level = userStats['level'] as int;

    // Pick appropriate difficulty based on level
    List<Map<String, dynamic>> availableChallenges;
    if (level >= 20) {
      availableChallenges = DAILY_CHALLENGES;
    } else if (level >= 10) {
      availableChallenges = DAILY_CHALLENGES
          .where((c) => c['difficulty'] != 'legendary')
          .toList();
    } else {
      availableChallenges = DAILY_CHALLENGES
          .where((c) => c['difficulty'] == 'easy' || c['difficulty'] == 'medium')
          .toList();
    }

    // Pick random challenge
    final random = Random();
    final challenge = availableChallenges[random.nextInt(availableChallenges.length)];

    // Insert into database
    await db.insert('daily_challenges', {
      'user_id': userId,
      'challenge_id': challenge['id'],
      'challenge_data': challenge.toString(),
      'date': today,
      'completed': 0,
      'progress': 0,
      'xp_reward': challenge['xp_reward'],
    });

    return {
      ...challenge,
      'progress': 0,
      'completed': false,
    };
  }

  /// Generate weekly challenge
  Future<Map<String, dynamic>> generateWeeklyChallenge() async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS weekly_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        challenge_id TEXT,
        challenge_data TEXT,
        week_start TEXT,
        completed INTEGER DEFAULT 0,
        progress INTEGER DEFAULT 0,
        target INTEGER,
        xp_reward INTEGER,
        completed_at TEXT
      )
    ''');

    // Get current week start (Monday)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartString = weekStart.toIso8601String().split('T')[0];

    final existing = await db.query(
      'weekly_challenges',
      where: 'user_id = ? AND week_start = ?',
      whereArgs: [userId, weekStartString],
    );

    if (existing.isNotEmpty) {
      final challengeData = existing.first;
      final template = WEEKLY_CHALLENGES.firstWhere(
        (c) => c['id'] == challengeData['challenge_id'],
        orElse: () => WEEKLY_CHALLENGES[0],
      );

      return {
        ...template,
        'progress': challengeData['progress'],
        'target': challengeData['target'],
        'completed': challengeData['completed'] == 1,
        'db_id': challengeData['id'],
      };
    }

    // Generate new weekly challenge
    final random = Random();
    final challenge = WEEKLY_CHALLENGES[random.nextInt(WEEKLY_CHALLENGES.length)];

    await db.insert('weekly_challenges', {
      'user_id': userId,
      'challenge_id': challenge['id'],
      'challenge_data': challenge.toString(),
      'week_start': weekStartString,
      'completed': 0,
      'progress': 0,
      'target': challenge['target'] ?? 0,
      'xp_reward': challenge['xp_reward'],
    });

    return {
      ...challenge,
      'progress': 0,
      'completed': false,
    };
  }

  /// Update challenge progress
  Future<Map<String, dynamic>> updateChallengeProgress(
    String challengeType,
    String eventType, {
    int incrementBy = 1,
  }) async {
    final db = await _dbHelper.database;

    if (challengeType == 'daily') {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final challenges = await db.query(
        'daily_challenges',
        where: 'user_id = ? AND date = ? AND completed = 0',
        whereArgs: [userId, today],
      );

      if (challenges.isEmpty) return {};

      final challenge = challenges.first;
      final challengeId = challenge['challenge_id'] as String;

      // Check if this event contributes to challenge
      if (_doesEventMatch(challengeId, eventType)) {
        final newProgress = (challenge['progress'] as int) + incrementBy;
        final isComplete = _checkChallengeComplete(challengeId, newProgress);

        await db.update(
          'daily_challenges',
          {
            'progress': newProgress,
            'completed': isComplete ? 1 : 0,
            'completed_at': isComplete ? DateTime.now().toIso8601String() : null,
          },
          where: 'id = ?',
          whereArgs: [challenge['id']],
        );

        if (isComplete) {
          final xpReward = challenge['xp_reward'] as int;
          await _gamificationEngine.awardXP(xpReward, 'Daily challenge completed!');

          return {
            'completed': true,
            'xp_awarded': xpReward,
            'challenge_name': _getChallengeTemplate(challengeId)['name'],
          };
        }

        return {'progress_updated': true, 'new_progress': newProgress};
      }
    }

    // Handle weekly challenges similarly
    if (challengeType == 'weekly') {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartString = weekStart.toIso8601String().split('T')[0];

      final challenges = await db.query(
        'weekly_challenges',
        where: 'user_id = ? AND week_start = ? AND completed = 0',
        whereArgs: [userId, weekStartString],
      );

      if (challenges.isEmpty) return {};

      final challenge = challenges.first;
      final challengeId = challenge['challenge_id'] as String;

      if (_doesEventMatch(challengeId, eventType)) {
        final newProgress = (challenge['progress'] as int) + incrementBy;
        final target = challenge['target'] as int;
        final isComplete = newProgress >= target;

        await db.update(
          'weekly_challenges',
          {
            'progress': newProgress,
            'completed': isComplete ? 1 : 0,
            'completed_at': isComplete ? DateTime.now().toIso8601String() : null,
          },
          where: 'id = ?',
          whereArgs: [challenge['id']],
        );

        if (isComplete) {
          final xpReward = challenge['xp_reward'] as int;
          await _gamificationEngine.awardXP(xpReward, 'Weekly challenge completed!');

          return {
            'completed': true,
            'xp_awarded': xpReward,
            'challenge_name': _getChallengeTemplate(challengeId)['name'],
          };
        }

        return {'progress_updated': true, 'new_progress': newProgress};
      }
    }

    return {};
  }

  /// Check if event matches challenge type
  bool _doesEventMatch(String challengeId, String eventType) {
    final eventMapping = {
      'perfect_day': ['all_habits_complete'],
      'early_bird': ['workout_before_10am'],
      'double_workout': ['workout_complete'],
      'hydration_hero': ['water_logged'],
      'meal_master': ['meal_logged'],
      'speed_demon': ['workout_under_30min'],
      'consistency_king': ['streak_check'],
      'workout_warrior': ['workout_complete'],
      'perfect_week': ['perfect_day'],
      'meal_tracker': ['meal_logged'],
      'streak_master': ['streak_maintained'],
      'social_butterfly': ['achievement_shared'],
    };

    return eventMapping[challengeId]?.contains(eventType) ?? false;
  }

  /// Check if challenge is complete
  bool _checkChallengeComplete(String challengeId, int progress) {
    // Most daily challenges complete at progress = 1
    final multiStepChallenges = {
      'double_workout': 2,
      'hydration_hero': 8,
      'meal_master': 3,
    };

    return progress >= (multiStepChallenges[challengeId] ?? 1);
  }

  /// Get challenge template by ID
  Map<String, dynamic> _getChallengeTemplate(String challengeId) {
    return [...DAILY_CHALLENGES, ...WEEKLY_CHALLENGES].firstWhere(
      (c) => c['id'] == challengeId,
      orElse: () => {'name': 'Unknown Challenge'},
    );
  }

  /// Get all active challenges
  Future<Map<String, dynamic>> getActiveChallenges() async {
    final daily = await generateDailyChallenge();
    final weekly = await generateWeeklyChallenge();

    return {
      'daily': daily,
      'weekly': weekly,
    };
  }

  /// Get challenge completion stats
  Future<Map<String, dynamic>> getChallengeStats() async {
    final db = await _dbHelper.database;

    try {
      final dailyCompleted = await db.rawQuery('''
        SELECT COUNT(*) as count FROM daily_challenges
        WHERE user_id = ? AND completed = 1
      ''', [userId]);

      final weeklyCompleted = await db.rawQuery('''
        SELECT COUNT(*) as count FROM weekly_challenges
        WHERE user_id = ? AND completed = 1
      ''', [userId]);

      return {
        'total_daily_completed': dailyCompleted.first['count'] ?? 0,
        'total_weekly_completed': weeklyCompleted.first['count'] ?? 0,
      };
    } catch (e) {
      return {
        'total_daily_completed': 0,
        'total_weekly_completed': 0,
      };
    }
  }

  /// Get recent completed challenges
  Future<List<Map<String, dynamic>>> getRecentCompletions({int limit = 10}) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT 'daily' as type, challenge_id, xp_reward, completed_at
        FROM daily_challenges
        WHERE user_id = ? AND completed = 1
        UNION ALL
        SELECT 'weekly' as type, challenge_id, xp_reward, completed_at
        FROM weekly_challenges
        WHERE user_id = ? AND completed = 1
        ORDER BY completed_at DESC
        LIMIT ?
      ''', [userId, userId, limit]);

      return results.map((r) {
        final template = _getChallengeTemplate(r['challenge_id'] as String);
        return {
          ...r,
          'challenge_name': template['name'],
          'challenge_icon': template['icon'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
