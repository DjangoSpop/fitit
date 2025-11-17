import '../services/database_helper_enhanced.dart';
import 'gamification_engine.dart';

/// Social Engine - Compete, Share, Inspire! 🏆
class SocialEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  SocialEngine({required this.userId});

  /// Get global leaderboard
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    String period = 'all_time', // 'daily', 'weekly', 'monthly', 'all_time'
    int limit = 50,
  }) async {
    final db = await _dbHelper.database;

    try {
      // Get all users with their stats
      final results = await db.rawQuery('''
        SELECT
          up.user_id,
          up.name,
          us.total_xp,
          us.level,
          us.total_workouts,
          hs.current_streak
        FROM user_profile up
        LEFT JOIN user_stats us ON up.id = us.user_id
        LEFT JOIN habit_streaks hs ON up.id = hs.user_id AND hs.habit_type = 'exercise'
        ORDER BY us.total_xp DESC
        LIMIT ?
      ''', [limit]);

      final gamificationEngine = GamificationEngine(userId: userId);

      return results.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final user = entry.value;
        final level = user['level'] as int? ?? 1;
        final rankInfo = gamificationEngine.getUserGameStats();

        return {
          'rank': rank,
          'user_id': user['user_id'],
          'name': user['name'] ?? 'User ${user['user_id']}',
          'total_xp': user['total_xp'] ?? 0,
          'level': level,
          'total_workouts': user['total_workouts'] ?? 0,
          'current_streak': user['current_streak'] ?? 0,
          'is_current_user': user['user_id'] == userId,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get friends leaderboard
  Future<List<Map<String, dynamic>>> getFriendsLeaderboard() async {
    final friends = await getFriends();
    final allUsers = [userId, ...friends.map((f) => f['user_id'] as int)];

    final db = await _dbHelper.database;

    try {
      final placeholders = List.filled(allUsers.length, '?').join(',');

      final results = await db.rawQuery('''
        SELECT
          up.id as user_id,
          up.name,
          us.total_xp,
          us.level,
          us.total_workouts,
          hs.current_streak
        FROM user_profile up
        LEFT JOIN user_stats us ON up.id = us.user_id
        LEFT JOIN habit_streaks hs ON up.id = hs.user_id AND hs.habit_type = 'exercise'
        WHERE up.id IN ($placeholders)
        ORDER BY us.total_xp DESC
      ''', allUsers);

      return results.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final user = entry.value;

        return {
          'rank': rank,
          'user_id': user['user_id'],
          'name': user['name'] ?? 'User ${user['user_id']}',
          'total_xp': user['total_xp'] ?? 0,
          'level': user['level'] ?? 1,
          'total_workouts': user['total_workouts'] ?? 0,
          'current_streak': user['current_streak'] ?? 0,
          'is_current_user': user['user_id'] == userId,
          'is_friend': user['user_id'] != userId,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add friend
  Future<bool> addFriend(int friendUserId) async {
    final db = await _dbHelper.database;

    try {
      await db.insert('social_connections', {
        'user_id_1': userId,
        'user_id_2': friendUserId,
        'connection_type': 'friend',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      });

      // Reciprocal connection
      await db.insert('social_connections', {
        'user_id_1': friendUserId,
        'user_id_2': userId,
        'connection_type': 'friend',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get friends list
  Future<List<Map<String, dynamic>>> getFriends() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          up.id as user_id,
          up.name,
          us.level,
          us.total_xp,
          hs.current_streak,
          sc.created_at as friend_since
        FROM social_connections sc
        JOIN user_profile up ON sc.user_id_2 = up.id
        LEFT JOIN user_stats us ON up.id = us.user_id
        LEFT JOIN habit_streaks hs ON up.id = hs.user_id AND hs.habit_type = 'exercise'
        WHERE sc.user_id_1 = ? AND sc.is_active = 1
        ORDER BY us.total_xp DESC
      ''', [userId]);

      return results.toList();
    } catch (e) {
      return [];
    }
  }

  /// Share achievement
  Future<Map<String, dynamic>> shareAchievement(
    String achievementId,
    String platform,
  ) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shared_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        achievement_id TEXT,
        platform TEXT,
        shared_at TEXT
      )
    ''');

    await db.insert('shared_achievements', {
      'user_id': userId,
      'achievement_id': achievementId,
      'platform': platform,
      'shared_at': DateTime.now().toIso8601String(),
    });

    return {
      'success': true,
      'share_url': _generateShareURL(achievementId),
      'share_text': _generateShareText(achievementId),
    };
  }

  /// Create group challenge
  Future<int> createGroupChallenge({
    required String challengeName,
    required String goalType,
    required int goalCount,
    required int durationDays,
    String? rewardDescription,
  }) async {
    final db = await _dbHelper.database;

    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: durationDays));

    final id = await db.insert('group_challenges', {
      'challenge_name': challengeName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'goal_type': goalType,
      'goal_count': goalCount,
      'reward_description': rewardDescription,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Auto-join creator
    await joinGroupChallenge(id);

    return id;
  }

  /// Join group challenge
  Future<bool> joinGroupChallenge(int challengeId) async {
    final db = await _dbHelper.database;

    try {
      await db.insert('challenge_participants', {
        'challenge_id': challengeId,
        'user_id': userId,
        'current_progress': 0,
        'rank': 0,
        'joined_date': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get active group challenges
  Future<List<Map<String, dynamic>>> getActiveGroupChallenges() async {
    final db = await _dbHelper.database;

    try {
      final now = DateTime.now().toIso8601String();

      final results = await db.rawQuery('''
        SELECT
          gc.*,
          COUNT(cp.user_id) as participant_count,
          MAX(CASE WHEN cp.user_id = ? THEN 1 ELSE 0 END) as is_joined
        FROM group_challenges gc
        LEFT JOIN challenge_participants cp ON gc.id = cp.challenge_id
        WHERE gc.is_active = 1 AND gc.end_date > ?
        GROUP BY gc.id
        ORDER BY gc.created_at DESC
      ''', [userId, now]);

      return results.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get challenge leaderboard
  Future<List<Map<String, dynamic>>> getChallengeLeaderboard(int challengeId) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          cp.*,
          up.name,
          us.level
        FROM challenge_participants cp
        JOIN user_profile up ON cp.user_id = up.id
        LEFT JOIN user_stats us ON up.id = us.user_id
        WHERE cp.challenge_id = ?
        ORDER BY cp.current_progress DESC, cp.joined_date ASC
      ''', [challengeId]);

      return results.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final participant = entry.value;

        return {
          ...participant,
          'rank': rank,
          'is_current_user': participant['user_id'] == userId,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(int challengeId, int progress) async {
    final db = await _dbHelper.database;

    await db.execute('''
      UPDATE challenge_participants
      SET current_progress = ?
      WHERE challenge_id = ? AND user_id = ?
    ''', [progress, challengeId, userId]);

    // Update ranks
    await _updateChallengeRanks(challengeId);
  }

  /// Update challenge ranks
  Future<void> _updateChallengeRanks(int challengeId) async {
    final db = await _dbHelper.database;

    final participants = await db.query(
      'challenge_participants',
      where: 'challenge_id = ?',
      whereArgs: [challengeId],
      orderBy: 'current_progress DESC, joined_date ASC',
    );

    for (var i = 0; i < participants.length; i++) {
      await db.update(
        'challenge_participants',
        {'rank': i + 1},
        where: 'id = ?',
        whereArgs: [participants[i]['id']],
      );
    }
  }

  /// Get social stats
  Future<Map<String, dynamic>> getSocialStats() async {
    final friends = await getFriends();
    final challenges = await getActiveGroupChallenges();
    final joinedChallenges = challenges.where((c) => c['is_joined'] == 1).toList();

    return {
      'total_friends': friends.length,
      'active_challenges': challenges.length,
      'joined_challenges': joinedChallenges.length,
    };
  }

  /// Generate share URL
  String _generateShareURL(String achievementId) {
    return 'https://fitit.app/achievement/$userId/$achievementId';
  }

  /// Generate share text
  String _generateShareText(String achievementId) {
    return 'I just earned a new achievement in FitIt! 🎉 Join me on my fitness journey!';
  }

  /// Send friend challenge
  Future<bool> challengeFriend(int friendId, String challengeType) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS friend_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenger_id INTEGER,
        challenged_id INTEGER,
        challenge_type TEXT,
        status TEXT,
        created_at TEXT,
        expires_at TEXT
      )
    ''');

    await db.insert('friend_challenges', {
      'challenger_id': userId,
      'challenged_id': friendId,
      'challenge_type': challengeType,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now().add(Duration(days: 7)).toIso8601String(),
    });

    return true;
  }

  /// Get pending friend challenges
  Future<List<Map<String, dynamic>>> getPendingChallenges() async {
    final db = await _dbHelper.database;

    try {
      final now = DateTime.now().toIso8601String();

      final results = await db.rawQuery('''
        SELECT
          fc.*,
          up.name as challenger_name
        FROM friend_challenges fc
        JOIN user_profile up ON fc.challenger_id = up.id
        WHERE fc.challenged_id = ?
        AND fc.status = 'pending'
        AND fc.expires_at > ?
        ORDER BY fc.created_at DESC
      ''', [userId, now]);

      return results.toList();
    } catch (e) {
      return [];
    }
  }
}
