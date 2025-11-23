import 'dart:math';
import '../services/database_helper_enhanced.dart';
import 'personal_journey_engine.dart';

/// AI Coach Engine - Your Personal Fitness Companion 🤖
///
/// This isn't just an AI - it's a coach that LEARNS about you, remembers
/// your struggles, celebrates your wins, and adapts to your personality.
/// It becomes YOUR coach, not just A coach.
class AICoachEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;
  late PersonalJourneyEngine _journeyEngine;

  AICoachEngine({required this.userId}) {
    _journeyEngine = PersonalJourneyEngine(userId: userId);
  }

  /// Coach Personality Types - Users can choose their coaching style
  static const Map<String, Map<String, dynamic>> COACH_PERSONALITIES = {
    'motivator': {
      'name': 'The Motivator',
      'description': 'High energy, positive, always hyping you up!',
      'emoji': '🔥',
      'tone': 'LETS GO! You\'re CRUSHING IT!',
      'style': 'energetic',
    },
    'mentor': {
      'name': 'The Mentor',
      'description': 'Wise, supportive, focuses on long-term growth',
      'emoji': '🧘',
      'tone': 'I believe in you. Let\'s take this one step at a time.',
      'style': 'calm',
    },
    'drill_sergeant': {
      'name': 'The Drill Sergeant',
      'description': 'Tough love, no excuses, pushes you hard',
      'emoji': '💪',
      'tone': 'NO EXCUSES! Get it done!',
      'style': 'intense',
    },
    'friend': {
      'name': 'The Supportive Friend',
      'description': 'Understanding, empathetic, celebrates with you',
      'emoji': '🤗',
      'tone': 'I\'m so proud of you! We\'ve got this together!',
      'style': 'friendly',
    },
    'scientist': {
      'name': 'The Scientist',
      'description': 'Data-driven, analytical, optimizes everything',
      'emoji': '🔬',
      'tone': 'Based on your data, here\'s the optimal approach...',
      'style': 'analytical',
    },
  };

  /// Initialize AI Coach
  Future<void> initializeCoach({
    required String personalityType,
    required String userPreferredName,
    String? coachName,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_coach (
        user_id INTEGER PRIMARY KEY,
        personality_type TEXT,
        coach_name TEXT,
        user_preferred_name TEXT,
        relationship_level INTEGER DEFAULT 1,
        total_interactions INTEGER DEFAULT 0,
        last_interaction_date TEXT,
        learned_preferences TEXT,
        memorable_moments TEXT
      )
    ''');

    await db.insert('ai_coach', {
      'user_id': userId,
      'personality_type': personalityType,
      'coach_name': coachName ?? _getDefaultCoachName(personalityType),
      'user_preferred_name': userPreferredName,
      'relationship_level': 1,
      'total_interactions': 0,
      'last_interaction_date': DateTime.now().toIso8601String(),
      'learned_preferences': '{}',
      'memorable_moments': '[]',
    });
  }

  /// Get personalized coaching message
  Future<String> getCoachingMessage({
    required String context,
    Map<String, dynamic>? userData,
  }) async {
    final coach = await _getCoachProfile();
    if (coach == null) return 'Keep going!';

    final personalityType = coach['personality_type'] as String;
    final userName = coach['user_preferred_name'] as String;
    final relationshipLevel = coach['relationship_level'] as int;

    // Record interaction
    await _recordInteraction(context);

    // Get contextual message based on personality
    return _generatePersonalizedMessage(
      personalityType: personalityType,
      userName: userName,
      context: context,
      relationshipLevel: relationshipLevel,
      userData: userData,
    );
  }

  /// Generate personalized message based on coach personality
  String _generatePersonalizedMessage({
    required String personalityType,
    required String userName,
    required String context,
    required int relationshipLevel,
    Map<String, dynamic>? userData,
  }) {
    // Build relationship-aware message
    final useFirstName = relationshipLevel >= 3;
    final userAddress = useFirstName ? userName : 'champ';

    switch (personalityType) {
      case 'motivator':
        return _getMotivatorMessage(context, userAddress, userData);
      case 'mentor':
        return _getMentorMessage(context, userAddress, userData);
      case 'drill_sergeant':
        return _getDrillSergeantMessage(context, userAddress, userData);
      case 'friend':
        return _getFriendMessage(context, userAddress, userData);
      case 'scientist':
        return _getScientistMessage(context, userAddress, userData);
      default:
        return 'You\'re doing great!';
    }
  }

  String _getMotivatorMessage(String context, String name, Map<String, dynamic>? data) {
    final messages = {
      'workout_start': [
        'LETS GOOOO $name! Time to absolutely CRUSH this workout! 🔥',
        'You\'re about to do something incredible, $name! Energy UP! 💪',
        'THIS IS YOUR MOMENT! Show this workout who\'s boss! 🚀',
      ],
      'workout_complete': [
        'YESSSS! That\'s what I\'m talking about! You KILLED it! 🎉',
        '$name, you\'re a MACHINE! Another one in the books! 💯',
        'BOOM! That\'s how champions work! So proud of you! 🏆',
      ],
      'missed_workout': [
        'Hey $name, it happens! But tomorrow? We\'re coming back STRONGER! 💪',
        'One missed day doesn\'t define you! Let\'s bounce back TODAY! 🔥',
        'You know what? This is just fuel for your comeback story! 🚀',
      ],
      'streak_milestone': [
        'ARE YOU KIDDING ME?! ${data?['streak_days']} DAYS! You\'re UNSTOPPABLE! 🔥🔥🔥',
        '$name, this streak is LEGENDARY! Keep this fire burning! 💪',
        'THIS is what dedication looks like! ${data?['streak_days']} days of pure GREATNESS! 👑',
      ],
    };

    final contextMessages = messages[context] ?? messages['workout_start']!;
    return contextMessages[Random().nextInt(contextMessages.length)];
  }

  String _getMentorMessage(String context, String name, Map<String, dynamic>? data) {
    final messages = {
      'workout_start': [
        'Welcome, $name. Remember, this isn\'t about perfection. It\'s about progress.',
        'Today is another opportunity for growth, $name. Embrace it.',
        'Take a deep breath, $name. You\'re exactly where you need to be.',
      ],
      'workout_complete': [
        'Well done, $name. You showed up, and that\'s what matters most.',
        'Another step forward on your journey. I\'m proud of your consistency.',
        'You\'re building something lasting, $name. One workout at a time.',
      ],
      'missed_workout': [
        '$name, setbacks are part of every journey. What matters is what you do next.',
        'I see you, $name. This doesn\'t erase your progress. Tomorrow is a new day.',
        'Let\'s reflect on what happened and learn from it. You\'re stronger than you think.',
      ],
      'streak_milestone': [
        '${data?['streak_days']} days, $name. You\'ve proven something important to yourself.',
        'This streak represents your commitment, $name. You should be proud.',
        'Consistency over ${data?['streak_days']} days? That\'s real transformation, $name.',
      ],
    };

    final contextMessages = messages[context] ?? messages['workout_start']!;
    return contextMessages[Random().nextInt(contextMessages.length)];
  }

  String _getDrillSergeantMessage(String context, String name, Map<String, dynamic>? data) {
    final messages = {
      'workout_start': [
        'Alright $name, NO EXCUSES today! Time to WORK!',
        'Get in there and DOMINATE, $name! I want 100%!',
        'Pain is temporary, $name! Pride is FOREVER! MOVE!',
      ],
      'workout_complete': [
        'GOOD! That\'s what I expect from you, $name! Now keep it up!',
        'Solid work! But don\'t get comfortable - tomorrow we go HARDER!',
        'You did what needed to be done. That\'s basic. Let\'s aim for EXCELLENCE!',
      ],
      'missed_workout': [
        'What happened, $name?! I KNOW you\'re better than this! Get back on track NOW!',
        'One miss I can understand. Two? Not happening. Get it together!',
        'You think champions take days off? Tomorrow, DOUBLE TIME!',
      ],
      'streak_milestone': [
        '${data?['streak_days']} days! FINALLY showing some discipline! Don\'t stop now!',
        'This is just the BEGINNING, $name! ${data?['streak_days']} days means NOTHING if you quit!',
        'Good. ${data?['streak_days']} days of not being weak. Keep pushing!',
      ],
    };

    final contextMessages = messages[context] ?? messages['workout_start']!;
    return contextMessages[Random().nextInt(contextMessages.length)];
  }

  String _getFriendMessage(String context, String name, Map<String, dynamic>? data) {
    final messages = {
      'workout_start': [
        'Hey $name! Ready to do this together? I\'m right here with you! 🤗',
        'You\'ve got this, $name! I believe in you! Let\'s make today great! ❤️',
        'Morning $name! So excited for your workout! You\'re going to feel amazing after! 😊',
      ],
      'workout_complete': [
        'OMG $name! You did it! I\'m so proud of you! 🎉',
        'YES! That\'s my friend right there! You\'re amazing, $name! ❤️',
        'I knew you could do it! Way to go, $name! You inspire me! ✨',
      ],
      'missed_workout': [
        'Hey $name, it\'s okay! Life happens to all of us. Tomorrow is a fresh start! 💕',
        'No judgment here, $name. You\'re human! Let\'s tackle tomorrow together! 🤗',
        'I understand, $name. Be kind to yourself. We\'ll get back on track together! ❤️',
      ],
      'streak_milestone': [
        'OH MY GOSH $name! ${data?['streak_days']} DAYS! I\'m crying happy tears! 😭❤️',
        'Can we just take a moment? ${data?['streak_days']} days, $name! YOU DID THAT! 🎉',
        'I\'m so incredibly proud of you, $name! ${data?['streak_days']} days of showing up! You\'re amazing! ✨',
      ],
    };

    final contextMessages = messages[context] ?? messages['workout_start']!;
    return contextMessages[Random().nextInt(contextMessages.length)];
  }

  String _getScientistMessage(String context, String name, Map<String, dynamic>? data) {
    final messages = {
      'workout_start': [
        'Based on your circadian rhythm, $name, your performance should be optimal now.',
        'Your recovery metrics look good, $name. Let\'s optimize today\'s output.',
        'Analysis shows you perform best at this time, $name. Let\'s capitalize on that.',
      ],
      'workout_complete': [
        'Excellent. Your consistency rate is now ${data?['completion_rate'] ?? 85}%. Trend: positive.',
        'Data logged. Your performance metrics continue to improve, $name.',
        'Another data point confirming your progress. Your trajectory is upward.',
      ],
      'missed_workout': [
        'Noted, $name. This deviation doesn\'t significantly impact your trend line.',
        'One outlier detected. Your overall pattern remains strong. Resume protocol tomorrow.',
        'Historical data shows you bounce back well from setbacks, $name. Continue.',
      ],
      'streak_milestone': [
        '${data?['streak_days']} consecutive days, $name. Statistically significant achievement.',
        'Your adherence rate: ${data?['streak_days']}/100 target. Probability of habit formation: HIGH.',
        'Data confirms: ${data?['streak_days']}-day consistency = behavioral transformation achieved.',
      ],
    };

    final contextMessages = messages[context] ?? messages['workout_start']!;
    return contextMessages[Random().nextInt(contextMessages.length)];
  }

  /// Learn user preferences
  Future<void> learnPreference({
    required String preferenceType,
    required String preferenceValue,
  }) async {
    final db = await _dbHelper.database;
    final coach = await _getCoachProfile();
    if (coach == null) return;

    // Simple learning: store preferences as key-value
    final learned = coach['learned_preferences'] as String;
    // In production, use proper JSON parsing
    final newPreference = '$preferenceType:$preferenceValue';

    await db.update(
      'ai_coach',
      {'learned_preferences': '$learned,$newPreference'},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Remember emotional moment
  Future<void> rememberMoment({
    required String momentDescription,
    required String emotionalContext,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS coach_memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        moment_description TEXT,
        emotional_context TEXT,
        created_date TEXT,
        importance_score INTEGER
      )
    ''');

    await db.insert('coach_memories', {
      'user_id': userId,
      'moment_description': momentDescription,
      'emotional_context': emotionalContext,
      'created_date': DateTime.now().toIso8601String(),
      'importance_score': 5, // Scale 1-10
    });

    // Increase relationship level
    await _increaseRelationship();
  }

  /// Get coach to recall past moments
  Future<String> recallPastMoment(String context) async {
    final db = await _dbHelper.database;

    try {
      final memories = await db.query(
        'coach_memories',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'importance_score DESC, created_date DESC',
        limit: 5,
      );

      if (memories.isEmpty) return '';

      final memory = memories[Random().nextInt(memories.length)];
      final moment = memory['moment_description'] as String;

      final coach = await _getCoachProfile();
      final name = coach?['user_preferred_name'] as String? ?? 'friend';

      return 'Remember $name, when you $moment? Look how far you\'ve come since then!';
    } catch (e) {
      return '';
    }
  }

  /// Get adaptive workout recommendation
  Future<Map<String, dynamic>> getAdaptiveRecommendation({
    required Map<String, dynamic> userState,
  }) async {
    final energyLevel = userState['energy_level'] as int? ?? 5; // 1-10
    final stressLevel = userState['stress_level'] as int? ?? 5;
    final sleepQuality = userState['sleep_quality'] as int? ?? 7;
    final recentPerformance = userState['recent_performance'] as double? ?? 0.8;

    // Calculate optimal workout intensity
    final physicalReadiness = (energyLevel + sleepQuality) / 2;
    final mentalReadiness = (10 - stressLevel + energyLevel) / 2;
    final overallReadiness = (physicalReadiness + mentalReadiness) / 2;

    String recommendedIntensity;
    String coachExplanation;

    if (overallReadiness >= 8) {
      recommendedIntensity = 'high';
      coachExplanation = 'You\'re firing on all cylinders! Let\'s push hard today!';
    } else if (overallReadiness >= 6) {
      recommendedIntensity = 'moderate';
      coachExplanation = 'Good energy! A solid, steady workout is perfect.';
    } else if (overallReadiness >= 4) {
      recommendedIntensity = 'low';
      coachExplanation = 'I see you\'re not at 100%. Let\'s do something lighter today.';
    } else {
      recommendedIntensity = 'recovery';
      coachExplanation = 'Your body needs rest. Let\'s focus on recovery today.';
    }

    return {
      'recommended_intensity': recommendedIntensity,
      'readiness_score': overallReadiness,
      'explanation': coachExplanation,
      'should_modify_plan': overallReadiness < 6,
    };
  }

  /// Private helper methods
  Future<Map<String, dynamic>?> _getCoachProfile() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'ai_coach',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _recordInteraction(String context) async {
    final db = await _dbHelper.database;

    await db.execute('''
      UPDATE ai_coach
      SET total_interactions = total_interactions + 1,
          last_interaction_date = ?
      WHERE user_id = ?
    ''', [DateTime.now().toIso8601String(), userId]);
  }

  Future<void> _increaseRelationship() async {
    final db = await _dbHelper.database;

    await db.execute('''
      UPDATE ai_coach
      SET relationship_level = relationship_level + 1
      WHERE user_id = ? AND relationship_level < 10
    ''', [userId]);
  }

  String _getDefaultCoachName(String personalityType) {
    const names = {
      'motivator': 'Coach Max',
      'mentor': 'Coach Sage',
      'drill_sergeant': 'Sarge',
      'friend': 'Alex',
      'scientist': 'Dr. Fit',
    };
    return names[personalityType] ?? 'Coach';
  }
}
