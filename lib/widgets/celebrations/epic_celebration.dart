import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import 'package:confetti/confetti.dart';

/// Epic Celebration Widget - MAXIMUM DOPAMINE! 🎉
class EpicCelebration extends StatefulWidget {
  final String type; // 'level_up', 'achievement', 'challenge', 'streak'
  final Map<String, dynamic> data;
  final VoidCallback onComplete;

  const EpicCelebration({
    Key? key,
    required this.type,
    required this.data,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<EpicCelebration> createState() => _EpicCelebrationState();
}

class _EpicCelebrationState extends State<EpicCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late ConfettiController _confettiController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation
    _mainController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    // Scale pulse
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat();

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    // Confetti
    _confettiController = ConfettiController(
      duration: Duration(seconds: 3),
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _rotationController,
    );

    // Start animations
    _mainController.forward();
    _particleController.forward();
    _confettiController.play();

    // Auto dismiss after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark overlay
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.black87,
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                AppTheme.primaryPurple,
                AppTheme.accentOrange,
                AppTheme.accentYellow,
                AppTheme.success,
                AppTheme.accentBlue,
              ],
            ),
          ),

          // Animated particles
          ...List.generate(20, (index) => _buildParticle(index)),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _mainController,
                  curve: Interval(0.2, 0.6, curve: Curves.easeOut),
                )),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildCelebrationContent(),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 40,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onComplete();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final startX = random.nextDouble() * MediaQuery.of(context).size.width;
    final endY = MediaQuery.of(context).size.height;
    final duration = 2000 + random.nextInt(1000);
    final delay = random.nextInt(500);

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = _particleController.value;
        return Positioned(
          left: startX,
          top: -50 + (endY * progress),
          child: Opacity(
            opacity: 1.0 - progress,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRandomColor(random),
                boxShadow: [
                  BoxShadow(
                    color: _getRandomColor(random).withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRandomColor(math.Random random) {
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.accentOrange,
      AppTheme.accentYellow,
      AppTheme.success,
      AppTheme.accentBlue,
    ];
    return colors[random.nextInt(colors.length)];
  }

  Widget _buildCelebrationContent() {
    switch (widget.type) {
      case 'level_up':
        return _buildLevelUpContent();
      case 'achievement':
        return _buildAchievementContent();
      case 'challenge':
        return _buildChallengeContent();
      case 'streak':
        return _buildStreakContent();
      default:
        return _buildGenericContent();
    }
  }

  Widget _buildLevelUpContent() {
    final newLevel = widget.data['new_level'] ?? 0;
    final rank = widget.data['rank'] ?? {'title': 'Warrior', 'emoji': '⚔️'};

    return Container(
      padding: EdgeInsets.all(AppTheme.space2XL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LEVEL UP text
          Text(
            'LEVEL UP!',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..shader = AppTheme.energyGradient.createShader(
                  Rect.fromLTWH(0, 0, 200, 70),
                ),
            ),
          ),

          SizedBox(height: AppTheme.spaceLG),

          // Rotating level badge
          RotationTransition(
            turns: _rotationAnimation,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rank['emoji'] as String,
                      style: TextStyle(fontSize: 64),
                    ),
                    Text(
                      '$newLevel',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: AppTheme.spaceLG),

          // Rank title
          Text(
            rank['title'] as String,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: AppTheme.spaceSM),

          Text(
            'You\'re unstoppable!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementContent() {
    final badgeName = widget.data['badge_name'] ?? 'Achievement';
    final description = widget.data['description'] ?? 'You did it!';
    final icon = widget.data['icon'] ?? '🏆';

    return Container(
      padding: EdgeInsets.all(AppTheme.space2XL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ACHIEVEMENT UNLOCKED!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentYellow,
            ),
          ),

          SizedBox(height: AppTheme.spaceLG),

          // Pulsing badge
          AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_scaleController.value * 0.2),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.successGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: AppTheme.spaceLG),

          Text(
            badgeName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppTheme.spaceSM),

          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeContent() {
    final challengeName = widget.data['challenge_name'] ?? 'Challenge';
    final xpAwarded = widget.data['xp_awarded'] ?? 0;

    return Container(
      padding: EdgeInsets.all(AppTheme.space2XL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CHALLENGE COMPLETE!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentOrange,
            ),
          ),

          SizedBox(height: AppTheme.spaceLG),

          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.energyGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOrange.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '🎯',
                style: TextStyle(fontSize: 80),
              ),
            ),
          ),

          SizedBox(height: AppTheme.spaceLG),

          Text(
            challengeName,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppTheme.spaceMD),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLG,
              vertical: AppTheme.spaceMD,
            ),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withOpacity(0.2),
              borderRadius: AppTheme.largeRadius,
              border: Border.all(color: AppTheme.accentYellow, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⚡', style: TextStyle(fontSize: 32)),
                SizedBox(width: AppTheme.spaceSM),
                Text(
                  '+$xpAwarded XP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakContent() {
    final streakDays = widget.data['streak_days'] ?? 0;

    return Container(
      padding: EdgeInsets.all(AppTheme.space2XL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STREAK MILESTONE!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentOrange,
            ),
          ),

          SizedBox(height: AppTheme.spaceLG),

          AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_scaleController.value * 0.3),
                child: Text(
                  '🔥',
                  style: TextStyle(fontSize: 120),
                ),
              );
            },
          ),

          SizedBox(height: AppTheme.spaceLG),

          Text(
            '$streakDays DAYS!',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),

          SizedBox(height: AppTheme.spaceSM),

          Text(
            'You\'re on FIRE!',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericContent() {
    return Container(
      padding: EdgeInsets.all(AppTheme.space2XL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎉',
            style: TextStyle(fontSize: 100),
          ),
          SizedBox(height: AppTheme.spaceLG),
          Text(
            'AWESOME!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show epic celebration
void showEpicCelebration(
  BuildContext context, {
  required String type,
  required Map<String, dynamic> data,
  VoidCallback? onComplete,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    transitionDuration: Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return EpicCelebration(
        type: type,
        data: data,
        onComplete: onComplete ?? () {},
      );
    },
  );
}
