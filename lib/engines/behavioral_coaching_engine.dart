import '../models/user_profile_model.dart';

class BehavioralCoachingEngine {
  BehavioralCoachingEngine();

  // Generate psychology-informed workout plan prompt
  String generateWorkoutPlanPrompt(
    UserProfile profile,
    Map<String, dynamic> performanceHistory,
  ) {
    final completionRate = performanceHistory['completion_rate'] as double? ?? 0.7;
    final currentStreak = performanceHistory['current_streak'] as int? ?? 0;
    final previouslyDroppedOff = performanceHistory['dropout_pattern'] as String? ?? '';

    return '''
You are an expert behavioral coach specializing in habit formation and psychology-driven fitness coaching.

USER CONTEXT:
- Name: ${profile.name}
- Age: ${profile.age}, Gender: ${profile.gender}
- Fitness Level: ${profile.fitnessLevel}
- Goal: ${profile.goals.join(', ')}
- Current Streak: $currentStreak days
- Completion Rate: ${(completionRate * 100).round()}%
- Known Dropout Pattern: $previouslyDroppedOff

BEHAVIORAL INSIGHTS:
- Identity Frame: "${profile.name} is someone who values their health and shows up for themselves"
- Loss Aversion Trigger: "A $currentStreak-day streak is at stake"
- Social Proof Opportunity: "Many others at your level follow this pattern"

COACHING PRINCIPLES:
1. Frame this as identity reinforcement, NOT obligation
2. Use "If-Then" implementation intentions
3. Acknowledge past patterns; show adaptation
4. Include fallback options for low-energy days
5. Emphasize streak maintenance

Generate a workout plan that includes:
- Main workout (45 min) - challenging but achievable
- Express option (20 min) - for low-energy days
- Recovery option (15 min) - for active rest
- Psychological framing for each
- Specific "why" tied to identity

Format as JSON:
{
  "main_workout": { "name": "...", "exercises": [...], "psychology": "..." },
  "express_option": { "name": "...", "exercises": [...], "psychology": "..." },
  "recovery_option": { "name": "...", "psychology": "..." },
  "coaching_message": "...",
  "completion_prediction": 0.85
}
''';
  }

  // Generate live performance coaching
  String generateLiveCoachingPrompt(
    Map<String, dynamic> currentSession,
    UserProfile profile,
  ) {
    final completedReps = currentSession['completed_reps'] as int? ?? 0;
    final targetReps = currentSession['target_reps'] as int? ?? 10;
    final exerciseName = currentSession['exercise_name'] as String? ?? 'exercise';
    final percentComplete = (completedReps / targetReps * 100).round();

    return '''
Generate a SHORT, powerful coaching message (max 15 words) for ${profile.name} during their workout.

CURRENT STATE:
- Exercise: $exerciseName
- Progress: $percentComplete% complete ($completedReps/$targetReps)
- Time elapsed: ${currentSession['elapsed_minutes'] ?? 5} minutes

COACHING MANDATE:
- Build on their identity as someone who "shows up"
- Create urgency ("finish strong")
- Use variable reward framing
- Be specific to current progress

Keep it SHORT and PUNCHY. Examples:
"You're 70% there. Three more reps proves you're serious."
"Champions finish what they start. Push through."
"Your future self is watching. Let's go!"

Generate message only (no JSON):
''';
  }

  // Generate adaptive meal plan with compliance psychology
  String generateAdaptiveMealPlanPrompt(
    UserProfile profile,
    Map<String, dynamic> adherenceHistory,
  ) {
    final pastCompliance = adherenceHistory['past_compliance_rate'] as double? ?? 0.6;
    final preferredMeals = adherenceHistory['preferred_meals'] as List<String>? ?? [];
    final busySchedule = adherenceHistory['availability_hours'] as int? ?? 2;

    return '''
Design a meal plan that prioritizes COMPLIANCE over perfection.

USER CONTEXT:
- Goal: ${profile.goals.join(', ')}
- Dietary Preferences: ${profile.availableEquipment.join(', ')}
- Past Compliance: ${(pastCompliance * 100).round()}%
- Available Time: $busySchedule hours/week for meal prep
- Preferred Meals: ${preferredMeals.join(', ')}

COMPLIANCE PSYCHOLOGY:
- If compliance is <60%: Reduce meal variety. Simple is better.
- If compliance is 60-80%: Balance simplicity with variety
- If compliance is >80%: Increase complexity and options

MEAL PLAN REQUIREMENTS:
1. Each meal takes <15 minutes to prepare
2. 80% overlap with foods they already like
3. Include prep day for batch cooking
4. "Fallback meals" for busy days (takeout options)
5. Specific quantities (not vague)
6. Shopping list provided

Psychology hooks:
- "If you prep Sunday, then meals are ready all week"
- "Simple meals you'll actually follow beat perfect meals you won't"
- "You've kept a streak for X days—don't break it"

Format as JSON with meal_plan, prep_strategy, fallback_meals
''';
  }

  // Generate recovery/failure prompts
  String generateRecoveryPrompt(
    String failureReason,
    UserProfile profile,
    int streakDays,
  ) {
    return '''
${profile.name} missed their workout today. Reason: $failureReason
Streak lost: $streakDays days

Generate a RECOVERY message that:
1. Validates the reason (no shame)
2. Reframes identity ("You're still someone who tries")
3. Creates micro-commitment for tomorrow
4. Uses loss aversion ("Let's not let this become a pattern")
5. Provides specific action for the next 24 hours

CONSTRAINTS:
- Warm and human, not robotic
- Acknowledge the reality (don't minimize)
- Focus on the NEXT action, not the miss
- Specific time recommendation for tomorrow
- Keep under 150 words

Example tone: "Life happens. Here's what matters now..."

Generate message only:
''';
  }

  // Generate progressive overload recommendations
  String generateProgressiveOverloadPrompt(
    UserProfile profile,
    List<Map<String, dynamic>> workoutHistory,
  ) {
    final recentWorkouts = workoutHistory.take(5).toList();
    final averageCompletion = recentWorkouts.isEmpty
        ? 0.0
        : recentWorkouts
                .map((w) => w['completion_rate'] as double? ?? 0.0)
                .reduce((a, b) => a + b) /
            recentWorkouts.length;

    return '''
Design a progressive workout adjustment for ${profile.name}.

RECENT PERFORMANCE:
- Last 5 workouts completion rate: ${(averageCompletion * 100).round()}%
- Fitness level: ${profile.fitnessLevel}
- Goals: ${profile.goals.join(', ')}

PROGRESSIVE OVERLOAD PRINCIPLES:
- If completion rate >90%: Increase difficulty by 10-15%
- If completion rate 70-90%: Maintain current level, add variety
- If completion rate <70%: Reduce difficulty, focus on consistency

ADJUSTMENT OPTIONS:
1. Increase reps/sets
2. Decrease rest time
3. Add weight/resistance
4. Increase workout frequency
5. Add new exercises

Provide specific recommendations with psychological framing to maintain motivation.

Format as JSON with adjustments, reasoning, motivation_message
''';
  }

  // Generate habit formation check-in prompts
  String generateHabitCheckInPrompt(
    UserProfile profile,
    int daysSinceStart,
    Map<String, dynamic> completionData,
  ) {
    final completionRate = completionData['completion_rate'] as double? ?? 0.0;
    final consecutiveDays = completionData['consecutive_days'] as int? ?? 0;

    String habitPhase;
    if (daysSinceStart <= 21) {
      habitPhase = 'Friction Phase (Days 1-21): Building the habit';
    } else if (daysSinceStart <= 66) {
      habitPhase = 'Automation Phase (Days 22-66): Making it automatic';
    } else {
      habitPhase = 'Identity Phase (Days 66+): It\'s who you are';
    }

    return '''
Generate a habit formation check-in message for ${profile.name}.

HABIT JOURNEY:
- Days since start: $daysSinceStart
- Current phase: $habitPhase
- Completion rate: ${(completionRate * 100).round()}%
- Consecutive days: $consecutiveDays

PHASE-SPECIFIC COACHING:
- Days 1-21: Focus on consistency, not perfection. Celebrate small wins.
- Days 22-66: Build identity. "You're someone who exercises."
- Days 66+: Maintain identity. Reference past achievements.

Generate a motivational check-in that:
1. Acknowledges their progress in this phase
2. Provides phase-appropriate encouragement
3. Sets expectation for next milestone
4. Reinforces identity over outcome

Keep under 100 words. Be warm and specific.
''';
  }

  // Generate barrier identification prompts
  String generateBarrierIdentificationPrompt(
    UserProfile profile,
    List<String> missedDays,
    Map<String, dynamic> patterns,
  ) {
    final commonMissDay = patterns['most_missed_day'] as String? ?? 'Unknown';
    final commonMissTime = patterns['most_missed_time'] as String? ?? 'Unknown';
    final commonReason = patterns['common_reason'] as String? ?? 'Not specified';

    return '''
Analyze barriers for ${profile.name} and provide solutions.

IDENTIFIED PATTERNS:
- Most missed day: $commonMissDay
- Most missed time: $commonMissTime
- Common reason: $commonReason
- Recent misses: ${missedDays.join(', ')}

Generate barrier-specific solutions using:
1. Implementation intentions ("If X, then Y")
2. Environment design (make it easier)
3. Social commitment (accountability)
4. Habit stacking (anchor to existing habits)

For each barrier, provide:
- Root cause analysis
- 2-3 specific solutions
- Example implementation intention

Format as JSON with barriers array containing: barrier, root_cause, solutions
''';
  }

  // Generate celebration and reinforcement messages
  String generateCelebrationPrompt(
    UserProfile profile,
    String achievement,
    Map<String, dynamic> context,
  ) {
    return '''
Generate a celebration message for ${profile.name} who just achieved: $achievement

CONTEXT:
- Current streak: ${context['current_streak'] ?? 0} days
- Total workouts: ${context['total_workouts'] ?? 0}
- Consistency rate: ${context['consistency_rate'] ?? 0}%

CELEBRATION PRINCIPLES:
1. Specific praise (reference the actual achievement)
2. Identity reinforcement ("This is who you are")
3. Forward momentum ("What's next?")
4. Social shareability (make them want to share)

Generate a message that:
- Celebrates the specific achievement
- Connects it to their identity
- Hints at the next milestone
- Makes them feel proud

Keep under 75 words. Be genuine and energetic.
''';
  }
}
