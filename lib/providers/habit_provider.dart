import 'package:flutter/foundation.dart';
import '../services/database_helper_enhanced.dart';
import '../engines/habit_formation_engine.dart';
import '../engines/behavioral_coaching_engine.dart';
import '../services/notification_scheduler_service.dart';

enum LoadingState {
  initial,
  loading,
  loaded,
  error,
}

class HabitProvider extends ChangeNotifier {
  final int userId;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late HabitFormationEngine _habitEngine;
  late BehavioralCoachingEngine _coachingEngine;
  late NotificationSchedulerService _notificationService;

  // State
  LoadingState _loadingState = LoadingState.initial;
  String? _errorMessage;

  // Data
  Map<String, Map<String, dynamic>> _streaks = {};
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _weeklyHabits = [];
  Map<String, dynamic> _motivationalStats = {};
  String _motivationMessage = '';
  Map<String, dynamic>? _todayHabits;

  // Getters
  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  Map<String, Map<String, dynamic>> get streaks => _streaks;
  List<Map<String, dynamic>> get achievements => _achievements;
  List<Map<String, dynamic>> get weeklyHabits => _weeklyHabits;
  Map<String, dynamic> get motivationalStats => _motivationalStats;
  String get motivationMessage => _motivationMessage;
  Map<String, dynamic>? get todayHabits => _todayHabits;

  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isLoaded => _loadingState == LoadingState.loaded;

  HabitProvider({required this.userId}) {
    _habitEngine = HabitFormationEngine(userId: userId);
    _coachingEngine = BehavioralCoachingEngine();
    _notificationService = NotificationSchedulerService(userId: userId);
    initialize();
  }

  Future<void> initialize() async {
    try {
      _setLoadingState(LoadingState.loading);

      // Check if user has streaks initialized
      final exerciseStreak = await _dbHelper.getStreakData(userId, 'exercise');
      if (exerciseStreak == null) {
        await _dbHelper.initializeStreaks(userId);
      }

      await loadAllData();
      _setLoadingState(LoadingState.loaded);
    } catch (e) {
      _handleError('Failed to initialize: $e');
    }
  }

  Future<void> loadAllData() async {
    try {
      final results = await Future.wait([
        _habitEngine.getAllStreaks(),
        _dbHelper.getUserAchievements(userId),
        _dbHelper.getWeeklyHabits(userId),
        _habitEngine.getMotivationalStats(),
        _habitEngine.generatePersonalizedMotivation(),
      ]);

      _streaks = results[0] as Map<String, Map<String, dynamic>>;
      _achievements = results[1] as List<Map<String, dynamic>>;
      _weeklyHabits = results[2] as List<Map<String, dynamic>>;
      _motivationalStats = results[3] as Map<String, dynamic>;
      _motivationMessage = results[4] as String;

      _loadTodayHabits();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  void _loadTodayHabits() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (var habit in _weeklyHabits) {
      final habitDate = habit['date'] as String;
      if (habitDate.startsWith(todayString)) {
        _todayHabits = habit;
        return;
      }
    }

    _todayHabits = {
      'exercise_completed': 0,
      'meal_logged': 0,
      'water_goal_met': 0,
    };
  }

  Future<void> refresh() async {
    try {
      _setLoadingState(LoadingState.loading);
      await loadAllData();
      _setLoadingState(LoadingState.loaded);
    } catch (e) {
      _handleError('Failed to refresh: $e');
    }
  }

  Future<List<String>> completeHabit(String habitType) async {
    try {
      List<String> newBadges = [];

      if (habitType == 'exercise') {
        await _habitEngine.recordWorkoutCompletion();
      } else {
        await _dbHelper.updateStreakOnCompletion(userId, habitType);
        await _dbHelper.logDailyHabit(userId, {
          'exercise_completed': 0,
          'meal_logged': habitType == 'meal_logging' ? 1 : 0,
          'water_goal_met': habitType == 'water' ? 1 : 0,
        });
      }

      // Check for new badges
      newBadges = await _habitEngine.checkBadgeAchievements();

      // Reload data
      await loadAllData();

      return newBadges;
    } catch (e) {
      _handleError('Failed to complete habit: $e');
      return [];
    }
  }

  Future<void> scheduleNextNotification() async {
    try {
      await _notificationService.scheduleOptimalNotification();
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  Future<Map<String, dynamic>> getWeeklyReflection() async {
    try {
      return await _habitEngine.generateWeeklyReflection();
    } catch (e) {
      _handleError('Failed to get weekly reflection: $e');
      return {};
    }
  }

  Future<bool> isAtRisk() async {
    try {
      return await _habitEngine.isAtDropoffRisk();
    } catch (e) {
      return false;
    }
  }

  Future<String> getLossAversionMessage() async {
    try {
      return await _habitEngine.generateLossAversionMessage();
    } catch (e) {
      return 'Keep up the great work!';
    }
  }

  Future<String> getIdentityMessage() async {
    try {
      return await _habitEngine.generateIdentityMessage();
    } catch (e) {
      return 'You\'re building a healthy lifestyle!';
    }
  }

  int getCurrentStreak(String habitType) {
    if (_streaks.containsKey(habitType)) {
      return _streaks[habitType]!['current_streak'] as int? ?? 0;
    }
    return 0;
  }

  int getLongestStreak(String habitType) {
    if (_streaks.containsKey(habitType)) {
      return _streaks[habitType]!['longest_streak'] as int? ?? 0;
    }
    return 0;
  }

  int getTotalCompletions(String habitType) {
    if (_streaks.containsKey(habitType)) {
      return _streaks[habitType]!['total_completions'] as int? ?? 0;
    }
    return 0;
  }

  bool isHabitCompletedToday(String habitType) {
    if (_todayHabits == null) return false;

    switch (habitType) {
      case 'exercise':
        return (_todayHabits!['exercise_completed'] as int? ?? 0) == 1;
      case 'meal_logging':
        return (_todayHabits!['meal_logged'] as int? ?? 0) == 1;
      case 'water':
        return (_todayHabits!['water_goal_met'] as int? ?? 0) == 1;
      default:
        return false;
    }
  }

  int getWeeklyCompletionCount() {
    return _weeklyHabits
        .where((h) => h['exercise_completed'] == 1)
        .length;
  }

  double getWeeklyCompletionRate() {
    final completed = getWeeklyCompletionCount();
    return completed / 7.0;
  }

  List<Map<String, dynamic>> getRecentAchievements({int limit = 5}) {
    return _achievements.take(limit).toList();
  }

  void _setLoadingState(LoadingState state) {
    _loadingState = state;
    if (state != LoadingState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _handleError(String message) {
    _errorMessage = message;
    _loadingState = LoadingState.error;
    notifyListeners();
    debugPrint('HabitProvider Error: $message');
  }

  void clearError() {
    _errorMessage = null;
    if (_loadingState == LoadingState.error) {
      _loadingState = LoadingState.loaded;
    }
    notifyListeners();
  }
}
