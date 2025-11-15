import 'package:flutter/material.dart';
import '../services/database_helper_enhanced.dart';
import '../engines/habit_formation_engine.dart';
import '../widgets/streak_display_widget.dart';
import '../widgets/achievements_widget.dart';
import '../widgets/habit_tracker_widget.dart';

class EnhancedDashboardPage extends StatefulWidget {
  final int userId;

  const EnhancedDashboardPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _EnhancedDashboardPageState createState() => _EnhancedDashboardPageState();
}

class _EnhancedDashboardPageState extends State<EnhancedDashboardPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late HabitFormationEngine _habitEngine;

  Map<String, Map<String, dynamic>> _streaks = {};
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _weeklyHabits = [];
  Map<String, dynamic> _motivationalStats = {};
  String _motivationMessage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _habitEngine = HabitFormationEngine(userId: widget.userId);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load all dashboard data in parallel
      final results = await Future.wait([
        _habitEngine.getAllStreaks(),
        _dbHelper.getUserAchievements(widget.userId),
        _dbHelper.getWeeklyHabits(widget.userId),
        _habitEngine.getMotivationalStats(),
        _habitEngine.generatePersonalizedMotivation(),
      ]);

      setState(() {
        _streaks = results[0] as Map<String, Map<String, dynamic>>;
        _achievements = results[1] as List<Map<String, dynamic>>;
        _weeklyHabits = results[2] as List<Map<String, dynamic>>;
        _motivationalStats = results[3] as Map<String, dynamic>;
        _motivationMessage = results[4] as String;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleHabitCompletion(String habitType) async {
    try {
      if (habitType == 'exercise') {
        await _habitEngine.recordWorkoutCompletion();
      } else {
        await _dbHelper.updateStreakOnCompletion(widget.userId, habitType);
        await _dbHelper.logDailyHabit(widget.userId, {
          'exercise_completed': 0,
          'meal_logged': habitType == 'meal_logging' ? 1 : 0,
          'water_goal_met': habitType == 'water' ? 1 : 0,
        });
      }

      // Check for new badges
      final newBadges = await _habitEngine.checkBadgeAchievements();
      if (newBadges.isNotEmpty) {
        _showBadgeAwardedDialog(newBadges);
      }

      // Reload dashboard data
      await _loadDashboardData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Great job! Habit completed 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error completing habit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing habit'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBadgeAwardedDialog(List<String> badges) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('🎉 '),
            Text('Achievement Unlocked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'You\'ve earned ${badges.length} new badge${badges.length > 1 ? 's' : ''}!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              SizedBox(height: 20),
              _buildMotivationCard(),
              SizedBox(height: 20),
              _buildStatsOverview(),
              SizedBox(height: 20),
              HabitTrackerWidget(
                weeklyHabits: _weeklyHabits,
                onHabitComplete: _handleHabitCompletion,
              ),
              SizedBox(height: 20),
              _buildStreaksSection(),
              SizedBox(height: 20),
              AchievementsWidget(achievements: _achievements),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.waving_hand, size: 32, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Let\'s make today count',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Card(
      elevation: 4,
      color: Colors.purple[50],
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb,
                color: Colors.purple[700],
                size: 28,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _motivationMessage,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.purple[900],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Workouts',
                  '${_motivationalStats['total_workouts'] ?? 0}',
                  Icons.fitness_center,
                  Colors.blue,
                ),
                _buildStatItem(
                  'This Week',
                  '${_motivationalStats['weekly_completion'] ?? 0}/7',
                  Icons.calendar_today,
                  Colors.green,
                ),
                _buildStatItem(
                  'Badges',
                  '${_motivationalStats['total_badges'] ?? 0}',
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStreaksSection() {
    if (_streaks.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Your Streaks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 12),
        ..._streaks.entries.map((entry) {
          final habitType = entry.key;
          final streakData = entry.value;
          return StreakDisplayWidget(
            currentStreak: streakData['current_streak'] as int? ?? 0,
            longestStreak: streakData['longest_streak'] as int? ?? 0,
            habitType: habitType,
          );
        }).toList(),
      ],
    );
  }
}
