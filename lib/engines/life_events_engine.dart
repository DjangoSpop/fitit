import '../services/database_helper_enhanced.dart';
import 'habit_formation_engine.dart';
import 'gamification_engine.dart';

/// Life Events Integration Engine - Life Happens! 🌊
///
/// This engine helps the app adapt to major life events that impact
/// fitness routines: vacations, illness, stress, new job, moving, etc.
/// Instead of breaking streaks, we adapt and show compassion.
class LifeEventsEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;
  late HabitFormationEngine _habitEngine;
  late GamificationEngine _gamificationEngine;

  LifeEventsEngine({required this.userId}) {
    _habitEngine = HabitFormationEngine(userId: userId);
    _gamificationEngine = GamificationEngine(userId: userId);
  }

  // Life event types
  static const Map<String, Map<String, dynamic>> EVENT_TYPES = {
    'vacation': {
      'name': 'Vacation / Travel',
      'emoji': '✈️',
      'impact_level': 'medium',
      'adaptive_tips': [
        'Hotel room workouts are perfectly valid!',
        'Walking/exploring counts as exercise',
        'Enjoy yourself! Consistency includes flexibility',
      ],
      'suggested_workout_reduction': 0.5,
    },
    'illness': {
      'name': 'Illness / Injury',
      'emoji': '🤒',
      'impact_level': 'high',
      'adaptive_tips': [
        'Rest is productive. Your body needs recovery',
        'Gentle movement when you feel ready',
        'Comeback > Pushing through injury',
      ],
      'suggested_workout_reduction': 0.8,
    },
    'work_stress': {
      'name': 'High Work Stress',
      'emoji': '💼',
      'impact_level': 'medium',
      'adaptive_tips': [
        'Even 10-minute workouts count!',
        'Exercise actually reduces stress',
        'Lower intensity, maintain consistency',
      ],
      'suggested_workout_reduction': 0.3,
    },
    'family_event': {
      'name': 'Major Family Event',
      'emoji': '👨‍👩‍👧',
      'impact_level': 'medium',
      'adaptive_tips': [
        'Family first, always',
        'Quick bodyweight sessions work wonders',
        'Your commitment hasn\'t changed',
      ],
      'suggested_workout_reduction': 0.4,
    },
    'new_job': {
      'name': 'New Job / Career Change',
      'emoji': '🚀',
      'impact_level': 'high',
      'adaptive_tips': [
        'Adjustment period is normal',
        'Morning workouts = consistent schedule',
        'You\'re handling two big changes like a pro!',
      ],
      'suggested_workout_reduction': 0.5,
    },
    'moving': {
      'name': 'Moving / Relocation',
      'emoji': '📦',
      'impact_level': 'high',
      'adaptive_tips': [
        'Lifting boxes = workout! 💪',
        'Explore your new neighborhood on foot',
        'New place, new opportunities',
      ],
      'suggested_workout_reduction': 0.6,
    },
    'mental_health': {
      'name': 'Mental Health / Low Energy',
      'emoji': '🧠',
      'impact_level': 'high',
      'adaptive_tips': [
        'ANY movement is a victory',
        'Be kind to yourself',
        'Showing up is 90% of success',
      ],
      'suggested_workout_reduction': 0.7,
    },
    'celebration': {
      'name': 'Holiday / Celebration',
      'emoji': '🎉',
      'impact_level': 'low',
      'adaptive_tips': [
        'Celebrate life!',
        'Balance is part of the journey',
        'Back to routine tomorrow 😊',
      ],
      'suggested_workout_reduction': 0.3,
    },
  };

  /// Record life event
  Future<int> recordLifeEvent({
    required String eventType,
    required DateTime startDate,
    DateTime? endDate,
    String? customDescription,
    String? feelingNote,
    bool protectStreak = true,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS life_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        event_type TEXT,
        custom_description TEXT,
        feeling_note TEXT,
        start_date TEXT,
        end_date TEXT,
        protect_streak INTEGER,
        is_active INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    final eventId = await db.insert('life_events', {
      'user_id': userId,
      'event_type': eventType,
      'custom_description': customDescription,
      'feeling_note': feelingNote,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'protect_streak': protectStreak ? 1 : 0,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // If streak protection is enabled, activate streak freeze
    if (protectStreak) {
      await _gamificationEngine.activatePowerUp('streak_freeze');
    }

    return eventId;
  }

  /// Get active life events
  Future<List<Map<String, dynamic>>> getActiveLifeEvents() async {
    final db = await _dbHelper.database;

    try {
      final now = DateTime.now();
      final results = await db.rawQuery('''
        SELECT * FROM life_events
        WHERE user_id = ?
        AND is_active = 1
        AND (end_date IS NULL OR end_date >= ?)
        ORDER BY start_date DESC
      ''', [userId, now.toIso8601String()]);

      return results.map((r) {
        final eventType = r['event_type'] as String;
        final template = EVENT_TYPES[eventType] ?? {};

        return {
          ...r,
          'event_info': template,
          'days_active': _calculateDaysActive(r['start_date'] as String),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// End life event
  Future<void> endLifeEvent(int eventId) async {
    final db = await _dbHelper.database;

    await db.update(
      'life_events',
      {
        'is_active': 0,
        'end_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
    );
  }

  /// Get adaptive workout plan
  Future<Map<String, dynamic>> getAdaptiveWorkoutPlan() async {
    final activeEvents = await getActiveLifeEvents();

    if (activeEvents.isEmpty) {
      return {
        'adaptation_needed': false,
        'workout_intensity': 1.0,
        'message': 'Full steam ahead! No active life events.',
      };
    }

    // Calculate combined impact
    double maxReduction = 0.0;
    String primaryEventType = '';

    for (var event in activeEvents) {
      final eventInfo = event['event_info'] as Map<String, dynamic>;
      final reduction = eventInfo['suggested_workout_reduction'] as double? ?? 0.0;

      if (reduction > maxReduction) {
        maxReduction = reduction;
        primaryEventType = event['event_type'] as String;
      }
    }

    final intensity = 1.0 - maxReduction;
    final eventTemplate = EVENT_TYPES[primaryEventType];

    return {
      'adaptation_needed': true,
      'workout_intensity': intensity,
      'primary_event': primaryEventType,
      'adaptive_tips': eventTemplate?['adaptive_tips'] ?? [],
      'message': _getAdaptiveMessage(primaryEventType, intensity),
      'suggested_duration_multiplier': intensity,
    };
  }

  /// Check if user should get compassion instead of streak warning
  Future<bool> shouldShowCompassion() async {
    final activeEvents = await getActiveLifeEvents();

    // If there are high-impact events, show compassion
    for (var event in activeEvents) {
      final eventInfo = event['event_info'] as Map<String, dynamic>;
      final impactLevel = eventInfo['impact_level'] as String?;

      if (impactLevel == 'high') {
        return true;
      }
    }

    return false;
  }

  /// Get compassionate message
  Future<String> getCompassionateMessage() async {
    final activeEvents = await getActiveLifeEvents();

    if (activeEvents.isEmpty) {
      return 'Remember, every champion takes rest days. You\'re doing great! 💪';
    }

    final event = activeEvents.first;
    final eventInfo = event['event_info'] as Map<String, dynamic>;
    final tips = eventInfo['adaptive_tips'] as List<dynamic>;

    if (tips.isNotEmpty) {
      return tips.first as String;
    }

    return 'Life happens. The fact that you\'re here shows your commitment. 💙';
  }

  /// Record how user felt during event
  Future<void> recordEventFeeling(int eventId, String feeling, {String? note}) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_feelings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER,
        feeling TEXT,
        note TEXT,
        recorded_at TEXT
      )
    ''');

    await db.insert('event_feelings', {
      'event_id': eventId,
      'feeling': feeling,
      'note': note,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get event history
  Future<List<Map<String, dynamic>>> getEventHistory({int limit = 10}) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'life_events',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'start_date DESC',
        limit: limit,
      );

      return results.map((r) {
        final eventType = r['event_type'] as String;
        final template = EVENT_TYPES[eventType] ?? {};

        return {
          ...r,
          'event_info': template,
          'duration': _calculateEventDuration(
            r['start_date'] as String,
            r['end_date'] as String?,
          ),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Suggest life event based on behavior
  Future<Map<String, dynamic>?> suggestLifeEvent() async {
    // Analyze recent behavior to suggest if user might be experiencing a life event
    final stats = await _habitEngine.getUserEngagementStats();
    final weeklyCompletion = stats['weekly_completion'] as double;
    final daysSinceLastWorkout = stats['days_since_last_workout'] as int;

    // If completion dropped significantly
    if (weeklyCompletion < 0.3 && daysSinceLastWorkout > 3) {
      return {
        'suggested': true,
        'message': 'We noticed a change in your routine. Everything okay? Life events happen!',
        'suggested_events': ['illness', 'work_stress', 'mental_health'],
      };
    }

    return null;
  }

  /// Get resilience score
  Future<Map<String, dynamic>> getResilienceScore() async {
    final db = await _dbHelper.database;

    try {
      // Get all completed events
      final events = await db.query(
        'life_events',
        where: 'user_id = ? AND is_active = 0',
        whereArgs: [userId],
      );

      if (events.isEmpty) {
        return {
          'resilience_score': 100,
          'events_overcome': 0,
          'message': 'Smooth sailing so far! 🌊',
        };
      }

      // Count how many events user pushed through
      int eventsWithWorkouts = 0;

      for (var event in events) {
        final startDate = event['start_date'] as String;
        final endDate = event['end_date'] as String?;

        if (endDate != null) {
          // Check if user worked out during this period
          final workoutsDuring = await _habitEngine.getWorkoutCount(
            startDate: DateTime.parse(startDate),
            endDate: DateTime.parse(endDate),
          );

          if (workoutsDuring > 0) {
            eventsWithWorkouts++;
          }
        }
      }

      final resilienceScore = events.isEmpty
          ? 100
          : ((eventsWithWorkouts / events.length) * 100).round();

      return {
        'resilience_score': resilienceScore,
        'events_overcome': events.length,
        'events_with_workouts': eventsWithWorkouts,
        'message': _getResilienceMessage(resilienceScore),
      };
    } catch (e) {
      return {
        'resilience_score': 100,
        'events_overcome': 0,
        'message': 'Keep building your resilience! 💪',
      };
    }
  }

  /// Private helper methods
  int _calculateDaysActive(String startDateString) {
    final startDate = DateTime.parse(startDateString);
    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }

  int _calculateEventDuration(String startDateString, String? endDateString) {
    final startDate = DateTime.parse(startDateString);
    final endDate = endDateString != null
        ? DateTime.parse(endDateString)
        : DateTime.now();

    return endDate.difference(startDate).inDays;
  }

  String _getAdaptiveMessage(String eventType, double intensity) {
    final messages = {
      'vacation': 'Enjoy your vacation! Even light activity counts. Travel safely! ✈️',
      'illness': 'Recovery is progress. Listen to your body. Get well soon! 🤒',
      'work_stress': 'Work is demanding, but so are you! Short workouts are perfect. 💼',
      'family_event': 'Family comes first. Proud of you for showing up anyway! 👨‍👩‍👧',
      'new_job': 'New beginnings! Morning workouts = great start to work days. 🚀',
      'moving': 'Moving is intense! You\'re getting plenty of exercise. 📦',
      'mental_health': 'Taking care of your mind matters. Gentle movement helps. 🧠',
      'celebration': 'Celebrate life! Balance is beautiful. 🎉',
    };

    return messages[eventType] ?? 'Life is happening. Adapt and overcome! 💪';
  }

  String _getResilienceMessage(int score) {
    if (score >= 80) {
      return 'UNBREAKABLE! You push through EVERYTHING! 💎';
    } else if (score >= 60) {
      return 'Strong resilience! Life throws punches, you keep going! 🥊';
    } else if (score >= 40) {
      return 'Building resilience! Each challenge makes you stronger! 🌱';
    } else {
      return 'Resilience is learned. You\'re on the journey! 💪';
    }
  }
}
