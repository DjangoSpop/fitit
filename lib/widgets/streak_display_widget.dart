import 'package:flutter/material.dart';

class StreakDisplayWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final String habitType;

  const StreakDisplayWidget({
    Key? key,
    required this.currentStreak,
    required this.longestStreak,
    required this.habitType,
  }) : super(key: key);

  String _getHabitIcon(String type) {
    switch (type) {
      case 'exercise':
        return '💪';
      case 'meal_logging':
        return '🥗';
      case 'weight_tracking':
        return '⚖️';
      default:
        return '✨';
    }
  }

  String _getHabitLabel(String type) {
    switch (type) {
      case 'exercise':
        return 'Workout Streak';
      case 'meal_logging':
        return 'Meal Log Streak';
      case 'weight_tracking':
        return 'Weight Tracking';
      default:
        return 'Habit Streak';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getHabitIcon(habitType),
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getHabitLabel(habitType),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Keep the momentum going!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakStat(
                  context,
                  'Current',
                  currentStreak.toString(),
                  currentStreak >= 7 ? Colors.orange : Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStreakStat(
                  context,
                  'Best',
                  longestStreak.toString(),
                  Colors.purple,
                ),
              ],
            ),
            if (currentStreak >= 7) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'re on fire! $currentStreak days strong!',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
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
        ),
      ],
    );
  }
}
