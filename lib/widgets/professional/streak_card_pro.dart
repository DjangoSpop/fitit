import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StreakCardPro extends StatefulWidget {
  final int currentStreak;
  final int longestStreak;
  final String habitType;
  final VoidCallback? onTap;

  const StreakCardPro({
    Key? key,
    required this.currentStreak,
    required this.longestStreak,
    required this.habitType,
    this.onTap,
  }) : super(key: key);

  @override
  State<StreakCardPro> createState() => _StreakCardProState();
}

class _StreakCardProState extends State<StreakCardPro>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  Color _getStreakColor() {
    if (widget.currentStreak >= 30) return AppTheme.success;
    if (widget.currentStreak >= 14) return AppTheme.accentOrange;
    if (widget.currentStreak >= 7) return AppTheme.accentYellow;
    return AppTheme.accentBlue;
  }

  LinearGradient _getGradient() {
    if (widget.currentStreak >= 30) return AppTheme.successGradient;
    if (widget.currentStreak >= 14) return AppTheme.energyGradient;
    if (widget.currentStreak >= 7) return AppTheme.energyGradient;
    return AppTheme.calmGradient;
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: AppTheme.spaceSM,
              horizontal: AppTheme.spaceXS,
            ),
            decoration: BoxDecoration(
              gradient: _getGradient(),
              borderRadius: AppTheme.largeRadius,
              boxShadow: AppTheme.mediumShadow,
            ),
            child: Container(
              padding: EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.95),
                borderRadius: AppTheme.largeRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _getGradient(),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getHabitIcon(widget.habitType),
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getHabitLabel(widget.habitType),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: AppTheme.spaceXS),
                            Text(
                              'Keep the momentum!',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (widget.currentStreak >= 7)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(seconds: 1),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.4 * value),
                              child: Text(
                                '🔥',
                                style: TextStyle(fontSize: 32),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

                  SizedBox(height: AppTheme.spaceLG),

                  // Streak Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStreakStat(
                          context,
                          'Current',
                          widget.currentStreak.toString(),
                          'days',
                          _getStreakColor(),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.textGrey.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildStreakStat(
                          context,
                          'Best',
                          widget.longestStreak.toString(),
                          'days',
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),

                  // Fire message for streaks >= 7
                  if (widget.currentStreak >= 7) ...[
                    SizedBox(height: AppTheme.spaceMD),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spaceMD),
                      decoration: BoxDecoration(
                        gradient: _getGradient().scale(0.3),
                        borderRadius: AppTheme.mediumRadius,
                      ),
                      child: Row(
                        children: [
                          Text('🔥', style: TextStyle(fontSize: 24)),
                          SizedBox(width: AppTheme.spaceSM),
                          Expanded(
                            child: Text(
                              _getStreakMessage(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
          ),
        ),
      ),
    );
  }

  Widget _buildStreakStat(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: int.parse(value)),
          duration: Duration(milliseconds: 1000),
          builder: (context, animatedValue, child) {
            return Text(
              animatedValue.toString(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1.0,
              ),
            );
          },
        ),
        SizedBox(height: AppTheme.spaceXS),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.7),
              ),
        ),
        SizedBox(height: AppTheme.spaceXS),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getStreakMessage() {
    if (widget.currentStreak >= 100) {
      return 'LEGENDARY! ${widget.currentStreak} days of pure dedication!';
    } else if (widget.currentStreak >= 30) {
      return 'Amazing! ${widget.currentStreak} days strong!';
    } else if (widget.currentStreak >= 14) {
      return 'Two weeks in! You\'re unstoppable!';
    } else {
      return '${widget.currentStreak} days! You\'re on fire!';
    }
  }
}
