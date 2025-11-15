import 'package:flutter/material.dart';

class HabitTrackerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyHabits;
  final Function(String habitType) onHabitComplete;

  const HabitTrackerWidget({
    Key? key,
    required this.weeklyHabits,
    required this.onHabitComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todayHabits = _getTodayHabits();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Habits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildHabitCheckbox(
              context,
              '💪 Complete Workout',
              todayHabits['exercise_completed'] == 1,
              'exercise',
            ),
            SizedBox(height: 12),
            _buildHabitCheckbox(
              context,
              '🥗 Log Meals',
              todayHabits['meal_logged'] == 1,
              'meal_logging',
            ),
            SizedBox(height: 12),
            _buildHabitCheckbox(
              context,
              '💧 Drink Water Goal',
              todayHabits['water_goal_met'] == 1,
              'water',
            ),
            SizedBox(height: 16),
            _buildWeeklyProgress(),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTodayHabits() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (var habit in weeklyHabits) {
      final habitDate = habit['date'] as String;
      if (habitDate.startsWith(todayString)) {
        return habit;
      }
    }

    return {
      'exercise_completed': 0,
      'meal_logged': 0,
      'water_goal_met': 0,
    };
  }

  Widget _buildHabitCheckbox(
    BuildContext context,
    String label,
    bool isCompleted,
    String habitType,
  ) {
    return InkWell(
      onTap: isCompleted ? null : () => onHabitComplete(habitType),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey[400],
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? Colors.green[800] : Colors.black87,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final currentWeekday = today.weekday - 1; // 0-indexed

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final isToday = index == currentWeekday;
            final dayData = _getDayData(index);
            final isCompleted = dayData['exercise_completed'] == 1;

            return Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : isToday
                            ? Colors.blue[100]
                            : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: isToday
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            weekDays[index].substring(0, 1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.blue : Colors.grey[600],
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  weekDays[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Map<String, dynamic> _getDayData(int dayIndex) {
    final today = DateTime.now();
    final targetDate = today.subtract(Duration(days: today.weekday - 1 - dayIndex));
    final targetDateString = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    for (var habit in weeklyHabits) {
      final habitDate = habit['date'] as String;
      if (habitDate.startsWith(targetDateString)) {
        return habit;
      }
    }

    return {
      'exercise_completed': 0,
      'meal_logged': 0,
      'water_goal_met': 0,
    };
  }
}
