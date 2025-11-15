# AI Fitness Planner - Habit Formation Engine

## Overview

This comprehensive habit formation system integrates psychology-backed features to help users build sustainable fitness habits. The implementation includes streak tracking, achievement badges, behavioral AI coaching, and intelligent notification scheduling.

## Features Implemented

### Phase 1: Enhanced Database Schema ✅

**File:** `lib/services/database_helper_enhanced.dart`

New database tables added:
- `habit_streaks` - Track current and longest streaks for each habit type
- `daily_habits` - Log daily habit completions and mood/energy levels
- `achievements` - Store earned badges and achievements
- `notifications_log` - Track notification delivery and engagement
- `performance_analytics` - Store user performance metrics over time
- `social_connections` - Support for future social features
- `group_challenges` - Support for group challenges
- `challenge_participants` - Track challenge participation

**Key Operations:**
```dart
// Initialize streaks for a new user
await dbHelper.initializeStreaks(userId);

// Update streak on habit completion
await dbHelper.updateStreakOnCompletion(userId, 'exercise');

// Log daily habits
await dbHelper.logDailyHabit(userId, {
  'exercise_completed': 1,
  'meal_logged': 1,
  'water_goal_met': 1,
  'mood_rating': 4,
  'energy_level': 3,
});

// Award achievements
await dbHelper.awardAchievement(
  userId,
  'week_warrior',
  'Week Warrior',
  'Completed 7 consecutive days!',
);
```

### Phase 2: Habit Formation Engine ✅

**File:** `lib/engines/habit_formation_engine.dart`

Implements core psychology principles:

1. **Streak Tracking**
   - Current streak calculation
   - Longest streak recording
   - Automatic reset on missed days

2. **Badge Achievement System**
   - First workout badge
   - 7-day streak badge (Week Warrior)
   - 30-day streak badge (Month Master)
   - 100-day streak badge (Year Champion)

3. **Psychological Messaging**
   - Identity-based coaching
   - Loss aversion framing
   - Variable reward schedules
   - Implementation intentions

4. **Motivation Scaling**
   - Adapts based on current streak
   - Ranges from 0.0 (low) to 1.0 (high)

**Usage Example:**
```dart
final habitEngine = HabitFormationEngine(userId: userId);

// Record workout completion
await habitEngine.recordWorkoutCompletion();

// Get personalized motivation
final message = await habitEngine.generatePersonalizedMotivation();

// Check for new badges
final badges = await habitEngine.checkBadgeAchievements();

// Get weekly reflection
final reflection = await habitEngine.generateWeeklyReflection();

// Get motivational stats
final stats = await habitEngine.getMotivationalStats();
```

### Phase 3: Behavioral AI Coaching Engine ✅

**File:** `lib/engines/behavioral_coaching_engine.dart`

Generates psychology-informed prompts for AI integration:

1. **Workout Plan Generation**
   - Main workout (45 min)
   - Express option (20 min)
   - Recovery option (15 min)
   - Psychology framing for each

2. **Live Coaching**
   - Real-time encouragement during workouts
   - Progress-specific messaging
   - Identity reinforcement

3. **Adaptive Meal Planning**
   - Compliance-focused approach
   - Simplicity-variety balance
   - Fallback options

4. **Recovery Messaging**
   - Validates missed workouts
   - Reframes identity
   - Creates micro-commitments

**Usage Example:**
```dart
final coachingEngine = BehavioralCoachingEngine();

// Generate workout plan prompt for AI
final workoutPrompt = coachingEngine.generateWorkoutPlanPrompt(
  userProfile,
  performanceHistory,
);

// Generate live coaching message
final liveCoaching = coachingEngine.generateLiveCoachingPrompt(
  currentSession,
  userProfile,
);

// Generate recovery message
final recoveryMessage = coachingEngine.generateRecoveryPrompt(
  'Too busy at work',
  userProfile,
  streakDays,
);
```

### Phase 4: Notification Scheduler Service ✅

**File:** `lib/services/notification_scheduler_service.dart`

Intelligent notification system:

1. **Optimal Timing**
   - Respects quiet hours (10 PM - 7 AM)
   - Minimum 4-hour spacing
   - Maximum 3 notifications per day

2. **Smart Messaging**
   - Time-based notifications
   - Progress-based notifications
   - Streak maintenance alerts
   - Recovery day reminders

3. **Engagement Tracking**
   - Logs notification delivery
   - Tracks open rates
   - Calculates performance metrics
   - Learns user preferences

4. **Adaptive Scheduling**
   - Determines best notification type
   - Analyzes user patterns
   - Recommends optimal times

**Usage Example:**
```dart
final notificationService = NotificationSchedulerService(userId: userId);

// Schedule optimal notification
final notification = await notificationService.scheduleOptimalNotification();

// Track engagement
await notificationService.trackNotificationEngagement(
  notificationId,
  wasOpened: true,
);

// Get performance metrics
final performance = await notificationService.getNotificationPerformance();

// Clean up old notifications
await notificationService.clearOldNotifications(daysToKeep: 30);
```

### UI Components ✅

**Files:**
- `lib/widgets/streak_display_widget.dart` - Display habit streaks
- `lib/widgets/achievements_widget.dart` - Show earned badges
- `lib/widgets/habit_tracker_widget.dart` - Daily habit checklist
- `lib/screens/EnhancedDashboardPage.dart` - Enhanced dashboard

**Features:**
- Real-time streak updates
- Visual achievement gallery
- Weekly progress calendar
- Motivational messaging
- Interactive habit completion
- Badge unlock celebrations

**Usage Example:**
```dart
// Enhanced Dashboard
EnhancedDashboardPage(userId: userId)

// Individual Widgets
StreakDisplayWidget(
  currentStreak: 7,
  longestStreak: 14,
  habitType: 'exercise',
)

AchievementsWidget(achievements: achievementsList)

HabitTrackerWidget(
  weeklyHabits: weeklyHabitsList,
  onHabitComplete: (habitType) async {
    // Handle habit completion
  },
)
```

## Psychology Principles Implemented

### 1. Identity-Based Habits
- Frames actions as identity reinforcement
- "You're someone who exercises" vs "You should exercise"
- Messages emphasize who the user is becoming

### 2. Loss Aversion
- Highlights what users stand to lose (streaks)
- Creates urgency around maintaining progress
- "Don't break your X-day streak" messaging

### 3. Variable Reward Schedules
- 60% predictable praise
- 30% special achievements
- 10% surprise bonuses
- Keeps users engaged and motivated

### 4. Implementation Intentions
- "If-Then" planning statements
- Specific time-based triggers
- Reduces decision fatigue

### 5. Habit Phases
- Days 1-21: Friction Phase (building the habit)
- Days 22-66: Automation Phase (making it automatic)
- Days 66+: Identity Phase (it's who you are)

## Testing

Comprehensive test suites included:

**Files:**
- `test/habit_formation_engine_test.dart`
- `test/notification_scheduler_test.dart`

**Test Coverage:**
- Streak tracking logic
- Badge award triggers
- Motivation scaling
- Message generation
- Notification timing
- Database operations
- Performance analytics

**Run Tests:**
```bash
flutter test
```

## Database Migration

The enhanced database schema includes migration support:

- **Version 1**: Original schema (user_profile, progress_entries)
- **Version 2**: Enhanced schema with habit tracking tables

Migration happens automatically on app startup. Existing data is preserved.

## Integration Guide

### 1. Initialize User Streaks
```dart
final dbHelper = DatabaseHelper.instance;
await dbHelper.initializeStreaks(userId);
```

### 2. Record Daily Habits
```dart
final habitEngine = HabitFormationEngine(userId: userId);
await habitEngine.recordWorkoutCompletion();
```

### 3. Display Enhanced Dashboard
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EnhancedDashboardPage(userId: userId),
  ),
);
```

### 4. Schedule Notifications
```dart
final notificationService = NotificationSchedulerService(userId: userId);
final notification = await notificationService.scheduleOptimalNotification();

// Use notification data with your notification plugin
await FlutterLocalNotifications.show(
  notification['title'],
  notification['body'],
  scheduledTime,
);
```

## Performance Considerations

1. **Database Indexing**: Add indexes on frequently queried columns
2. **Batch Operations**: Use transactions for multiple database operations
3. **Caching**: Cache user profile and streak data to reduce database calls
4. **Lazy Loading**: Load achievements and analytics on demand

## Future Enhancements

1. **Social Features**
   - Connect with friends
   - Share achievements
   - Group challenges

2. **Advanced Analytics**
   - Predictive modeling for dropoff risk
   - Personalized difficulty adjustment
   - Pattern recognition

3. **Gamification**
   - Leaderboards
   - Seasonal challenges
   - Rare achievement hunting

4. **AI Integration**
   - Real-time form correction
   - Adaptive workout generation
   - Nutrition optimization

## License

This implementation follows the MIT License of the parent project.

## Support

For issues or questions:
1. Check the test files for usage examples
2. Review the inline documentation
3. Open an issue on the project repository

---

**Status:** Production Ready ✅
**Version:** 2.0.0
**Last Updated:** 2025-11-15
