import '../services/database_helper_enhanced.dart';
import 'gamification_engine.dart';

/// Mentor/Mentee System - Pass It Forward! 🤝
///
/// This creates a supportive community where experienced users mentor
/// newcomers, creating a cycle of inspiration and accountability.
class MentorSystemEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;
  late GamificationEngine _gamificationEngine;

  MentorSystemEngine({required this.userId}) {
    _gamificationEngine = GamificationEngine(userId: userId);
  }

  /// Become a mentor
  Future<bool> becomeMentor({
    required String expertise, // 'weight_loss', 'muscle_building', 'general_fitness'
    required String mentorBio,
    List<String>? specialties,
    int? maxMentees,
  }) async {
    final db = await _dbHelper.database;

    // Check eligibility (must have certain XP/level)
    final userStats = await _gamificationEngine.getUserGameStats();
    final level = userStats['level'] as int;

    if (level < 10) {
      return false; // Must be at least level 10
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE,
        expertise TEXT,
        mentor_bio TEXT,
        specialties TEXT,
        max_mentees INTEGER,
        current_mentees INTEGER DEFAULT 0,
        total_mentees_helped INTEGER DEFAULT 0,
        mentor_rating REAL DEFAULT 5.0,
        is_active INTEGER DEFAULT 1,
        created_date TEXT
      )
    ''');

    try {
      await db.insert('mentors', {
        'user_id': userId,
        'expertise': expertise,
        'mentor_bio': mentorBio,
        'specialties': specialties?.join('|||') ?? '',
        'max_mentees': maxMentees ?? 3,
        'current_mentees': 0,
        'total_mentees_helped': 0,
        'created_date': DateTime.now().toIso8601String(),
      });

      // Award XP for becoming mentor
      await _gamificationEngine.awardXP(500, 'Became a mentor! Paying it forward! 🤝');

      return true;
    } catch (e) {
      return false; // Already a mentor
    }
  }

  /// Find a mentor
  Future<List<Map<String, dynamic>>> findMentors({
    String? expertise,
    int limit = 20,
  }) async {
    final db = await _dbHelper.database;

    try {
      String whereClause = 'm.is_active = 1 AND m.current_mentees < m.max_mentees';
      List<dynamic> whereArgs = [];

      if (expertise != null) {
        whereClause += ' AND m.expertise = ?';
        whereArgs.add(expertise);
      }

      final results = await db.rawQuery('''
        SELECT
          m.*,
          up.name as mentor_name,
          up.avatar_url as mentor_avatar,
          us.level as mentor_level,
          us.total_workouts
        FROM mentors m
        JOIN user_profile up ON m.user_id = up.id
        LEFT JOIN user_stats us ON m.user_id = us.user_id
        WHERE $whereClause
        ORDER BY m.mentor_rating DESC, m.total_mentees_helped DESC
        LIMIT ?
      ''', [...whereArgs, limit]);

      return results.map((r) {
        return {
          ...r,
          'specialties': _decodeTags(r['specialties'] as String?),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Request mentorship
  Future<int> requestMentorship(int mentorUserId, {String? message}) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentorship_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mentee_user_id INTEGER,
        mentor_user_id INTEGER,
        request_message TEXT,
        status TEXT,
        created_date TEXT,
        responded_date TEXT
      )
    ''');

    return await db.insert('mentorship_requests', {
      'mentee_user_id': userId,
      'mentor_user_id': mentorUserId,
      'request_message': message,
      'status': 'pending',
      'created_date': DateTime.now().toIso8601String(),
    });
  }

  /// Accept mentorship request
  Future<bool> acceptMentorshipRequest(int requestId) async {
    final db = await _dbHelper.database;

    // Get request details
    final request = await db.query(
      'mentorship_requests',
      where: 'id = ? AND mentor_user_id = ?',
      whereArgs: [requestId, userId],
      limit: 1,
    );

    if (request.isEmpty) return false;

    final menteeUserId = request.first['mentee_user_id'] as int;

    // Create mentorship relationship
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentorship_relationships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mentor_user_id INTEGER,
        mentee_user_id INTEGER,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        check_ins INTEGER DEFAULT 0,
        mentee_progress_rating INTEGER
      )
    ''');

    await db.insert('mentorship_relationships', {
      'mentor_user_id': userId,
      'mentee_user_id': menteeUserId,
      'start_date': DateTime.now().toIso8601String(),
      'is_active': 1,
      'check_ins': 0,
    });

    // Update request status
    await db.update(
      'mentorship_requests',
      {
        'status': 'accepted',
        'responded_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [requestId],
    );

    // Update mentor's current mentees count
    await db.rawUpdate('''
      UPDATE mentors
      SET current_mentees = current_mentees + 1
      WHERE user_id = ?
    ''', [userId]);

    return true;
  }

  /// Decline mentorship request
  Future<void> declineMentorshipRequest(int requestId, {String? reason}) async {
    final db = await _dbHelper.database;

    await db.update(
      'mentorship_requests',
      {
        'status': 'declined',
        'responded_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND mentor_user_id = ?',
      whereArgs: [requestId, userId],
    );
  }

  /// Get pending mentorship requests (for mentors)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          mr.*,
          up.name as mentee_name,
          up.avatar_url as mentee_avatar,
          us.level as mentee_level
        FROM mentorship_requests mr
        JOIN user_profile up ON mr.mentee_user_id = up.id
        LEFT JOIN user_stats us ON mr.mentee_user_id = us.user_id
        WHERE mr.mentor_user_id = ? AND mr.status = 'pending'
        ORDER BY mr.created_date DESC
      ''', [userId]);

      return results.toList();
    } catch (e) {
      return [];
    }
  }

  /// Get my mentor
  Future<Map<String, dynamic>?> getMyMentor() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          mr.*,
          m.*,
          up.name as mentor_name,
          up.avatar_url as mentor_avatar,
          us.level as mentor_level
        FROM mentorship_relationships mr
        JOIN mentors m ON mr.mentor_user_id = m.user_id
        JOIN user_profile up ON m.user_id = up.id
        LEFT JOIN user_stats us ON m.user_id = us.user_id
        WHERE mr.mentee_user_id = ? AND mr.is_active = 1
        LIMIT 1
      ''', [userId]);

      if (results.isEmpty) return null;

      final mentor = results.first;

      return {
        ...mentor,
        'specialties': _decodeTags(mentor['specialties'] as String?),
        'days_together': _calculateDaysTogether(mentor['start_date'] as String),
      };
    } catch (e) {
      return null;
    }
  }

  /// Get my mentees
  Future<List<Map<String, dynamic>>> getMyMentees() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          mr.*,
          up.name as mentee_name,
          up.avatar_url as mentee_avatar,
          us.level as mentee_level,
          us.total_workouts as mentee_workouts
        FROM mentorship_relationships mr
        JOIN user_profile up ON mr.mentee_user_id = up.id
        LEFT JOIN user_stats us ON mr.mentee_user_id = us.user_id
        WHERE mr.mentor_user_id = ? AND mr.is_active = 1
        ORDER BY mr.start_date DESC
      ''', [userId]);

      return results.map((r) {
        return {
          ...r,
          'days_together': _calculateDaysTogether(r['start_date'] as String),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Record check-in (mentor checks in with mentee)
  Future<int> recordCheckIn({
    required int menteeUserId,
    required String checkInType, // 'message', 'call', 'workout_review'
    required String notes,
    int? encouragementRating, // How encouraging was the check-in 1-5
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentor_checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mentor_user_id INTEGER,
        mentee_user_id INTEGER,
        checkin_type TEXT,
        notes TEXT,
        encouragement_rating INTEGER,
        checkin_date TEXT
      )
    ''');

    final checkinId = await db.insert('mentor_checkins', {
      'mentor_user_id': userId,
      'mentee_user_id': menteeUserId,
      'checkin_type': checkInType,
      'notes': notes,
      'encouragement_rating': encouragementRating,
      'checkin_date': DateTime.now().toIso8601String(),
    });

    // Update relationship check-in count
    await db.rawUpdate('''
      UPDATE mentorship_relationships
      SET check_ins = check_ins + 1
      WHERE mentor_user_id = ? AND mentee_user_id = ?
    ''', [userId, menteeUserId]);

    // Award XP for checking in
    await _gamificationEngine.awardXP(50, 'Mentor check-in! Supporting your mentee! 🤝');

    return checkinId;
  }

  /// Rate mentor (mentee rates their mentor)
  Future<void> rateMentor(int mentorUserId, {
    required int rating, // 1-5
    String? feedback,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mentor_ratings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mentor_user_id INTEGER,
        mentee_user_id INTEGER,
        rating INTEGER,
        feedback TEXT,
        rated_date TEXT
      )
    ''');

    await db.insert('mentor_ratings', {
      'mentor_user_id': mentorUserId,
      'mentee_user_id': userId,
      'rating': rating,
      'feedback': feedback,
      'rated_date': DateTime.now().toIso8601String(),
    });

    // Recalculate mentor's average rating
    final ratings = await db.query(
      'mentor_ratings',
      columns: ['rating'],
      where: 'mentor_user_id = ?',
      whereArgs: [mentorUserId],
    );

    if (ratings.isNotEmpty) {
      final avgRating = ratings.map((r) => r['rating'] as int).reduce((a, b) => a + b) / ratings.length;

      await db.update(
        'mentors',
        {'mentor_rating': avgRating},
        where: 'user_id = ?',
        whereArgs: [mentorUserId],
      );
    }
  }

  /// End mentorship
  Future<void> endMentorship(int menteeUserId) async {
    final db = await _dbHelper.database;

    await db.update(
      'mentorship_relationships',
      {
        'is_active': 0,
        'end_date': DateTime.now().toIso8601String(),
      },
      where: 'mentor_user_id = ? AND mentee_user_id = ?',
      whereArgs: [userId, menteeUserId],
    );

    // Update mentor's counts
    await db.rawUpdate('''
      UPDATE mentors
      SET current_mentees = current_mentees - 1,
          total_mentees_helped = total_mentees_helped + 1
      WHERE user_id = ?
    ''', [userId]);
  }

  /// Get mentorship impact stats (for mentors)
  Future<Map<String, dynamic>> getMentorshipImpact() async {
    final db = await _dbHelper.database;

    try {
      final mentorData = await db.query(
        'mentors',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (mentorData.isEmpty) {
        return {
          'is_mentor': false,
        };
      }

      final mentor = mentorData.first;

      // Get total check-ins
      final checkins = await db.query(
        'mentor_checkins',
        where: 'mentor_user_id = ?',
        whereArgs: [userId],
      );

      // Get average rating
      final ratings = await db.query(
        'mentor_ratings',
        where: 'mentor_user_id = ?',
        whereArgs: [userId],
      );

      double avgRating = 5.0;
      if (ratings.isNotEmpty) {
        avgRating = ratings.map((r) => r['rating'] as int).reduce((a, b) => a + b) / ratings.length;
      }

      return {
        'is_mentor': true,
        'current_mentees': mentor['current_mentees'],
        'total_mentees_helped': mentor['total_mentees_helped'],
        'total_checkins': checkins.length,
        'average_rating': avgRating,
        'impact_message': _getImpactMessage(
          mentor['total_mentees_helped'] as int,
          checkins.length,
        ),
      };
    } catch (e) {
      return {
        'is_mentor': false,
      };
    }
  }

  /// Get suggested mentors based on user's goals
  Future<List<Map<String, dynamic>>> getSuggestedMentors() async {
    final db = await _dbHelper.database;

    try {
      // Get user's goals from profile
      final profile = await db.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      String? userGoal;
      if (profile.isNotEmpty) {
        userGoal = profile.first['fitness_goal'] as String?;
      }

      // Find mentors matching user's goal
      return await findMentors(
        expertise: userGoal,
        limit: 5,
      );
    } catch (e) {
      return [];
    }
  }

  /// Get mentor leaderboard
  Future<List<Map<String, dynamic>>> getMentorLeaderboard({int limit = 20}) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          m.*,
          up.name as mentor_name,
          up.avatar_url as mentor_avatar,
          us.level as mentor_level
        FROM mentors m
        JOIN user_profile up ON m.user_id = up.id
        LEFT JOIN user_stats us ON m.user_id = us.user_id
        WHERE m.is_active = 1
        ORDER BY m.total_mentees_helped DESC, m.mentor_rating DESC
        LIMIT ?
      ''', [limit]);

      return results.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final mentor = entry.value;

        return {
          ...mentor,
          'rank': rank,
          'badge': _getMentorBadge(rank, mentor['total_mentees_helped'] as int),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Private helper methods
  List<String> _decodeTags(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    return encoded.split('|||');
  }

  int _calculateDaysTogether(String startDateString) {
    final startDate = DateTime.parse(startDateString);
    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }

  String _getImpactMessage(int totalHelped, int totalCheckins) {
    if (totalHelped >= 10) {
      return 'LEGENDARY MENTOR! You\'ve transformed $totalHelped lives! 👑';
    } else if (totalHelped >= 5) {
      return 'Mentor Master! $totalHelped people are better because of you! 🌟';
    } else if (totalHelped >= 1) {
      return 'Making an impact! You\'ve helped $totalHelped people! 🤝';
    } else {
      return 'Start your mentorship journey! Pay it forward! 💪';
    }
  }

  String _getMentorBadge(int rank, int totalHelped) {
    if (rank == 1) {
      return '🥇 #1 Mentor';
    } else if (rank <= 3) {
      return '🥈 Top 3 Mentor';
    } else if (rank <= 10) {
      return '🥉 Top 10 Mentor';
    } else if (totalHelped >= 5) {
      return '⭐ Master Mentor';
    } else {
      return '🤝 Mentor';
    }
  }
}
