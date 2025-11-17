import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DailyHabitsCard extends StatelessWidget {
  final bool exerciseCompleted;
  final bool mealLogged;
  final bool waterGoalMet;
  final Function(String) onHabitTap;
  final List<bool> weekProgress;

  const DailyHabitsCard({
    Key? key,
    required this.exerciseCompleted,
    required this.mealLogged,
    required this.waterGoalMet,
    required this.onHabitTap,
    this.weekProgress = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completionCount = [exerciseCompleted, mealLogged, waterGoalMet]
        .where((completed) => completed)
        .length;
    final completionRate = completionCount / 3;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          Container(
            padding: EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spaceSM),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        borderRadius: AppTheme.smallRadius,
                      ),
                      child: Icon(
                        Icons.today,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Habits',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: AppTheme.spaceXS),
                          Text(
                            '$completionCount of 3 completed',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _buildCompletionBadge(context, completionRate),
                  ],
                ),
                SizedBox(height: AppTheme.spaceMD),
                _buildProgressBar(completionRate),
              ],
            ),
          ),

          // Habit List
          Padding(
            padding: EdgeInsets.all(AppTheme.spaceMD),
            child: Column(
              children: [
                _HabitCheckItem(
                  icon: '💪',
                  label: 'Complete Workout',
                  subtitle: 'Keep your streak alive',
                  isCompleted: exerciseCompleted,
                  color: AppTheme.accentOrange,
                  onTap: () => onHabitTap('exercise'),
                ),
                SizedBox(height: AppTheme.spaceMD),
                _HabitCheckItem(
                  icon: '🥗',
                  label: 'Log Your Meals',
                  subtitle: 'Track your nutrition',
                  isCompleted: mealLogged,
                  color: AppTheme.success,
                  onTap: () => onHabitTap('meal_logging'),
                ),
                SizedBox(height: AppTheme.spaceMD),
                _HabitCheckItem(
                  icon: '💧',
                  label: 'Drink Water Goal',
                  subtitle: 'Stay hydrated',
                  isCompleted: waterGoalMet,
                  color: AppTheme.accentBlue,
                  onTap: () => onHabitTap('water'),
                ),
              ],
            ),
          ),

          // Week Progress
          if (weekProgress.isNotEmpty) ...[
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(AppTheme.spaceMD),
              child: _buildWeekProgress(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionBadge(BuildContext context, double rate) {
    String emoji;
    String text;
    Color color;

    if (rate == 1.0) {
      emoji = '🎉';
      text = 'Perfect!';
      color = AppTheme.success;
    } else if (rate >= 0.66) {
      emoji = '👍';
      text = 'Good';
      color = AppTheme.accentOrange;
    } else if (rate > 0) {
      emoji = '💪';
      text = 'Going';
      color = AppTheme.accentBlue;
    } else {
      emoji = '🚀';
      text = 'Start';
      color = AppTheme.textGrey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceSM,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: AppTheme.largeRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: AppTheme.spaceXS),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return ClipRRect(
          borderRadius: AppTheme.smallRadius,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppTheme.textGrey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              value == 1.0 ? AppTheme.success : AppTheme.primaryPurple,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekProgress(BuildContext context) {
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: AppTheme.spaceMD),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final isCompleted = index < weekProgress.length && weekProgress[index];
            final isToday = index == today;

            return _WeekDayIndicator(
              day: weekDays[index],
              isCompleted: isCompleted,
              isToday: isToday,
              index: index,
            );
          }),
        ),
      ],
    );
  }
}

class _HabitCheckItem extends StatefulWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  const _HabitCheckItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isCompleted,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_HabitCheckItem> createState() => _HabitCheckItemState();
}

class _HabitCheckItemState extends State<_HabitCheckItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isCompleted) {
      _controller.forward().then((_) => _controller.reverse());
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: AppTheme.mediumRadius,
        child: Container(
          padding: EdgeInsets.all(AppTheme.spaceMD),
          decoration: BoxDecoration(
            gradient: widget.isCompleted
                ? LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.1),
                      widget.color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isCompleted ? null : Theme.of(context).cardColor,
            borderRadius: AppTheme.mediumRadius,
            border: Border.all(
              color: widget.isCompleted
                  ? widget.color.withOpacity(0.5)
                  : AppTheme.textGrey.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  borderRadius: AppTheme.smallRadius,
                ),
                child: Center(
                  child: Text(
                    widget.icon,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spaceMD),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: widget.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    SizedBox(height: AppTheme.spaceXS),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Checkbox
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isCompleted ? widget.color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color,
                    width: 2,
                  ),
                ),
                child: widget.isCompleted
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekDayIndicator extends StatefulWidget {
  final String day;
  final bool isCompleted;
  final bool isToday;
  final int index;

  const _WeekDayIndicator({
    Key? key,
    required this.day,
    required this.isCompleted,
    required this.isToday,
    required this.index,
  }) : super(key: key);

  @override
  State<_WeekDayIndicator> createState() => _WeekDayIndicatorState();
}

class _WeekDayIndicatorState extends State<_WeekDayIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.1,
          0.5 + (widget.index * 0.1),
          curve: Curves.elasticOut,
        ),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: widget.isCompleted
                  ? AppTheme.successGradient
                  : null,
              color: widget.isCompleted
                  ? null
                  : widget.isToday
                      ? AppTheme.primaryPurple.withOpacity(0.2)
                      : AppTheme.textGrey.withOpacity(0.1),
              shape: BoxShape.circle,
              border: widget.isToday
                  ? Border.all(color: AppTheme.primaryPurple, width: 2)
                  : null,
            ),
            child: Center(
              child: widget.isCompleted
                  ? Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      widget.day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isToday
                            ? AppTheme.primaryPurple
                            : AppTheme.textGrey,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
