import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/habit_provider.dart';

class WeeklyReflectionScreen extends StatefulWidget {
  const WeeklyReflectionScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyReflectionScreen> createState() => _WeeklyReflectionScreenState();
}

class _WeeklyReflectionScreenState extends State<WeeklyReflectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Reflection'),
        elevation: 0,
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          return FutureBuilder<Map<String, dynamic>>(
            future: habitProvider.getWeeklyReflection(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _buildErrorState();
              }

              return _buildReflectionContent(context, snapshot.data!);
            },
          );
        },
      ),
    );
  }

  Widget _buildReflectionContent(
    BuildContext context,
    Map<String, dynamic> reflection,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, reflection),
              SizedBox(height: AppTheme.spaceLG),
              _buildSummaryCard(context, reflection),
              SizedBox(height: AppTheme.spaceLG),
              _buildReflectionQuestionCard(context, reflection),
              SizedBox(height: AppTheme.spaceLG),
              _buildNextWeekFocusCard(context, reflection),
              SizedBox(height: AppTheme.space2XL),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> reflection) {
    final completionRate = int.tryParse(
          reflection['completion_rate']?.toString().replaceAll('%', '') ?? '0',
        ) ??
        0;

    return Container(
      padding: EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: completionRate >= 80
            ? AppTheme.successGradient
            : completionRate >= 50
                ? AppTheme.energyGradient
                : AppTheme.calmGradient,
        borderRadius: AppTheme.largeRadius,
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Column(
        children: [
          Text(
            _getWeekEmoji(completionRate),
            style: TextStyle(fontSize: 64),
          ),
          SizedBox(height: AppTheme.spaceMD),
          Text(
            _getWeekTitle(completionRate),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spaceSM),
          Text(
            'Week of ${_getCurrentWeekRange()}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> reflection) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spaceSM),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: AppTheme.smallRadius,
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                SizedBox(width: AppTheme.spaceMD),
                Text(
                  'Week Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spaceLG),
            _buildSummaryRow(
              Icons.fitness_center,
              'Workouts',
              reflection['week_summary'] ?? 'No data',
              AppTheme.accentOrange,
            ),
            SizedBox(height: AppTheme.spaceMD),
            _buildSummaryRow(
              Icons.restaurant_menu,
              'Meal Tracking',
              reflection['meal_adherence'] ?? 'No data',
              AppTheme.success,
            ),
            SizedBox(height: AppTheme.spaceMD),
            _buildSummaryRow(
              Icons.percent,
              'Completion Rate',
              reflection['completion_rate'] ?? '0%',
              AppTheme.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReflectionQuestionCard(
    BuildContext context,
    Map<String, dynamic> reflection,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('💭', style: TextStyle(fontSize: 24)),
                SizedBox(width: AppTheme.spaceSM),
                Expanded(
                  child: Text(
                    'Reflection Time',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spaceMD),
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.05),
                borderRadius: AppTheme.mediumRadius,
              ),
              child: Text(
                reflection['reflection_question'] ?? 'Keep up the great work!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextWeekFocusCard(
    BuildContext context,
    Map<String, dynamic> reflection,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppTheme.spaceSM),
                  decoration: BoxDecoration(
                    gradient: AppTheme.energyGradient,
                    borderRadius: AppTheme.smallRadius,
                  ),
                  child: Icon(Icons.trending_up, color: Colors.white),
                ),
                SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Text(
                    'Next Week Focus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spaceMD),
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.05),
                borderRadius: AppTheme.mediumRadius,
                border: Border.all(
                  color: AppTheme.accentOrange.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 24)),
                  SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Text(
                      reflection['next_week_focus'] ?? 'Keep building consistency!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
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

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Back to Dashboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text('Failed to load reflection data'),
    );
  }

  String _getWeekEmoji(int completionRate) {
    if (completionRate >= 90) return '🏆';
    if (completionRate >= 70) return '🔥';
    if (completionRate >= 50) return '💪';
    if (completionRate >= 30) return '👍';
    return '🌱';
  }

  String _getWeekTitle(int completionRate) {
    if (completionRate >= 90) return 'Incredible Week!';
    if (completionRate >= 70) return 'Strong Week!';
    if (completionRate >= 50) return 'Good Progress!';
    if (completionRate >= 30) return 'Getting Started!';
    return 'New Beginning!';
  }

  String _getCurrentWeekRange() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));

    return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
