import '../services/database_helper_enhanced.dart';

/// Vision Board Engine - Visualize Your Dreams! 🎯
///
/// This helps users create an emotional connection to their goals through
/// visualization, inspiring images, and clear milestone mapping.
class VisionBoardEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  VisionBoardEngine({required this.userId});

  /// Create vision board
  Future<int> createVisionBoard({
    required String boardTitle,
    required String dreamStatement,
    required DateTime targetDate,
    List<String>? inspirationImageUrls,
    List<String>? motivationalQuotes,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vision_boards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        board_title TEXT,
        dream_statement TEXT,
        target_date TEXT,
        inspiration_images TEXT,
        motivational_quotes TEXT,
        created_date TEXT,
        last_viewed_date TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    return await db.insert('vision_boards', {
      'user_id': userId,
      'board_title': boardTitle,
      'dream_statement': dreamStatement,
      'target_date': targetDate.toIso8601String(),
      'inspiration_images': inspirationImageUrls?.join('|||') ?? '',
      'motivational_quotes': motivationalQuotes?.join('|||') ?? '',
      'created_date': DateTime.now().toIso8601String(),
      'last_viewed_date': DateTime.now().toIso8601String(),
      'is_active': 1,
    });
  }

  /// Add milestones to vision board
  Future<void> addMilestone({
    required int visionBoardId,
    required String milestoneTitle,
    required String description,
    required DateTime targetDate,
    String? rewardDescription,
    int? targetWeight,
    int? targetWorkouts,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vision_milestones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vision_board_id INTEGER,
        milestone_title TEXT,
        description TEXT,
        target_date TEXT,
        reward_description TEXT,
        target_weight REAL,
        target_workouts INTEGER,
        is_completed INTEGER DEFAULT 0,
        completed_date TEXT,
        celebration_unlocked INTEGER DEFAULT 0
      )
    ''');

    await db.insert('vision_milestones', {
      'vision_board_id': visionBoardId,
      'milestone_title': milestoneTitle,
      'description': description,
      'target_date': targetDate.toIso8601String(),
      'reward_description': rewardDescription,
      'target_weight': targetWeight,
      'target_workouts': targetWorkouts,
      'is_completed': 0,
    });
  }

  /// Get active vision board
  Future<Map<String, dynamic>?> getActiveVisionBoard() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'vision_boards',
        where: 'user_id = ? AND is_active = 1',
        whereArgs: [userId],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final board = results.first;

      // Get milestones
      final milestones = await db.query(
        'vision_milestones',
        where: 'vision_board_id = ?',
        whereArgs: [board['id']],
        orderBy: 'target_date ASC',
      );

      // Update last viewed
      await db.update(
        'vision_boards',
        {'last_viewed_date': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [board['id']],
      );

      return {
        ...board,
        'milestones': milestones,
        'days_until_goal': _calculateDaysUntil(board['target_date'] as String),
        'progress_percentage': await _calculateOverallProgress(board['id'] as int),
      };
    } catch (e) {
      return null;
    }
  }

  /// Complete milestone
  Future<Map<String, dynamic>> completeMilestone(int milestoneId) async {
    final db = await _dbHelper.database;

    await db.update(
      'vision_milestones',
      {
        'is_completed': 1,
        'completed_date': DateTime.now().toIso8601String(),
        'celebration_unlocked': 1,
      },
      where: 'id = ?',
      whereArgs: [milestoneId],
    );

    // Get milestone details for celebration
    final milestone = await db.query(
      'vision_milestones',
      where: 'id = ?',
      whereArgs: [milestoneId],
      limit: 1,
    );

    if (milestone.isNotEmpty) {
      return {
        'milestone': milestone.first,
        'celebration_message': 'MILESTONE ACHIEVED! ${milestone.first['milestone_title']}! 🎉',
        'reward': milestone.first['reward_description'],
      };
    }

    return {};
  }

  /// Get next milestone
  Future<Map<String, dynamic>?> getNextMilestone() async {
    final board = await getActiveVisionBoard();
    if (board == null) return null;

    final milestones = board['milestones'] as List<Map<String, dynamic>>;
    final incompleteMilestones = milestones.where((m) => m['is_completed'] == 0).toList();

    if (incompleteMilestones.isEmpty) return null;

    final nextMilestone = incompleteMilestones.first;

    return {
      ...nextMilestone,
      'days_until': _calculateDaysUntil(nextMilestone['target_date'] as String),
      'motivation_message': _getMilestoneMotivation(nextMilestone),
    };
  }

  /// Add "Why" statement (emotional anchor)
  Future<void> addWhyStatement({
    required String whyStatement,
    required String deeperWhy,
    String? emotionalImageUrl,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_why_statements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        why_statement TEXT,
        deeper_why TEXT,
        emotional_image_url TEXT,
        created_date TEXT,
        times_viewed INTEGER DEFAULT 0
      )
    ''');

    await db.insert('user_why_statements', {
      'user_id': userId,
      'why_statement': whyStatement,
      'deeper_why': deeperWhy,
      'emotional_image_url': emotionalImageUrl,
      'created_date': DateTime.now().toIso8601String(),
      'times_viewed': 0,
    });
  }

  /// Get "Why" statement (to remind users during tough times)
  Future<Map<String, dynamic>?> getWhyStatement() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'user_why_statements',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_date DESC',
        limit: 1,
      );

      if (results.isEmpty) return null;

      // Increment view count
      await db.execute('''
        UPDATE user_why_statements
        SET times_viewed = times_viewed + 1
        WHERE id = ?
      ''', [results.first['id']]);

      return results.first;
    } catch (e) {
      return null;
    }
  }

  /// Add progress photo
  Future<void> addProgressPhoto({
    required String photoUrl,
    String? notes,
    double? currentWeight,
    Map<String, double>? measurements,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS progress_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        photo_url TEXT,
        notes TEXT,
        current_weight REAL,
        measurements TEXT,
        photo_date TEXT,
        is_milestone INTEGER DEFAULT 0
      )
    ''');

    await db.insert('progress_photos', {
      'user_id': userId,
      'photo_url': photoUrl,
      'notes': notes,
      'current_weight': currentWeight,
      'measurements': measurements?.toString() ?? '',
      'photo_date': DateTime.now().toIso8601String(),
      'is_milestone': 0,
    });
  }

  /// Get progress photo timeline
  Future<List<Map<String, dynamic>>> getProgressPhotoTimeline() async {
    final db = await _dbHelper.database;

    try {
      return await db.query(
        'progress_photos',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'photo_date DESC',
      );
    } catch (e) {
      return [];
    }
  }

  /// Create before/after comparison
  Future<Map<String, dynamic>> getBeforeAfterComparison() async {
    final photos = await getProgressPhotoTimeline();
    if (photos.length < 2) return {};

    final firstPhoto = photos.last; // Oldest
    final latestPhoto = photos.first; // Newest

    final firstDate = DateTime.parse(firstPhoto['photo_date'] as String);
    final latestDate = DateTime.parse(latestPhoto['photo_date'] as String);
    final daysBetween = latestDate.difference(firstDate).inDays;

    double? weightChange;
    if (firstPhoto['current_weight'] != null && latestPhoto['current_weight'] != null) {
      weightChange = (latestPhoto['current_weight'] as double) - (firstPhoto['current_weight'] as double);
    }

    return {
      'before_photo': firstPhoto,
      'after_photo': latestPhoto,
      'days_between': daysBetween,
      'weight_change': weightChange,
      'transformation_message': _getTransformationMessage(daysBetween, weightChange),
    };
  }

  /// Private helper methods
  int _calculateDaysUntil(String targetDateString) {
    final targetDate = DateTime.parse(targetDateString);
    final now = DateTime.now();
    return targetDate.difference(now).inDays;
  }

  Future<double> _calculateOverallProgress(int visionBoardId) async {
    final db = await _dbHelper.database;

    final milestones = await db.query(
      'vision_milestones',
      where: 'vision_board_id = ?',
      whereArgs: [visionBoardId],
    );

    if (milestones.isEmpty) return 0.0;

    final completedCount = milestones.where((m) => m['is_completed'] == 1).length;
    return completedCount / milestones.length;
  }

  String _getMilestoneMotivation(Map<String, dynamic> milestone) {
    final daysUntil = _calculateDaysUntil(milestone['target_date'] as String);
    final title = milestone['milestone_title'] as String;

    if (daysUntil < 0) {
      return 'You\'re past your target date for "$title". Let\'s adjust and keep moving forward!';
    } else if (daysUntil == 0) {
      return 'TODAY is the day for "$title"! Let\'s make it happen!';
    } else if (daysUntil <= 7) {
      return 'Just $daysUntil days until "$title"! You\'re so close!';
    } else if (daysUntil <= 30) {
      return '$daysUntil days to "$title". Keep pushing!';
    } else {
      return '"$title" is coming in $daysUntil days. One day at a time!';
    }
  }

  String _getTransformationMessage(int days, double? weightChange) {
    if (weightChange == null) {
      return 'Look at your transformation over $days days! The change is real!';
    }

    final weightChangeAbs = weightChange.abs();
    if (weightChange < 0) {
      return 'WOW! You\'ve lost ${weightChangeAbs.toStringAsFixed(1)} kg in $days days! Incredible transformation!';
    } else if (weightChange > 0) {
      return 'You\'ve gained ${weightChangeAbs.toStringAsFixed(1)} kg of muscle in $days days! Beast mode!';
    } else {
      return 'Perfect maintenance over $days days! You\'re in control!';
    }
  }
}
