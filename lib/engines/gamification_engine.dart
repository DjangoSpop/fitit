import 'dart:math';
import '../services/database_helper_enhanced.dart';

/// Gamification Engine - Makes fitness ADDICTIVE! 🎮
class GamificationEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  GamificationEngine({required this.userId});

  // XP and Levels
  static const int BASE_XP_FOR_LEVEL = 100;
  static const double LEVEL_MULTIPLIER = 1.5;

  // XP Rewards
  static const int XP_WORKOUT_COMPLETE = 50;
  static const int XP_MEAL_LOGGED = 20;
  static const int XP_WATER_GOAL = 15;
  static const int XP_DAILY_ALL_HABITS = 100; // BONUS!
  static const int XP_WEEKLY_ALL_HABITS = 500; // MEGA BONUS!
  static const int XP_STREAK_MILESTONE = 200; // Per milestone
  static const int XP_CHALLENGE_COMPLETE = 150;
  static const int XP_FRIEND_BEAT = 75;
  static const int XP_PERFECT_WEEK = 1000; // LEGENDARY!

  // Power-ups and Boosters
  static const Map<String, Map<String, dynamic>> POWER_UPS = {
    'double_xp': {
      'name': 'Double XP',
      'description': 'Earn 2x XP for 24 hours!',
      'duration_hours': 24,
      'multiplier': 2.0,
      'icon': '⚡',
      'unlock_level': 5,
    },
    'streak_freeze': {
      'name': 'Streak Freeze',
      'description': 'Protect your streak for 1 day',
      'duration_hours': 24,
      'icon': '❄️',
      'unlock_level': 10,
    },
    'motivation_blast': {
      'name': 'Motivation Blast',
      'description': 'Get extra motivation messages',
      'duration_hours': 12,
      'icon': '💥',
      'unlock_level': 3,
    },
    'xp_bomb': {
      'name': 'XP Bomb',
      'description': 'Instant 500 XP!',
      'instant': true,
      'xp_reward': 500,
      'icon': '💣',
      'unlock_level': 15,
    },
  };

  // Titles and Ranks
  static const Map<int, Map<String, String>> RANK_TITLES = {
    1: {'title': 'Beginner', 'emoji': '🌱', 'color': '0xFF4ECDC4'},
    5: {'title': 'Novice', 'emoji': '🔰', 'color': '0xFF51CF66'},
    10: {'title': 'Apprentice', 'emoji': '⭐', 'color': '0xFF4A90E2'},
    15: {'title': 'Warrior', 'emoji': '⚔️', 'color': '0xFFFF6B6B'},
    20: {'title': 'Champion', 'emoji': '🏆', 'color': '0xFFFFD93D'},
    25: {'title': 'Hero', 'emoji': '🦸', 'color': '0xFF6C63FF'},
    30: {'title': 'Master', 'emoji': '👑', 'color': '0xFFFF6B9D'},
    40: {'title': 'Grand Master', 'emoji': '💎', 'color': '0xFF9B59B6'},
    50: {'title': 'Legend', 'emoji': '🌟', 'color': '0xFFFFD700'},
    75: {'title': 'Mythic', 'emoji': '🔥', 'color': '0xFFFF4500'},
    100: {'title': 'IMMORTAL', 'emoji': '✨', 'color': '0xFFFF1493'},
  };

  /// Calculate total XP needed for a level
  int getXPForLevel(int level) {
    if (level <= 1) return 0;
    int totalXP = 0;
    for (int i = 1; i < level; i++) {
      totalXP += (BASE_XP_FOR_LEVEL * pow(LEVEL_MULTIPLIER, i - 1)).round();
    }
    return totalXP;
  }

  /// Get current level from total XP
  int getLevelFromXP(int totalXP) {
    int level = 1;
    while (getXPForLevel(level + 1) <= totalXP) {
      level++;
    }
    return level;
  }

  /// Get XP progress for current level (0.0 to 1.0)
  double getLevelProgress(int totalXP) {
    final currentLevel = getLevelFromXP(totalXP);
    final currentLevelXP = getXPForLevel(currentLevel);
    final nextLevelXP = getXPForLevel(currentLevel + 1);
    final xpInCurrentLevel = totalXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;
    return xpInCurrentLevel / xpNeededForLevel;
  }

  /// Award XP and return level-up info
  Future<Map<String, dynamic>> awardXP(int xpAmount, String reason) async {
    final db = await _dbHelper.database;

    // Get current XP
    final userStats = await _getUserStats();
    final oldTotalXP = userStats['total_xp'] as int? ?? 0;
    final oldLevel = getLevelFromXP(oldTotalXP);

    // Check for active power-ups
    final multiplier = await _getActiveXPMultiplier();
    final finalXP = (xpAmount * multiplier).round();

    // Add XP
    final newTotalXP = oldTotalXP + finalXP;
    final newLevel = getLevelFromXP(newTotalXP);

    // Update database
    await db.execute('''
      INSERT OR REPLACE INTO user_stats (
        user_id, total_xp, level, last_updated
      ) VALUES (?, ?, ?, ?)
    ''', [userId, newTotalXP, newLevel, DateTime.now().toIso8601String()]);

    // Log XP transaction
    await _logXPTransaction(finalXP, reason, multiplier);

    // Check for level up
    final didLevelUp = newLevel > oldLevel;
    final newRank = _getRankForLevel(newLevel);
    final oldRank = _getRankForLevel(oldLevel);
    final rankUp = newRank['title'] != oldRank['title'];

    if (didLevelUp) {
      await _handleLevelUp(newLevel);
    }

    return {
      'xp_awarded': finalXP,
      'base_xp': xpAmount,
      'multiplier': multiplier,
      'old_total_xp': oldTotalXP,
      'new_total_xp': newTotalXP,
      'old_level': oldLevel,
      'new_level': newLevel,
      'did_level_up': didLevelUp,
      'rank_up': rankUp,
      'new_rank': newRank,
      'xp_to_next_level': getXPForLevel(newLevel + 1) - newTotalXP,
    };
  }

  /// Handle workout completion with XP
  Future<Map<String, dynamic>> completeWorkout() async {
    var result = await awardXP(XP_WORKOUT_COMPLETE, 'Workout completed');

    // Bonus for all habits today
    if (await _checkAllHabitsToday()) {
      final bonusResult = await awardXP(XP_DAILY_ALL_HABITS, 'All habits completed today!');
      result['bonus_awarded'] = true;
      result['bonus_xp'] = bonusResult['xp_awarded'];
    }

    return result;
  }

  /// Handle meal logging
  Future<Map<String, dynamic>> logMeal() async {
    return await awardXP(XP_MEAL_LOGGED, 'Meal logged');
  }

  /// Handle water goal
  Future<Map<String, dynamic>> completeWaterGoal() async {
    return await awardXP(XP_WATER_GOAL, 'Water goal met');
  }

  /// Handle streak milestone
  Future<Map<String, dynamic>> streakMilestone(int streakDays) async {
    return await awardXP(XP_STREAK_MILESTONE, '$streakDays day streak milestone!');
  }

  /// Get user rank title
  Map<String, String> _getRankForLevel(int level) {
    var rank = RANK_TITLES[1]!;
    for (var entry in RANK_TITLES.entries) {
      if (level >= entry.key) {
        rank = entry.value;
      } else {
        break;
      }
    }
    return rank;
  }

  /// Get current user stats
  Future<Map<String, dynamic>> _getUserStats() async {
    final db = await _dbHelper.database;

    // Create table if not exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_stats (
        user_id INTEGER PRIMARY KEY,
        total_xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        total_workouts INTEGER DEFAULT 0,
        total_challenges_completed INTEGER DEFAULT 0,
        last_updated TEXT
      )
    ''');

    final result = await db.query(
      'user_stats',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (result.isEmpty) {
      // Initialize
      await db.insert('user_stats', {
        'user_id': userId,
        'total_xp': 0,
        'level': 1,
        'total_workouts': 0,
        'total_challenges_completed': 0,
        'last_updated': DateTime.now().toIso8601String(),
      });
      return {'total_xp': 0, 'level': 1};
    }

    return result.first;
  }

  /// Get active XP multiplier from power-ups
  Future<double> _getActiveXPMultiplier() async {
    // Check for active double_xp power-up
    final activePowerUps = await getActivePowerUps();
    for (var powerUp in activePowerUps) {
      if (powerUp['type'] == 'double_xp') {
        return 2.0;
      }
    }
    return 1.0;
  }

  /// Log XP transaction for history
  Future<void> _logXPTransaction(int xp, String reason, double multiplier) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS xp_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        xp_amount INTEGER,
        reason TEXT,
        multiplier REAL,
        timestamp TEXT
      )
    ''');

    await db.insert('xp_transactions', {
      'user_id': userId,
      'xp_amount': xp,
      'reason': reason,
      'multiplier': multiplier,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handle level up rewards
  Future<void> _handleLevelUp(int newLevel) async {
    // Award power-ups at certain levels
    if (newLevel % 5 == 0) {
      await _awardPowerUp('double_xp', 1);
    }

    if (newLevel % 10 == 0) {
      await _awardPowerUp('streak_freeze', 1);
    }

    // Log achievement
    await _dbHelper.awardAchievement(
      userId,
      'level_$newLevel',
      'Level $newLevel Reached!',
      'You\'ve reached level $newLevel. Keep crushing it!',
    );
  }

  /// Award a power-up to user
  Future<void> _awardPowerUp(String powerUpType, int quantity) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_power_ups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        power_up_type TEXT,
        quantity INTEGER,
        acquired_date TEXT
      )
    ''');

    await db.insert('user_power_ups', {
      'user_id': userId,
      'power_up_type': powerUpType,
      'quantity': quantity,
      'acquired_date': DateTime.now().toIso8601String(),
    });
  }

  /// Use a power-up
  Future<bool> usePowerUp(String powerUpType) async {
    final db = await _dbHelper.database;

    // Check if user has this power-up
    final result = await db.query(
      'user_power_ups',
      where: 'user_id = ? AND power_up_type = ? AND quantity > 0',
      whereArgs: [userId, powerUpType],
    );

    if (result.isEmpty) return false;

    final powerUp = POWER_UPS[powerUpType];
    if (powerUp == null) return false;

    // Decrease quantity
    await db.execute(
      'UPDATE user_power_ups SET quantity = quantity - 1 WHERE user_id = ? AND power_up_type = ?',
      [userId, powerUpType],
    );

    // If instant effect (like xp_bomb)
    if (powerUp['instant'] == true) {
      await awardXP(powerUp['xp_reward'] as int, 'XP Bomb activated!');
      return true;
    }

    // Activate timed power-up
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_power_ups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        power_up_type TEXT,
        activated_at TEXT,
        expires_at TEXT
      )
    ''');

    final duration = powerUp['duration_hours'] as int;
    final expiresAt = DateTime.now().add(Duration(hours: duration));

    await db.insert('active_power_ups', {
      'user_id': userId,
      'power_up_type': powerUpType,
      'activated_at': DateTime.now().toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    });

    return true;
  }

  /// Get active power-ups
  Future<List<Map<String, dynamic>>> getActivePowerUps() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'active_power_ups',
        where: 'user_id = ? AND expires_at > ?',
        whereArgs: [userId, DateTime.now().toIso8601String()],
      );

      return results.map((r) {
        final expiresAt = DateTime.parse(r['expires_at'] as String);
        final remainingMinutes = expiresAt.difference(DateTime.now()).inMinutes;

        return {
          ...r,
          'remaining_minutes': remainingMinutes,
          'details': POWER_UPS[r['power_up_type']],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's power-up inventory
  Future<List<Map<String, dynamic>>> getPowerUpInventory() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'user_power_ups',
        where: 'user_id = ? AND quantity > 0',
        whereArgs: [userId],
      );

      return results.map((r) {
        return {
          ...r,
          'details': POWER_UPS[r['power_up_type']],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if all habits completed today
  Future<bool> _checkAllHabitsToday() async {
    final habits = await _dbHelper.getWeeklyHabits(userId);
    if (habits.isEmpty) return false;

    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (var habit in habits) {
      if ((habit['date'] as String).startsWith(todayString)) {
        return habit['exercise_completed'] == 1 &&
            habit['meal_logged'] == 1 &&
            habit['water_goal_met'] == 1;
      }
    }

    return false;
  }

  /// Get complete user stats for display
  Future<Map<String, dynamic>> getUserGameStats() async {
    final stats = await _getUserStats();
    final totalXP = stats['total_xp'] as int? ?? 0;
    final level = getLevelFromXP(totalXP);
    final progress = getLevelProgress(totalXP);
    final rank = _getRankForLevel(level);
    final xpToNext = getXPForLevel(level + 1) - totalXP;
    final activePowerUps = await getActivePowerUps();
    final inventory = await getPowerUpInventory();

    return {
      'total_xp': totalXP,
      'level': level,
      'level_progress': progress,
      'xp_to_next_level': xpToNext,
      'rank': rank,
      'active_power_ups': activePowerUps,
      'inventory': inventory,
      'total_workouts': stats['total_workouts'] ?? 0,
      'total_challenges': stats['total_challenges_completed'] ?? 0,
    };
  }

  /// Get XP history for charts
  Future<List<Map<String, dynamic>>> getXPHistory({int days = 30}) async {
    final db = await _dbHelper.database;

    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final results = await db.query(
        'xp_transactions',
        where: 'user_id = ? AND timestamp >= ?',
        whereArgs: [userId, startDate.toIso8601String()],
        orderBy: 'timestamp DESC',
        limit: 100,
      );

      return results.toList();
    } catch (e) {
      return [];
    }
  }
}
