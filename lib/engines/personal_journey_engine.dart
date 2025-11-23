import 'dart:math';
import '../services/database_helper_enhanced.dart';

/// Personal Journey Engine - Turn Fitness Into An Epic Story! 📖
///
/// This engine creates a personalized narrative journey where users are
/// the HERO of their own transformation story. Every workout is a chapter,
/// every achievement is a plot point, and the user's dream body is the
/// ultimate destination.
class PersonalJourneyEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  PersonalJourneyEngine({required this.userId});

  /// Journey Stages - The Hero's Journey adapted for fitness
  static const List<Map<String, dynamic>> JOURNEY_STAGES = [
    {
      'id': 'awakening',
      'name': 'The Awakening',
      'description': 'Every hero starts somewhere. This is YOUR moment of decision.',
      'emoji': '🌅',
      'days_range': [0, 7],
      'milestones': [
        'First workout completed',
        'Profile created',
        'Goals defined',
        'Why statement written',
      ],
      'story_arc': 'You\'ve made the decision. The old you is behind you. A new chapter begins today.',
    },
    {
      'id': 'building_foundation',
      'name': 'Building the Foundation',
      'description': 'Rome wasn\'t built in a day. Neither is your dream body.',
      'emoji': '🏗️',
      'days_range': [8, 21],
      'milestones': [
        '7-day streak achieved',
        '10 workouts completed',
        'First habit formed',
        'Consistency proven',
      ],
      'story_arc': 'The journey is harder than you thought, but you\'re showing up. That\'s what heroes do.',
    },
    {
      'id': 'facing_resistance',
      'name': 'Facing Resistance',
      'description': 'Every hero faces obstacles. This is where you prove yourself.',
      'emoji': '⚔️',
      'days_range': [22, 45],
      'milestones': [
        'Overcame first setback',
        '30-day streak',
        'Visible progress',
        'Mental breakthrough',
      ],
      'story_arc': 'The doubts creep in. Your old self whispers "quit." But you push forward anyway.',
    },
    {
      'id': 'breakthrough',
      'name': 'The Breakthrough',
      'description': 'This is when everything clicks. You\'re not trying anymore - you ARE.',
      'emoji': '💡',
      'days_range': [46, 66],
      'milestones': [
        'Identity shift',
        '50 workouts completed',
        'Others notice changes',
        'New habits automatic',
      ],
      'story_arc': 'Something changed. You\'re not the person who started this journey. You\'re becoming someone new.',
    },
    {
      'id': 'mastery',
      'name': 'Mastery',
      'description': 'Fitness is part of who you are now. This is your new normal.',
      'emoji': '👑',
      'days_range': [67, 100],
      'milestones': [
        '90-day streak',
        '100 workouts',
        'Goal body achieved',
        'Inspiring others',
      ],
      'story_arc': 'You\'ve done it. The transformation is complete. But this isn\'t the end - it\'s a new beginning.',
    },
    {
      'id': 'legend',
      'name': 'Living Legend',
      'description': 'You\'re not just fit - you\'re an inspiration. Your story inspires others.',
      'emoji': '✨',
      'days_range': [101, 999],
      'milestones': [
        '100+ day streak',
        '200+ workouts',
        'Mentoring others',
        'Lifestyle mastered',
      ],
      'story_arc': 'You\'re living proof that transformation is possible. Your journey inspires countless others.',
    },
  ];

  /// Initialize user journey
  Future<void> initializeJourney({
    required String whyStatement,
    required String dreamGoal,
    required String currentChallenge,
    required String emotionalReason,
    List<String>? inspirationPhotos,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_journey (
        user_id INTEGER PRIMARY KEY,
        journey_started_date TEXT,
        current_stage TEXT,
        total_journey_days INTEGER,
        why_statement TEXT,
        dream_goal TEXT,
        current_challenge TEXT,
        emotional_reason TEXT,
        inspiration_photos TEXT,
        last_chapter_date TEXT,
        story_so_far TEXT
      )
    ''');

    final now = DateTime.now().toIso8601String();

    await db.insert('user_journey', {
      'user_id': userId,
      'journey_started_date': now,
      'current_stage': 'awakening',
      'total_journey_days': 0,
      'why_statement': whyStatement,
      'dream_goal': dreamGoal,
      'current_challenge': currentChallenge,
      'emotional_reason': emotionalReason,
      'inspiration_photos': inspirationPhotos?.join(',') ?? '',
      'last_chapter_date': now,
      'story_so_far': '',
    });

    // Create first chapter
    await addJourneyChapter(
      chapterTitle: 'Chapter 1: The Decision',
      chapterContent: 'Today, I decided to change my life. My dream: $dreamGoal. My reason: $emotionalReason. This is day one of my transformation.',
      emotionalMoment: 'The moment I decided to start',
    );
  }

  /// Get current journey stage
  Future<Map<String, dynamic>> getCurrentStage() async {
    final journey = await _getUserJourney();
    if (journey == null) return {};

    final startDate = DateTime.parse(journey['journey_started_date'] as String);
    final daysSinceStart = DateTime.now().difference(startDate).inDays;

    // Find current stage based on days
    var currentStage = JOURNEY_STAGES[0];
    for (var stage in JOURNEY_STAGES) {
      final range = stage['days_range'] as List<int>;
      if (daysSinceStart >= range[0] && daysSinceStart <= range[1]) {
        currentStage = stage;
        break;
      }
    }

    // Calculate progress within current stage
    final range = currentStage['days_range'] as List<int>;
    final stageProgress = (daysSinceStart - range[0]) / (range[1] - range[0]);

    return {
      ...currentStage,
      'days_since_start': daysSinceStart,
      'stage_progress': stageProgress.clamp(0.0, 1.0),
      'days_in_stage': daysSinceStart - range[0],
      'days_until_next': range[1] - daysSinceStart,
    };
  }

  /// Add a chapter to the journey (major milestone)
  Future<void> addJourneyChapter({
    required String chapterTitle,
    required String chapterContent,
    String? emotionalMoment,
    String? lessonLearned,
    List<String>? photoUrls,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS journey_chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        chapter_number INTEGER,
        chapter_title TEXT,
        chapter_content TEXT,
        emotional_moment TEXT,
        lesson_learned TEXT,
        photo_urls TEXT,
        created_date TEXT
      )
    ''');

    // Get current chapter number
    final chapters = await db.query(
      'journey_chapters',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final chapterNumber = chapters.length + 1;

    await db.insert('journey_chapters', {
      'user_id': userId,
      'chapter_number': chapterNumber,
      'chapter_title': chapterTitle,
      'chapter_content': chapterContent,
      'emotional_moment': emotionalMoment,
      'lesson_learned': lessonLearned,
      'photo_urls': photoUrls?.join(',') ?? '',
      'created_date': DateTime.now().toIso8601String(),
    });
  }

  /// Get the user's complete story
  Future<Map<String, dynamic>> getUserStory() async {
    final journey = await _getUserJourney();
    if (journey == null) return {};

    final chapters = await getJourneyChapters();
    final currentStage = await getCurrentStage();
    final achievements = await _dbHelper.getUserAchievements(userId);
    final stats = await _getJourneyStats();

    return {
      'journey': journey,
      'current_stage': currentStage,
      'chapters': chapters,
      'achievements': achievements,
      'stats': stats,
      'story_arc': _generateStoryArc(chapters, stats),
    };
  }

  /// Generate a narrative story arc
  String _generateStoryArc(List<Map<String, dynamic>> chapters, Map<String, dynamic> stats) {
    final totalDays = stats['total_days'] ?? 0;
    final totalWorkouts = stats['total_workouts'] ?? 0;
    final currentStreak = stats['current_streak'] ?? 0;

    if (totalDays < 7) {
      return 'Your journey has just begun. Every hero starts with a single step. You\'ve taken yours.';
    } else if (totalDays < 30) {
      return 'You\'ve proven you can show up. $totalWorkouts workouts completed. This is no longer about trying - you\'re doing it.';
    } else if (totalDays < 66) {
      return 'The transformation is happening. $totalDays days of commitment. Others may not see it yet, but YOU know you\'re different.';
    } else if (totalDays < 100) {
      return 'You\'ve crossed the threshold. This isn\'t a phase anymore - it\'s who you are. $currentStreak days strong.';
    } else {
      return 'You\'re living proof that transformation is real. $totalDays days, $totalWorkouts workouts. Your story inspires others to start their own journey.';
    }
  }

  /// Get journey chapters
  Future<List<Map<String, dynamic>>> getJourneyChapters() async {
    final db = await _dbHelper.database;

    try {
      return await db.query(
        'journey_chapters',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'chapter_number ASC',
      );
    } catch (e) {
      return [];
    }
  }

  /// Generate daily reflection prompt based on journey
  Future<String> getDailyReflectionPrompt() async {
    final stage = await getCurrentStage();
    final journey = await _getUserJourney();

    final prompts = {
      'awakening': [
        'What made you decide to start this journey today?',
        'How do you want to feel 30 days from now?',
        'What\'s the first step you can take today?',
      ],
      'building_foundation': [
        'What habit feels like it\'s starting to stick?',
        'What challenge did you overcome this week?',
        'How has your mindset changed since day 1?',
      ],
      'facing_resistance': [
        'What obstacle are you facing right now?',
        'How will you feel when you push through this?',
        'What would your future self tell you right now?',
      ],
      'breakthrough': [
        'When did you realize you\'ve changed?',
        'What feels different about you now?',
        'Who have you become through this journey?',
      ],
      'mastery': [
        'How can you help someone else start their journey?',
        'What wisdom would you share with your day-1 self?',
        'What\'s your next challenge?',
      ],
      'legend': [
        'How are you inspiring others today?',
        'What legacy are you building?',
        'What does fitness mean to you now?',
      ],
    };

    final stageId = stage['id'] as String? ?? 'awakening';
    final stagePrompts = prompts[stageId] ?? prompts['awakening']!;

    final random = Random();
    return stagePrompts[random.nextInt(stagePrompts.length)];
  }

  /// Log emotional moment
  Future<void> logEmotionalMoment({
    required String momentType,
    required String description,
    int? emotionalIntensity,
    String? photoUrl,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS emotional_moments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        moment_type TEXT,
        description TEXT,
        emotional_intensity INTEGER,
        photo_url TEXT,
        created_date TEXT
      )
    ''');

    await db.insert('emotional_moments', {
      'user_id': userId,
      'moment_type': momentType,
      'description': description,
      'emotional_intensity': emotionalIntensity ?? 5,
      'photo_url': photoUrl,
      'created_date': DateTime.now().toIso8601String(),
    });
  }

  /// Get emotional moments
  Future<List<Map<String, dynamic>>> getEmotionalMoments({int limit = 10}) async {
    final db = await _dbHelper.database;

    try {
      return await db.query(
        'emotional_moments',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_date DESC',
        limit: limit,
      );
    } catch (e) {
      return [];
    }
  }

  /// Generate journey milestone notification
  Future<String> getMilestoneMessage(String milestoneType) async {
    final journey = await _getUserJourney();
    final dreamGoal = journey?['dream_goal'] as String? ?? 'your fitness goal';

    final messages = {
      '7_days': 'Week 1 complete! Remember when you started? Look at you now. $dreamGoal is getting closer.',
      '30_days': 'ONE MONTH! You\'ve proven this isn\'t a phase. You\'re becoming who you always wanted to be.',
      '66_days': 'THIS IS IT! Studies show it takes 66 days to form a habit. You\'ve done it. This is who you are now.',
      '100_days': '100 DAYS! You\'re not the same person who started this journey. You\'ve transformed. You\'re an inspiration.',
      'first_chapter': 'You just wrote your first chapter! This is the beginning of an incredible story.',
      'stage_complete': 'You\'ve completed a major stage of your journey. The next chapter awaits.',
    };

    return messages[milestoneType] ?? 'You\'re making incredible progress!';
  }

  /// Get personalized journey message
  Future<String> getTodayJourneyMessage() async {
    final stage = await getCurrentStage();
    final journey = await _getUserJourney();
    final stats = await _getJourneyStats();

    final daysSinceStart = stats['total_days'] ?? 0;
    final dreamGoal = journey?['dream_goal'] as String? ?? 'transformation';

    // Check for milestones
    if (daysSinceStart == 7) {
      return 'Week 1 complete! Every hero\'s journey starts with a single week. You\'ve taken that step.';
    } else if (daysSinceStart == 30) {
      return '30 days strong! A month ago, $dreamGoal seemed impossible. Now? You\'re living it.';
    } else if (daysSinceStart == 66) {
      return 'The science is clear: 66 days creates a habit. You\'re not trying anymore. You ARE.';
    }

    // Stage-based messages
    final stageArc = stage['story_arc'] as String? ?? 'Your journey continues...';
    return stageArc;
  }

  /// Private helper methods
  Future<Map<String, dynamic>?> _getUserJourney() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'user_journey',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJourneyStats() async {
    final journey = await _getUserJourney();
    if (journey == null) return {};

    final startDate = DateTime.parse(journey['journey_started_date'] as String);
    final totalDays = DateTime.now().difference(startDate).inDays;

    final streak = await _dbHelper.getStreakData(userId, 'exercise');

    return {
      'total_days': totalDays,
      'current_streak': streak?['current_streak'] ?? 0,
      'total_workouts': streak?['total_completions'] ?? 0,
      'longest_streak': streak?['longest_streak'] ?? 0,
    };
  }
}
