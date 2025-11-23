import '../services/database_helper_enhanced.dart';
import 'dart:math';

/// Emotional Wellness Engine - Mind & Body Together! 🧠💙
///
/// This tracks the complete wellness picture: mood, energy, stress, sleep.
/// Fitness isn't just physical - mental and emotional health matter too!
class EmotionalWellnessEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  EmotionalWellnessEngine({required this.userId});

  /// Record daily wellness check-in
  Future<int> recordWellnessCheckIn({
    required int moodRating, // 1-5
    required int energyLevel, // 1-5
    required int stressLevel, // 1-5
    required double hoursSlept,
    int? anxietyLevel, // 1-5
    int? motivationLevel, // 1-5
    String? notes,
    List<String>? tags, // ['good_sleep', 'workout_high', 'work_stress']
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS wellness_checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        mood_rating INTEGER,
        energy_level INTEGER,
        stress_level INTEGER,
        anxiety_level INTEGER,
        motivation_level INTEGER,
        hours_slept REAL,
        notes TEXT,
        tags TEXT,
        checkin_date TEXT,
        created_at TEXT
      )
    ''');

    final checkinDate = DateTime.now().toIso8601String().split('T')[0];

    return await db.insert('wellness_checkins', {
      'user_id': userId,
      'mood_rating': moodRating,
      'energy_level': energyLevel,
      'stress_level': stressLevel,
      'anxiety_level': anxietyLevel,
      'motivation_level': motivationLevel,
      'hours_slept': hoursSlept,
      'notes': notes,
      'tags': tags?.join('|||') ?? '',
      'checkin_date': checkinDate,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get today's wellness status
  Future<Map<String, dynamic>?> getTodayWellness() async {
    final db = await _dbHelper.database;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final results = await db.query(
        'wellness_checkins',
        where: 'user_id = ? AND checkin_date = ?',
        whereArgs: [userId, today],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final wellness = results.first;
      return {
        ...wellness,
        'tags': _decodeTags(wellness['tags'] as String?),
        'overall_wellness': _calculateOverallWellness(wellness),
        'wellness_message': _getWellnessMessage(wellness),
      };
    } catch (e) {
      return null;
    }
  }

  /// Get wellness trends
  Future<Map<String, dynamic>> getWellnessTrends({int daysBack = 30}) async {
    final db = await _dbHelper.database;

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      final results = await db.query(
        'wellness_checkins',
        where: 'user_id = ? AND checkin_date >= ?',
        whereArgs: [userId, cutoffDate.toIso8601String().split('T')[0]],
        orderBy: 'checkin_date ASC',
      );

      if (results.isEmpty) {
        return {
          'has_data': false,
        };
      }

      // Calculate averages
      double avgMood = 0;
      double avgEnergy = 0;
      double avgStress = 0;
      double avgSleep = 0;
      int anxietyCount = 0;
      double avgAnxiety = 0;

      for (var r in results) {
        avgMood += (r['mood_rating'] as int? ?? 0);
        avgEnergy += (r['energy_level'] as int? ?? 0);
        avgStress += (r['stress_level'] as int? ?? 0);
        avgSleep += (r['hours_slept'] as double? ?? 0);

        if (r['anxiety_level'] != null) {
          avgAnxiety += (r['anxiety_level'] as int);
          anxietyCount++;
        }
      }

      final count = results.length;
      avgMood /= count;
      avgEnergy /= count;
      avgStress /= count;
      avgSleep /= count;
      if (anxietyCount > 0) avgAnxiety /= anxietyCount;

      // Detect trends (improving/declining)
      final recent7 = results.length > 7 ? results.sublist(results.length - 7) : results;
      final earlier = results.length > 7 ? results.sublist(0, results.length - 7) : [];

      String moodTrend = 'stable';
      if (earlier.isNotEmpty) {
        final recentAvgMood = recent7.map((r) => r['mood_rating'] as int).reduce((a, b) => a + b) / recent7.length;
        final earlierAvgMood = earlier.map((r) => r['mood_rating'] as int).reduce((a, b) => a + b) / earlier.length;

        if (recentAvgMood > earlierAvgMood + 0.5) {
          moodTrend = 'improving';
        } else if (recentAvgMood < earlierAvgMood - 0.5) {
          moodTrend = 'declining';
        }
      }

      return {
        'has_data': true,
        'average_mood': avgMood,
        'average_energy': avgEnergy,
        'average_stress': avgStress,
        'average_sleep': avgSleep,
        'average_anxiety': avgAnxiety,
        'mood_trend': moodTrend,
        'total_checkins': count,
        'checkin_frequency': count / daysBack,
        'wellness_score': _calculateWellnessScore(avgMood, avgEnergy, avgStress, avgSleep),
        'insights': _generateInsights(avgMood, avgEnergy, avgStress, avgSleep),
      };
    } catch (e) {
      return {'has_data': false};
    }
  }

  /// Get mood calendar
  Future<Map<String, int>> getMoodCalendar({int daysBack = 90}) async {
    final db = await _dbHelper.database;

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      final results = await db.query(
        'wellness_checkins',
        where: 'user_id = ? AND checkin_date >= ?',
        whereArgs: [userId, cutoffDate.toIso8601String().split('T')[0]],
        orderBy: 'checkin_date ASC',
      );

      final Map<String, int> calendar = {};

      for (var r in results) {
        final date = r['checkin_date'] as String;
        final mood = r['mood_rating'] as int;
        calendar[date] = mood;
      }

      return calendar;
    } catch (e) {
      return {};
    }
  }

  /// Correlate wellness with workouts
  Future<Map<String, dynamic>> getWorkoutWellnessCorrelation() async {
    final db = await _dbHelper.database;

    try {
      // Get wellness data with workout information
      final results = await db.rawQuery('''
        SELECT
          w.checkin_date,
          w.mood_rating,
          w.energy_level,
          COUNT(dh.id) as workout_completed
        FROM wellness_checkins w
        LEFT JOIN daily_habits dh ON
          dh.user_id = w.user_id AND
          dh.habit_type = 'exercise' AND
          date(dh.completion_date) = w.checkin_date AND
          dh.completed = 1
        WHERE w.user_id = ?
        GROUP BY w.checkin_date
        ORDER BY w.checkin_date DESC
        LIMIT 30
      ''', [userId]);

      if (results.isEmpty) {
        return {
          'has_data': false,
        };
      }

      // Calculate average mood on workout vs non-workout days
      double moodOnWorkoutDays = 0;
      double moodOnRestDays = 0;
      int workoutDayCount = 0;
      int restDayCount = 0;

      for (var r in results) {
        final mood = r['mood_rating'] as int;
        final hadWorkout = (r['workout_completed'] as int) > 0;

        if (hadWorkout) {
          moodOnWorkoutDays += mood;
          workoutDayCount++;
        } else {
          moodOnRestDays += mood;
          restDayCount++;
        }
      }

      if (workoutDayCount > 0) moodOnWorkoutDays /= workoutDayCount;
      if (restDayCount > 0) moodOnRestDays /= restDayCount;

      final moodBoost = moodOnWorkoutDays - moodOnRestDays;

      return {
        'has_data': true,
        'avg_mood_workout_days': moodOnWorkoutDays,
        'avg_mood_rest_days': moodOnRestDays,
        'mood_boost_from_exercise': moodBoost,
        'insight': _getCorrelationInsight(moodBoost),
      };
    } catch (e) {
      return {'has_data': false};
    }
  }

  /// Record gratitude/wins
  Future<int> recordGratitude({
    required String gratitudeText,
    String? category, // 'win', 'gratitude', 'proud_moment'
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS gratitude_journal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        gratitude_text TEXT,
        category TEXT,
        recorded_date TEXT,
        created_at TEXT
      )
    ''');

    return await db.insert('gratitude_journal', {
      'user_id': userId,
      'gratitude_text': gratitudeText,
      'category': category ?? 'gratitude',
      'recorded_date': DateTime.now().toIso8601String().split('T')[0],
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get recent gratitude entries
  Future<List<Map<String, dynamic>>> getGratitudeEntries({int limit = 10}) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'gratitude_journal',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return results.toList();
    } catch (e) {
      return [];
    }
  }

  /// Suggest wellness actions based on current state
  Future<List<String>> suggestWellnessActions() async {
    final today = await getTodayWellness();

    if (today == null) {
      return [
        'Check in with yourself today! How are you feeling?',
        'A quick wellness check-in helps track your journey',
      ];
    }

    final suggestions = <String>[];

    final mood = today['mood_rating'] as int;
    final energy = today['energy_level'] as int;
    final stress = today['stress_level'] as int;
    final sleep = today['hours_slept'] as double;

    // Low mood
    if (mood <= 2) {
      suggestions.add('💙 Low mood detected. Remember: This is temporary. You\'re stronger than this moment.');
      suggestions.add('Consider a gentle walk or calling a friend');
    }

    // Low energy
    if (energy <= 2) {
      suggestions.add('⚡ Low energy? Maybe try a lighter workout or take a rest day');
      suggestions.add('Hydration and a healthy snack might help!');
    }

    // High stress
    if (stress >= 4) {
      suggestions.add('😌 High stress alert. Breathing exercises or meditation?');
      suggestions.add('Exercise actually reduces stress hormones!');
    }

    // Poor sleep
    if (sleep < 6.0) {
      suggestions.add('😴 Sleep matters! Try to get 7-9 hours tonight');
      suggestions.add('Consider an earlier bedtime routine');
    }

    if (suggestions.isEmpty) {
      suggestions.add('You\'re doing great! Keep taking care of yourself! 💚');
    }

    return suggestions;
  }

  /// Get wellness insights and patterns
  Future<List<String>> getWellnessInsights() async {
    final trends = await getWellnessTrends(daysBack: 30);
    final correlation = await getWorkoutWellnessCorrelation();

    final insights = <String>[];

    if (trends['has_data'] == true) {
      final avgMood = trends['average_mood'] as double;
      final avgSleep = trends['average_sleep'] as double;
      final moodTrend = trends['mood_trend'] as String;

      if (moodTrend == 'improving') {
        insights.add('📈 Your mood is trending UP! Whatever you\'re doing is working!');
      } else if (moodTrend == 'declining') {
        insights.add('📉 Mood dipping lately? Let\'s talk about self-care strategies');
      }

      if (avgSleep < 7.0) {
        insights.add('💤 You\'re averaging ${avgSleep.toStringAsFixed(1)} hours of sleep. Aim for 7-9!');
      }

      if (avgMood >= 4.0) {
        insights.add('🌟 Your average mood is excellent! You\'re thriving!');
      }
    }

    if (correlation['has_data'] == true) {
      final moodBoost = correlation['mood_boost_from_exercise'] as double;

      if (moodBoost > 0.5) {
        insights.add('💪 Workouts boost your mood by ${moodBoost.toStringAsFixed(1)} points on average!');
      }
    }

    return insights;
  }

  /// Private helper methods
  List<String> _decodeTags(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    return encoded.split('|||');
  }

  double _calculateOverallWellness(Map<String, dynamic> wellness) {
    final mood = wellness['mood_rating'] as int;
    final energy = wellness['energy_level'] as int;
    final stress = wellness['stress_level'] as int;
    final sleep = wellness['hours_slept'] as double;

    // Normalize sleep to 1-5 scale (7-9 hours = optimal)
    double sleepScore = 5.0;
    if (sleep < 6) {
      sleepScore = (sleep / 6) * 3; // Very low
    } else if (sleep > 9) {
      sleepScore = 4.0;
    } else {
      sleepScore = 5.0; // Optimal
    }

    // Stress is inverted (high stress = bad)
    final stressScore = 6 - stress;

    return (mood + energy + stressScore + sleepScore) / 4;
  }

  String _getWellnessMessage(Map<String, dynamic> wellness) {
    final overall = _calculateOverallWellness(wellness);

    if (overall >= 4.5) {
      return 'You\'re feeling AMAZING today! Ride this wave! 🌊';
    } else if (overall >= 3.5) {
      return 'Solid day! You\'re doing well! 💪';
    } else if (overall >= 2.5) {
      return 'Mixed feelings today. That\'s okay. Be kind to yourself. 💙';
    } else {
      return 'Tough day? Remember: Bad days don\'t last. You\'re resilient. 🌱';
    }
  }

  double _calculateWellnessScore(double avgMood, double avgEnergy, double avgStress, double avgSleep) {
    // Normalize to 0-100 scale
    final moodScore = (avgMood / 5) * 25;
    final energyScore = (avgEnergy / 5) * 25;
    final stressScore = ((5 - avgStress) / 5) * 25; // Inverted
    final sleepScore = ((avgSleep / 8).clamp(0, 1)) * 25;

    return moodScore + energyScore + stressScore + sleepScore;
  }

  List<String> _generateInsights(double avgMood, double avgEnergy, double avgStress, double avgSleep) {
    final insights = <String>[];

    if (avgSleep < 7.0) {
      insights.add('💤 Sleep Alert: You\'re averaging ${avgSleep.toStringAsFixed(1)} hours. Aim for 7-9!');
    }

    if (avgStress >= 3.5) {
      insights.add('😰 Stress levels are elevated. Consider stress management techniques');
    }

    if (avgMood >= 4.0) {
      insights.add('😊 Great mood overall! Keep doing what you\'re doing!');
    } else if (avgMood < 2.5) {
      insights.add('💙 Mood has been low. Consider reaching out for support');
    }

    if (avgEnergy < 2.5) {
      insights.add('⚡ Low energy detected. Check sleep, nutrition, and stress levels');
    }

    return insights;
  }

  String _getCorrelationInsight(double moodBoost) {
    if (moodBoost >= 1.0) {
      return 'POWERFUL! Exercise boosts your mood significantly. That\'s your superpower! 💪';
    } else if (moodBoost >= 0.5) {
      return 'Exercise consistently improves your mood. Science in action! 🧪';
    } else if (moodBoost > 0) {
      return 'Exercise has a positive effect on your mood. Keep it up! ✨';
    } else {
      return 'Interesting! Mood seems independent of workouts. Mental state varies! 🧠';
    }
  }
}
