import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/habit_provider.dart';
import '../widgets/professional/streak_card_pro.dart';
import '../widgets/professional/achievement_showcase.dart';
import '../widgets/professional/daily_habits_card.dart';

class ProfessionalDashboard extends StatefulWidget {
  final int userId;

  const ProfessionalDashboard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfessionalDashboard> createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitProvider(userId: widget.userId),
      child: Scaffold(
        body: Consumer<HabitProvider>(
          builder: (context, habitProvider, child) {
            if (habitProvider.isLoading && !habitProvider.isLoaded) {
              return _buildLoadingState();
            }

            if (habitProvider.hasError) {
              return _buildErrorState(context, habitProvider);
            }

            return RefreshIndicator(
              onRefresh: habitProvider.refresh,
              color: AppTheme.primaryPurple,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context, habitProvider),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spaceMD),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMotivationCard(context, habitProvider),
                          SizedBox(height: AppTheme.spaceLG),
                          _buildQuickStats(context, habitProvider),
                          SizedBox(height: AppTheme.spaceLG),
                          DailyHabitsCard(
                            exerciseCompleted:
                                habitProvider.isHabitCompletedToday('exercise'),
                            mealLogged:
                                habitProvider.isHabitCompletedToday('meal_logging'),
                            waterGoalMet:
                                habitProvider.isHabitCompletedToday('water'),
                            onHabitTap: (habitType) =>
                                _handleHabitCompletion(context, habitProvider, habitType),
                            weekProgress: _getWeekProgress(habitProvider),
                          ),
                          SizedBox(height: AppTheme.spaceLG),
                          _buildStreaksSection(context, habitProvider),
                          SizedBox(height: AppTheme.spaceLG),
                          AchievementShowcase(
                            achievements: habitProvider.getRecentAchievements(),
                            onViewAll: () => _showAllAchievements(context, habitProvider),
                          ),
                          SizedBox(height: AppTheme.space2XL),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, HabitProvider habitProvider) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              padding: EdgeInsets.all(AppTheme.spaceLG),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          '👋',
                          style: TextStyle(fontSize: 32),
                        ),
                        SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppTheme.spaceXS),
                              Text(
                                'Let\'s make today count',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildProfileButton(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.person, color: Colors.white),
        onPressed: () {
          // Navigate to profile/settings
        },
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context, HabitProvider habitProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          gradient: AppTheme.calmGradient,
          borderRadius: AppTheme.largeRadius,
          boxShadow: AppTheme.mediumShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wb_sunny_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Text(
                habitProvider.motivationMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, HabitProvider habitProvider) {
    final stats = habitProvider.motivationalStats;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total',
            '${stats['total_workouts'] ?? 0}',
            'workouts',
            Icons.fitness_center,
            AppTheme.accentOrange,
          ),
        ),
        SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: _buildStatCard(
            context,
            'This Week',
            '${stats['weekly_completion'] ?? 0}/7',
            'days',
            Icons.calendar_today,
            AppTheme.success,
          ),
        ),
        SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: _buildStatCard(
            context,
            'Badges',
            '${stats['total_badges'] ?? 0}',
            'earned',
            Icons.emoji_events,
            AppTheme.accentYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppTheme.mediumRadius,
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: AppTheme.spaceSM),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: AppTheme.spaceXS),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaksSection(BuildContext context, HabitProvider habitProvider) {
    if (habitProvider.streaks.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceXS),
          child: Text(
            'Your Streaks 🔥',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(height: AppTheme.spaceMD),
        ...habitProvider.streaks.entries.map((entry) {
          final habitType = entry.key;
          final streakData = entry.value;
          return StreakCardPro(
            currentStreak: streakData['current_streak'] as int? ?? 0,
            longestStreak: streakData['longest_streak'] as int? ?? 0,
            habitType: habitType,
            onTap: () {
              // Show streak details
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          SizedBox(height: AppTheme.spaceLG),
          Text(
            'Loading your progress...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, HabitProvider habitProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            SizedBox(height: AppTheme.spaceLG),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spaceSM),
            Text(
              habitProvider.errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textGrey,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spaceLG),
            ElevatedButton.icon(
              onPressed: () => habitProvider.refresh(),
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  List<bool> _getWeekProgress(HabitProvider habitProvider) {
    final weekProgress = <bool>[];
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final targetDate = today.subtract(Duration(days: today.weekday - 1 - i));
      final targetDateString =
          '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

      bool completed = false;
      for (var habit in habitProvider.weeklyHabits) {
        final habitDate = habit['date'] as String;
        if (habitDate.startsWith(targetDateString) &&
            habit['exercise_completed'] == 1) {
          completed = true;
          break;
        }
      }
      weekProgress.add(completed);
    }

    return weekProgress;
  }

  Future<void> _handleHabitCompletion(
    BuildContext context,
    HabitProvider habitProvider,
    String habitType,
  ) async {
    try {
      final newBadges = await habitProvider.completeHabit(habitType);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Text(
                  'Great job! Habit completed 🎉',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.mediumRadius,
          ),
          duration: Duration(seconds: 2),
        ),
      );

      if (newBadges.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 500));
        _showBadgeAwardDialog(context, newBadges);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete habit'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showBadgeAwardDialog(BuildContext context, List<String> badges) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.largeRadius,
        ),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: AppTheme.largeRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '🏆',
                      style: TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spaceLG),
              Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppTheme.spaceSM),
              Text(
                'You earned ${badges.length} new badge${badges.length > 1 ? 's' : ''}!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: AppTheme.spaceLG),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryPurple,
                  ),
                  child: Text(
                    'Awesome!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllAchievements(BuildContext context, HabitProvider habitProvider) {
    // Navigate to full achievements page
    // TODO: Implement full achievements screen
  }
}
