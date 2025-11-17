import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dart:math' as math;

class AchievementShowcase extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;
  final VoidCallback? onViewAll;

  const AchievementShowcase({
    Key? key,
    required this.achievements,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppTheme.spaceMD),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spaceSM),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.mediumRadius,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${achievements.length} earned',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: Text('View All'),
                  ),
              ],
            ),
          ),

          Divider(height: 1),

          // Achievement Grid
          Container(
            height: 280,
            padding: EdgeInsets.all(AppTheme.spaceMD),
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: AppTheme.spaceMD,
                mainAxisSpacing: AppTheme.spaceMD,
              ),
              itemCount: math.min(achievements.length, 6),
              itemBuilder: (context, index) {
                return _AchievementCard(
                  achievement: achievements[index],
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(AppTheme.space2XL),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.textGrey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 60,
                  color: AppTheme.textGrey.withOpacity(0.4),
                ),
              ),
            ),
            SizedBox(height: AppTheme.spaceLG),
            Text(
              'No Achievements Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textGrey,
                  ),
            ),
            SizedBox(height: AppTheme.spaceSM),
            Text(
              'Complete your first workout to\nstart earning badges!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGrey.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatefulWidget {
  final Map<String, dynamic> achievement;
  final int index;

  const _AchievementCard({
    Key? key,
    required this.achievement,
    required this.index,
  }) : super(key: key);

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.1,
          0.5 + (widget.index * 0.1),
          curve: Curves.easeIn,
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

  Color _getBadgeColor(String badgeType) {
    switch (badgeType) {
      case 'first_workout':
        return AppTheme.accentBlue;
      case 'week_warrior':
      case 'consistency_7':
        return AppTheme.accentOrange;
      case 'month_master':
      case 'consistency_30':
        return AppTheme.success;
      case 'year_champion':
      case 'consistency_100':
        return AppTheme.primaryPurple;
      default:
        return AppTheme.accentYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconCode = widget.achievement['icon_code'] as String? ?? '🎯';
    final badgeName = widget.achievement['badge_name'] as String? ?? 'Achievement';
    final badgeType = widget.achievement['badge_type'] as String? ?? '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getBadgeColor(badgeType).withOpacity(0.2),
                _getBadgeColor(badgeType).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppTheme.mediumRadius,
            border: Border.all(
              color: _getBadgeColor(badgeType).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glow effect
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getBadgeColor(badgeType).withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getBadgeColor(badgeType).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Text(
                          iconCode,
                          style: TextStyle(fontSize: 32),
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: AppTheme.spaceSM),

              // Badge Name
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceXS),
                child: Text(
                  badgeName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getBadgeColor(badgeType),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
