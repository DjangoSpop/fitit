import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HabitOnboardingScreen extends StatefulWidget {
  final Function onComplete;

  const HabitOnboardingScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<HabitOnboardingScreen> createState() => _HabitOnboardingScreenState();
}

class _HabitOnboardingScreenState extends State<HabitOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Build Lasting Habits',
      description:
          'Transform your fitness journey with psychology-backed habit formation. We help you build routines that stick.',
      icon: '💪',
      gradient: AppTheme.primaryGradient,
    ),
    OnboardingPage(
      title: 'Track Your Streaks',
      description:
          'Stay motivated with visual streak tracking. See your progress grow day by day and celebrate milestones.',
      icon: '🔥',
      gradient: AppTheme.energyGradient,
    ),
    OnboardingPage(
      title: 'Earn Achievements',
      description:
          'Unlock badges as you hit milestones. From your first workout to 100-day streaks, we celebrate every win.',
      icon: '🏆',
      gradient: AppTheme.successGradient,
    ),
    OnboardingPage(
      title: 'Smart Reminders',
      description:
          'Get personalized notifications at optimal times. We learn when you\'re most likely to workout.',
      icon: '🔔',
      gradient: AppTheme.calmGradient,
    ),
    OnboardingPage(
      title: 'Your Identity, Transformed',
      description:
          'You\'re not just working out - you\'re becoming someone who exercises. Let\'s build that identity together.',
      icon: '✨',
      gradient: AppTheme.primaryGradient,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.normalAnimation,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppTheme.normalAnimation,
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: EdgeInsets.all(AppTheme.spaceMD),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildOnboardingPage(_pages[index]),
                  );
                },
              ),
            ),

            // Page Indicator
            Padding(
              padding: EdgeInsets.all(AppTheme.spaceLG),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  dotColor: AppTheme.textGrey.withOpacity(0.3),
                  activeDotColor: AppTheme.primaryPurple,
                  dotHeight: 12,
                  dotWidth: 12,
                  spacing: 16,
                ),
              ),
            ),

            // Next/Get Started Button
            Padding(
              padding: EdgeInsets.all(AppTheme.spaceLG),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spaceLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: page.gradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.mediumShadow,
            ),
            child: Center(
              child: Text(
                page.icon,
                style: TextStyle(fontSize: 80),
              ),
            ),
          ),

          SizedBox(height: AppTheme.space2XL),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          SizedBox(height: AppTheme.spaceMD),

          // Description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textGrey,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String icon;
  final LinearGradient gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
