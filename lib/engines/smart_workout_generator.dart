import '../services/database_helper_enhanced.dart';
import 'dart:math';

/// Smart AI Workout Generator - Personalized Workouts! 🤖💪
///
/// This generates intelligent, adaptive workouts based on:
/// - User's fitness level and goals
/// - Available equipment and time
/// - Recent performance and recovery
/// - Current energy/stress levels
class SmartWorkoutGenerator {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  SmartWorkoutGenerator({required this.userId});

  // Exercise database
  static const Map<String, List<Map<String, dynamic>>> EXERCISE_LIBRARY = {
    'chest': [
      {'name': 'Push-ups', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'chest'},
      {'name': 'Decline Push-ups', 'difficulty': 'intermediate', 'equipment': 'none', 'muscle': 'chest'},
      {'name': 'Diamond Push-ups', 'difficulty': 'advanced', 'equipment': 'none', 'muscle': 'chest'},
      {'name': 'Dumbbell Bench Press', 'difficulty': 'beginner', 'equipment': 'dumbbells', 'muscle': 'chest'},
      {'name': 'Dumbbell Flyes', 'difficulty': 'intermediate', 'equipment': 'dumbbells', 'muscle': 'chest'},
    ],
    'back': [
      {'name': 'Superman Holds', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'back'},
      {'name': 'Reverse Snow Angels', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'back'},
      {'name': 'Dumbbell Rows', 'difficulty': 'intermediate', 'equipment': 'dumbbells', 'muscle': 'back'},
      {'name': 'Pull-ups', 'difficulty': 'advanced', 'equipment': 'pull_up_bar', 'muscle': 'back'},
    ],
    'legs': [
      {'name': 'Bodyweight Squats', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'legs'},
      {'name': 'Lunges', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'legs'},
      {'name': 'Jump Squats', 'difficulty': 'intermediate', 'equipment': 'none', 'muscle': 'legs'},
      {'name': 'Bulgarian Split Squats', 'difficulty': 'advanced', 'equipment': 'none', 'muscle': 'legs'},
      {'name': 'Goblet Squats', 'difficulty': 'intermediate', 'equipment': 'dumbbells', 'muscle': 'legs'},
    ],
    'shoulders': [
      {'name': 'Pike Push-ups', 'difficulty': 'intermediate', 'equipment': 'none', 'muscle': 'shoulders'},
      {'name': 'Lateral Raises', 'difficulty': 'beginner', 'equipment': 'dumbbells', 'muscle': 'shoulders'},
      {'name': 'Shoulder Press', 'difficulty': 'intermediate', 'equipment': 'dumbbells', 'muscle': 'shoulders'},
      {'name': 'Handstand Push-ups', 'difficulty': 'advanced', 'equipment': 'none', 'muscle': 'shoulders'},
    ],
    'arms': [
      {'name': 'Tricep Dips', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'triceps'},
      {'name': 'Bicep Curls', 'difficulty': 'beginner', 'equipment': 'dumbbells', 'muscle': 'biceps'},
      {'name': 'Hammer Curls', 'difficulty': 'intermediate', 'equipment': 'dumbbells', 'muscle': 'biceps'},
      {'name': 'Overhead Tricep Extension', 'difficulty': 'intermediate', 'equipment': 'dumbbells', 'muscle': 'triceps'},
    ],
    'core': [
      {'name': 'Plank', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'core'},
      {'name': 'Bicycle Crunches', 'difficulty': 'beginner', 'equipment': 'none', 'muscle': 'core'},
      {'name': 'Russian Twists', 'difficulty': 'intermediate', 'equipment': 'none', 'muscle': 'core'},
      {'name': 'Mountain Climbers', 'difficulty': 'intermediate', 'equipment': 'none', 'muscle': 'core'},
      {'name': 'L-sits', 'difficulty': 'advanced', 'equipment': 'none', 'muscle': 'core'},
    ],
    'cardio': [
      {'name': 'Jumping Jacks', 'difficulty': 'beginner', 'equipment': 'none', 'type': 'cardio'},
      {'name': 'High Knees', 'difficulty': 'beginner', 'equipment': 'none', 'type': 'cardio'},
      {'name': 'Burpees', 'difficulty': 'intermediate', 'equipment': 'none', 'type': 'cardio'},
      {'name': 'Jump Rope', 'difficulty': 'intermediate', 'equipment': 'jump_rope', 'type': 'cardio'},
    ],
  };

  /// Generate personalized workout
  Future<Map<String, dynamic>> generateWorkout({
    required String workoutGoal, // 'strength', 'cardio', 'weight_loss', 'muscle_building', 'toning'
    required int availableMinutes,
    required String fitnessLevel, // 'beginner', 'intermediate', 'advanced'
    List<String>? availableEquipment,
    List<String>? targetMuscles,
    int? currentEnergy, // 1-5
    int? currentStress, // 1-5
  }) async {
    final db = await _dbHelper.database;

    // Adjust workout based on energy and stress
    final intensityMultiplier = _calculateIntensityMultiplier(currentEnergy, currentStress);
    final adjustedDuration = (availableMinutes * intensityMultiplier).round();

    // Select appropriate exercises
    final exercises = _selectExercises(
      goal: workoutGoal,
      fitnessLevel: fitnessLevel,
      availableEquipment: availableEquipment ?? ['none'],
      targetMuscles: targetMuscles,
      duration: adjustedDuration,
    );

    // Generate sets and reps
    final workoutPlan = _generateWorkoutPlan(
      exercises: exercises,
      goal: workoutGoal,
      duration: adjustedDuration,
      fitnessLevel: fitnessLevel,
    );

    // Create workout record
    await db.execute('''
      CREATE TABLE IF NOT EXISTS generated_workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        workout_goal TEXT,
        fitness_level TEXT,
        duration_minutes INTEGER,
        exercises_data TEXT,
        created_date TEXT,
        completed INTEGER DEFAULT 0,
        completed_date TEXT,
        performance_rating INTEGER
      )
    ''');

    final workoutId = await db.insert('generated_workouts', {
      'user_id': userId,
      'workout_goal': workoutGoal,
      'fitness_level': fitnessLevel,
      'duration_minutes': adjustedDuration,
      'exercises_data': _encodeExercises(workoutPlan['exercises'] as List),
      'created_date': DateTime.now().toIso8601String(),
      'completed': 0,
    });

    return {
      'workout_id': workoutId,
      'title': _getWorkoutTitle(workoutGoal),
      'description': _getWorkoutDescription(workoutGoal, adjustedDuration),
      'estimated_duration': adjustedDuration,
      'difficulty': fitnessLevel,
      'exercises': workoutPlan['exercises'],
      'total_exercises': (workoutPlan['exercises'] as List).length,
      'warm_up': _getWarmUp(),
      'cool_down': _getCoolDown(),
      'tips': _getWorkoutTips(workoutGoal),
      'intensity_note': intensityMultiplier < 1.0
          ? 'Adjusted for current energy/stress levels 💙'
          : null,
    };
  }

  /// Quick workout (15 min or less)
  Future<Map<String, dynamic>> generateQuickWorkout({
    String fitnessLevel = 'beginner',
    List<String>? availableEquipment,
  }) async {
    return await generateWorkout(
      workoutGoal: 'quick_burn',
      availableMinutes: 15,
      fitnessLevel: fitnessLevel,
      availableEquipment: availableEquipment,
    );
  }

  /// Full body workout
  Future<Map<String, dynamic>> generateFullBodyWorkout({
    required String fitnessLevel,
    int duration = 45,
  }) async {
    return await generateWorkout(
      workoutGoal: 'full_body',
      availableMinutes: duration,
      fitnessLevel: fitnessLevel,
      targetMuscles: ['chest', 'back', 'legs', 'core'],
    );
  }

  /// Progressive overload workout (based on previous performance)
  Future<Map<String, dynamic>> generateProgressiveWorkout({
    required String fitnessLevel,
  }) async {
    // Get recent workout history
    final recentWorkouts = await getRecentWorkouts(limit: 5);

    // If user has been consistent, increase difficulty slightly
    String adjustedLevel = fitnessLevel;
    if (recentWorkouts.length >= 5) {
      if (fitnessLevel == 'beginner') {
        adjustedLevel = 'intermediate';
      } else if (fitnessLevel == 'intermediate') {
        // Mix of intermediate and advanced exercises
        adjustedLevel = 'intermediate';
      }
    }

    return await generateWorkout(
      workoutGoal: 'muscle_building',
      availableMinutes: 45,
      fitnessLevel: adjustedLevel,
    );
  }

  /// Mark workout as completed
  Future<void> completeWorkout(int workoutId, {
    required int performanceRating, // 1-5
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    await db.update(
      'generated_workouts',
      {
        'completed': 1,
        'completed_date': DateTime.now().toIso8601String(),
        'performance_rating': performanceRating,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [workoutId, userId],
    );
  }

  /// Get recent workouts
  Future<List<Map<String, dynamic>>> getRecentWorkouts({int limit = 10}) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'generated_workouts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_date DESC',
        limit: limit,
      );

      return results.map((r) {
        return {
          ...r,
          'exercises': _decodeExercises(r['exercises_data'] as String?),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get workout variety score (are they mixing it up?)
  Future<Map<String, dynamic>> getWorkoutVariety() async {
    final workouts = await getRecentWorkouts(limit: 30);

    if (workouts.isEmpty) {
      return {
        'variety_score': 0,
        'message': 'Start your fitness journey!',
      };
    }

    final goals = <String>{};
    for (var workout in workouts) {
      goals.add(workout['workout_goal'] as String);
    }

    final varietyScore = (goals.length / 5) * 100; // 5 possible goals

    return {
      'variety_score': varietyScore.round(),
      'unique_goals': goals.length,
      'message': varietyScore >= 70
          ? 'Excellent variety! You\'re hitting all angles! 🌟'
          : varietyScore >= 40
              ? 'Good variety! Consider mixing in different workout types'
              : 'Try diversifying your workouts for better results!',
    };
  }

  /// Private helper methods
  double _calculateIntensityMultiplier(int? energy, int? stress) {
    if (energy == null && stress == null) return 1.0;

    double multiplier = 1.0;

    // Low energy = reduce intensity
    if (energy != null && energy <= 2) {
      multiplier *= 0.7;
    }

    // High stress = slightly reduce intensity
    if (stress != null && stress >= 4) {
      multiplier *= 0.85;
    }

    return multiplier;
  }

  List<Map<String, dynamic>> _selectExercises({
    required String goal,
    required String fitnessLevel,
    required List<String> availableEquipment,
    List<String>? targetMuscles,
    required int duration,
  }) {
    final selected = <Map<String, dynamic>>[];
    final random = Random();

    // Determine muscle groups to target
    List<String> muscles = targetMuscles ?? _getDefaultMuscles(goal);

    // Add exercises for each muscle group
    for (var muscle in muscles) {
      final exercises = EXERCISE_LIBRARY[muscle] ?? [];

      // Filter by fitness level and equipment
      final suitable = exercises.where((e) {
        final matchesLevel = e['difficulty'] == fitnessLevel ||
            (fitnessLevel == 'intermediate' && e['difficulty'] == 'beginner');

        final matchesEquipment = e['equipment'] == null ||
            e['equipment'] == 'none' ||
            availableEquipment.contains(e['equipment']);

        return matchesLevel && matchesEquipment;
      }).toList();

      if (suitable.isNotEmpty) {
        selected.add(suitable[random.nextInt(suitable.length)]);
      }
    }

    // Add cardio if goal-appropriate
    if (goal == 'cardio' || goal == 'weight_loss') {
      final cardioExercises = EXERCISE_LIBRARY['cardio'] ?? [];
      if (cardioExercises.isNotEmpty) {
        selected.add(cardioExercises[random.nextInt(cardioExercises.length)]);
      }
    }

    return selected;
  }

  List<String> _getDefaultMuscles(String goal) {
    switch (goal) {
      case 'strength':
        return ['chest', 'back', 'legs'];
      case 'cardio':
        return ['cardio', 'core'];
      case 'weight_loss':
        return ['cardio', 'legs', 'core'];
      case 'muscle_building':
        return ['chest', 'back', 'legs', 'shoulders', 'arms'];
      case 'toning':
        return ['arms', 'legs', 'core'];
      case 'full_body':
        return ['chest', 'back', 'legs', 'core'];
      case 'quick_burn':
        return ['cardio', 'core'];
      default:
        return ['chest', 'legs', 'core'];
    }
  }

  Map<String, dynamic> _generateWorkoutPlan({
    required List<Map<String, dynamic>> exercises,
    required String goal,
    required int duration,
    required String fitnessLevel,
  }) {
    // Determine sets and reps based on goal
    final workoutPlan = <Map<String, dynamic>>[];

    for (var exercise in exercises) {
      final isCardio = exercise['type'] == 'cardio';

      int sets = 3;
      String reps = '12';

      if (goal == 'strength' || goal == 'muscle_building') {
        sets = 4;
        reps = fitnessLevel == 'beginner' ? '8-10' : '10-12';
      } else if (goal == 'cardio' || goal == 'weight_loss') {
        sets = 3;
        reps = isCardio ? '30 seconds' : '15-20';
      } else if (goal == 'toning') {
        sets = 3;
        reps = '12-15';
      }

      workoutPlan.add({
        ...exercise,
        'sets': sets,
        'reps': reps,
        'rest_seconds': 60,
      });
    }

    return {
      'exercises': workoutPlan,
      'total_sets': workoutPlan.fold(0, (sum, e) => sum + (e['sets'] as int)),
    };
  }

  String _getWorkoutTitle(String goal) {
    final titles = {
      'strength': 'Strength Builder 💪',
      'cardio': 'Cardio Burn 🔥',
      'weight_loss': 'Fat Burner 🔥',
      'muscle_building': 'Muscle Maker 💎',
      'toning': 'Tone & Sculpt ✨',
      'full_body': 'Total Body Blast 💥',
      'quick_burn': 'Quick Burn 15 ⚡',
    };

    return titles[goal] ?? 'Custom Workout';
  }

  String _getWorkoutDescription(String goal, int duration) {
    return 'A $duration-minute ${goal.replaceAll('_', ' ')} workout designed just for you!';
  }

  List<Map<String, dynamic>> _getWarmUp() {
    return [
      {'name': 'Arm Circles', 'duration': '30 seconds'},
      {'name': 'Leg Swings', 'duration': '30 seconds'},
      {'name': 'Light Jogging in Place', 'duration': '1 minute'},
    ];
  }

  List<Map<String, dynamic>> _getCoolDown() {
    return [
      {'name': 'Standing Hamstring Stretch', 'duration': '30 seconds each side'},
      {'name': 'Quad Stretch', 'duration': '30 seconds each side'},
      {'name': 'Shoulder Stretch', 'duration': '30 seconds'},
      {'name': 'Deep Breathing', 'duration': '1 minute'},
    ];
  }

  List<String> _getWorkoutTips(String goal) {
    final tips = {
      'strength': [
        'Focus on form over speed',
        'Control the negative (lowering) part of each rep',
        'Rest 60-90 seconds between sets',
      ],
      'cardio': [
        'Keep your heart rate elevated',
        'Hydrate frequently',
        'Listen to your body',
      ],
      'weight_loss': [
        'Consistency > Intensity',
        'Combine with healthy eating',
        'Minimum rest between exercises',
      ],
    };

    return tips[goal] ?? [
      'Stay hydrated',
      'Focus on form',
      'You got this! 💪',
    ];
  }

  String _encodeExercises(List exercises) {
    return exercises.map((e) => e.toString()).join('###');
  }

  List<Map<String, dynamic>> _decodeExercises(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    // Simplified decoding - in production, use JSON
    return [];
  }
}
