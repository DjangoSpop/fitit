import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitness_app_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Existing tables
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        age INTEGER,
        gender TEXT,
        height REAL,
        weight REAL,
        fitness_level TEXT,
        goals TEXT,
        available_equipment TEXT,
        personality_type TEXT,
        notification_preference TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE progress_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        weight REAL,
        notes TEXT,
        workout_completed INTEGER,
        meal_adherence REAL
      )
    ''');

    // NEW TABLES FOR HABIT FORMATION
    await db.execute('''
      CREATE TABLE habit_streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        habit_type TEXT,
        current_streak INTEGER,
        longest_streak INTEGER,
        last_completed TEXT,
        total_completions INTEGER,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT,
        exercise_completed INTEGER,
        meal_logged INTEGER,
        water_goal_met INTEGER,
        notes TEXT,
        mood_rating INTEGER,
        energy_level INTEGER,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        badge_type TEXT,
        badge_name TEXT,
        description TEXT,
        date_achieved TEXT,
        icon_code TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        notification_type TEXT,
        title TEXT,
        body TEXT,
        scheduled_time TEXT,
        delivered_time TEXT,
        opened INTEGER,
        opened_time TEXT,
        engagement_score REAL,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE performance_analytics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        date TEXT,
        completion_rate REAL,
        predicted_completion REAL,
        difficulty_level TEXT,
        adherence_score REAL,
        energy_pattern TEXT,
        drop_off_risk REAL,
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE social_connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id_1 INTEGER,
        user_id_2 INTEGER,
        connection_type TEXT,
        created_at TEXT,
        is_active INTEGER,
        FOREIGN KEY (user_id_1) REFERENCES user_profile(id),
        FOREIGN KEY (user_id_2) REFERENCES user_profile(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE group_challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_name TEXT,
        start_date TEXT,
        end_date TEXT,
        goal_type TEXT,
        goal_count INTEGER,
        reward_description TEXT,
        is_active INTEGER,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE challenge_participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challenge_id INTEGER,
        user_id INTEGER,
        current_progress INTEGER,
        rank INTEGER,
        joined_date TEXT,
        FOREIGN KEY (challenge_id) REFERENCES group_challenges(id),
        FOREIGN KEY (user_id) REFERENCES user_profile(id)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from v1 to v2 - create new tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS habit_streaks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          habit_type TEXT,
          current_streak INTEGER,
          longest_streak INTEGER,
          last_completed TEXT,
          total_completions INTEGER,
          created_at TEXT,
          FOREIGN KEY (user_id) REFERENCES user_profile(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_habits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          date TEXT,
          exercise_completed INTEGER,
          meal_logged INTEGER,
          water_goal_met INTEGER,
          notes TEXT,
          mood_rating INTEGER,
          energy_level INTEGER,
          created_at TEXT,
          FOREIGN KEY (user_id) REFERENCES user_profile(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS achievements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          badge_type TEXT,
          badge_name TEXT,
          description TEXT,
          date_achieved TEXT,
          icon_code TEXT,
          FOREIGN KEY (user_id) REFERENCES user_profile(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          notification_type TEXT,
          title TEXT,
          body TEXT,
          scheduled_time TEXT,
          delivered_time TEXT,
          opened INTEGER,
          opened_time TEXT,
          engagement_score REAL,
          FOREIGN KEY (user_id) REFERENCES user_profile(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS performance_analytics (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          date TEXT,
          completion_rate REAL,
          predicted_completion REAL,
          difficulty_level TEXT,
          adherence_score REAL,
          energy_pattern TEXT,
          drop_off_risk REAL,
          FOREIGN KEY (user_id) REFERENCES user_profile(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS social_connections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id_1 INTEGER,
          user_id_2 INTEGER,
          connection_type TEXT,
          created_at TEXT,
          is_active INTEGER,
          FOREIGN KEY (user_id_1) REFERENCES user_profile(id),
          FOREIGN KEY (user_id_2) REFERENCES user_profile(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS group_challenges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          challenge_name TEXT,
          start_date TEXT,
          end_date TEXT,
          goal_type TEXT,
          goal_count INTEGER,
          reward_description TEXT,
          is_active INTEGER,
          created_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS challenge_participants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          challenge_id INTEGER,
          user_id INTEGER,
          current_progress INTEGER,
          rank INTEGER,
          joined_date TEXT,
          FOREIGN KEY (challenge_id) REFERENCES group_challenges(id),
          FOREIGN KEY (user_id) REFERENCES user_profile(id)
        )
      ''');
    }
  }

  // HABIT STREAK OPERATIONS
  Future<void> initializeStreaks(int userId) async {
    final db = await instance.database;
    final habitsToTrack = ['exercise', 'meal_logging', 'weight_tracking'];

    for (String habit in habitsToTrack) {
      await db.insert('habit_streaks', {
        'user_id': userId,
        'habit_type': habit,
        'current_streak': 0,
        'longest_streak': 0,
        'last_completed': null,
        'total_completions': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<Map<String, dynamic>?> getStreakData(int userId, String habitType) async {
    final db = await instance.database;
    final results = await db.query(
      'habit_streaks',
      where: 'user_id = ? AND habit_type = ?',
      whereArgs: [userId, habitType],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateStreakOnCompletion(int userId, String habitType) async {
    final db = await instance.database;
    final streak = await getStreakData(userId, habitType);

    if (streak != null) {
      final lastCompleted = streak['last_completed'];
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final today = DateTime.now();

      int newStreak = streak['current_streak'] as int? ?? 0;

      // Check if streak continues or resets
      if (lastCompleted != null) {
        final lastDate = DateTime.parse(lastCompleted as String);
        if (lastDate.year == yesterday.year &&
            lastDate.month == yesterday.month &&
            lastDate.day == yesterday.day) {
          newStreak += 1;
        } else if (lastDate.year == today.year &&
                   lastDate.month == today.month &&
                   lastDate.day == today.day) {
          // Already completed today
          return;
        } else {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      final longestStreak = streak['longest_streak'] as int? ?? 0;

      await db.update(
        'habit_streaks',
        {
          'current_streak': newStreak,
          'longest_streak': newStreak > longestStreak ? newStreak : longestStreak,
          'last_completed': today.toIso8601String(),
          'total_completions': (streak['total_completions'] as int? ?? 0) + 1,
        },
        where: 'user_id = ? AND habit_type = ?',
        whereArgs: [userId, habitType],
      );
    }
  }

  // DAILY HABIT LOGGING
  Future<void> logDailyHabit(int userId, Map<String, dynamic> habitData) async {
    final db = await instance.database;
    await db.insert('daily_habits', {
      'user_id': userId,
      'date': DateTime.now().toIso8601String().split('T')[0],
      ...habitData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getWeeklyHabits(int userId) async {
    final db = await instance.database;
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));

    return await db.query(
      'daily_habits',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, sevenDaysAgo.toIso8601String().split('T')[0]],
      orderBy: 'date DESC',
    );
  }

  // ACHIEVEMENT OPERATIONS
  Future<void> awardAchievement(
    int userId,
    String badgeType,
    String badgeName,
    String description,
  ) async {
    final db = await instance.database;
    await db.insert('achievements', {
      'user_id': userId,
      'badge_type': badgeType,
      'badge_name': badgeName,
      'description': description,
      'date_achieved': DateTime.now().toIso8601String(),
      'icon_code': _getIconCode(badgeType),
    });
  }

  String _getIconCode(String badgeType) {
    const iconMap = {
      'first_workout': '💪',
      'week_warrior': '🔥',
      'month_master': '👑',
      'year_champion': '🏆',
      'consistency_7': '⭐',
      'consistency_30': '✨',
      'consistency_100': '💎',
      'social_butterfly': '🦋',
      'meal_master': '🥗',
    };
    return iconMap[badgeType] ?? '🎯';
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(int userId) async {
    final db = await instance.database;
    return await db.query(
      'achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_achieved DESC',
    );
  }

  // PERFORMANCE ANALYTICS
  Future<void> recordPerformanceMetrics(
    int userId,
    Map<String, dynamic> metrics,
  ) async {
    final db = await instance.database;
    await db.insert('performance_analytics', {
      'user_id': userId,
      'date': DateTime.now().toIso8601String().split('T')[0],
      ...metrics,
    });
  }

  Future<List<Map<String, dynamic>>> getPerformanceTrend(
    int userId,
    int days,
  ) async {
    final db = await instance.database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    return await db.query(
      'performance_analytics',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, startDate.toIso8601String().split('T')[0]],
      orderBy: 'date ASC',
    );
  }

  // NOTIFICATION LOG OPERATIONS
  Future<void> insertNotificationLog(
    int userId,
    Map<String, dynamic> notificationData,
  ) async {
    final db = await instance.database;
    await db.insert('notifications_log', {
      'user_id': userId,
      ...notificationData,
    });
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory(
    int userId,
    DateTime since,
  ) async {
    final db = await instance.database;
    return await db.query(
      'notifications_log',
      where: 'user_id = ? AND scheduled_time >= ?',
      whereArgs: [userId, since.toIso8601String()],
      orderBy: 'scheduled_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getNotificationsForUser(int userId) async {
    final db = await instance.database;
    return await db.query(
      'notifications_log',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'scheduled_time DESC',
    );
  }

  Future<void> updateNotificationEngagement(
    int notificationId,
    bool wasOpened,
    DateTime openedTime,
  ) async {
    final db = await instance.database;
    await db.update(
      'notifications_log',
      {
        'opened': wasOpened ? 1 : 0,
        'opened_time': openedTime.toIso8601String(),
        'engagement_score': wasOpened ? 1.0 : 0.0,
      },
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  // EXISTING USER PROFILE OPERATIONS (for backward compatibility)
  Future<int> insertUserProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    return await db.insert('user_profile', profile);
  }

  Future<int> updateUserProfile(Map<String, dynamic> profile) async {
    final db = await instance.database;
    return await db.update('user_profile', profile,
        where: 'id = ?', whereArgs: [profile['id']]);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await instance.database;
    final results = await db.query('user_profile', limit: 1);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> insertProgressEntry(Map<String, dynamic> entry) async {
    final db = await instance.database;
    return await db.insert('progress_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getProgressEntries() async {
    final db = await instance.database;
    return await db.query('progress_entries', orderBy: 'date DESC');
  }
}
