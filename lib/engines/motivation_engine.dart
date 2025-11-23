import 'dart:math';

/// Motivation Engine - Daily Inspiration! 💪
class MotivationEngine {
  final Random _random = Random();

  // Epic motivational quotes organized by category
  static const Map<String, List<String>> QUOTES = {
    'morning': [
      "Wake up with determination. Go to bed with satisfaction. 💪",
      "Your only limit is YOU. Make today count! 🔥",
      "The pain you feel today will be the strength you feel tomorrow.",
      "Success starts with self-discipline. Let's do this! ⚡",
      "You're not just working out. You're building a lifestyle.",
      "The best project you'll ever work on is YOU. 💎",
      "Rise and grind! Your future self will thank you.",
      "Champions are made when no one is watching. 👑",
    ],
    'motivation': [
      "You didn't come this far to only come this far. 🚀",
      "Excuses don't burn calories. Actions do! 🔥",
      "The difference between try and triumph is a little UMPH! 💥",
      "Your body can stand almost anything. It's your mind you have to convince.",
      "Don't wish for it. WORK for it! 💪",
      "Sweat is magic. Cover yourself in it daily to grant your wishes.",
      "The only bad workout is the one that didn't happen.",
      "You're one workout away from a good mood. Let's go! 😤",
    ],
    'discipline': [
      "Discipline is choosing between what you want now and what you want most.",
      "It's not about having time. It's about making time. ⏰",
      "The pain of discipline is far less than the pain of regret.",
      "Don't stop when you're tired. Stop when you're DONE! 🎯",
      "Excellence is not a singular act. It's a habit. 👊",
      "The body achieves what the mind believes. 🧠",
      "No pain, no gain. Shut up and train! 💪",
      "Consistency > Intensity. Show up. Every. Single. Day.",
    ],
    'achievement': [
      "Look at you! Crushing goals like a BOSS! 🏆",
      "You're not just working out. You're becoming legendary! ✨",
      "This is YOUR time. OWN IT! 👑",
      "You didn't wake up today to be mediocre. Dominate! 🔥",
      "Every rep, every step, every choice matters. Keep going!",
      "You're rewriting your story. Make it epic! 📖",
      "Progress is progress, no matter how small. Celebrate it! 🎉",
      "You're literally building your dream body. How cool is that?! 💎",
    ],
    'struggle': [
      "If it doesn't challenge you, it doesn't change you. 💪",
      "Embrace the struggle. That's where the magic happens. ✨",
      "Pain is temporary. Pride is forever. 🏆",
      "When you feel like quitting, remember why you started.",
      "The struggle you're in today is developing the strength for tomorrow.",
      "Diamonds are formed under pressure. So are champions! 💎",
      "Fall seven times, stand up eight. You got this! 👊",
      "This is the part of the movie where you DON'T QUIT! 🎬",
    ],
    'recovery': [
      "Rest is not a luxury. It's a necessity. Recovery day = Growth day! 🌱",
      "Your muscles are being rebuilt right now. Recovery is progress! 💪",
      "Smart athletes know when to push and when to rest. You're smart! 🧠",
      "Today's rest is tomorrow's PR. Take care of yourself! 🛌",
      "Recovery isn't slacking. It's strategic advancement. 🎯",
      "You're not weak for resting. You're wise. Come back stronger! 💪",
      "Your body whispers. Learn to listen. Rest when needed. 👂",
      "Recovery days are where the gains happen. Enjoy it! ✨",
    ],
    'streak': [
      "Look at that streak! You're absolutely unstoppable! 🔥",
      "Day after day, you show up. That's what legends do! 👑",
      "Your consistency is INSPIRING! Keep the fire burning! 🔥",
      "Streaks don't lie. You're committed. You're dedicated. You're AWESOME! ⭐",
      "One day at a time, you're building something incredible! 🏗️",
      "That streak is your superpower. Protect it! 💪",
      "Consistency beats talent every time. You're proof! 🏆",
      "You're not just on a streak. You're on a MISSION! 🚀",
    ],
    'weekend': [
      "Weekend warriors, UNITE! Let's make it count! 💪",
      "No excuses. Weekends are for CRUSHING goals! 🎯",
      "While others are resting, you're progressing. Legend! 👑",
      "Weekend mode: ACTIVATED! Time to dominate! 🔥",
      "Saturday/Sunday? More like SLAY-turday and STUN-day! ✨",
      "Your dedication doesn't take weekends off! 💎",
      "Weekend warriors, this is YOUR time to shine! 🌟",
      "Rest is for after you've earned it. Let's work! 💪",
    ],
    'goal': [
      "Your goal is closer than you think. One more step! 🎯",
      "Big dreams require big effort. You're doing it! 💪",
      "Every workout brings you closer to your goal. Keep pushing! 🚀",
      "You set the goal. Now GO GET IT! 🔥",
      "Goals don't work unless YOU do. And you're working! 💼",
      "That goal? It's already yours. Just keep showing up! 👑",
      "Dream it. Believe it. ACHIEVE IT! You're on your way! ✨",
      "Your goal is waiting for you on the other side of hard work! 🏆",
    ],
  };

  // Emojis for different moods
  static const Map<String, String> MOOD_EMOJIS = {
    'fire': '🔥',
    'strong': '💪',
    'rocket': '🚀',
    'trophy': '🏆',
    'star': '⭐',
    'lightning': '⚡',
    'crown': '👑',
    'diamond': '💎',
    'sparkles': '✨',
    'target': '🎯',
  };

  /// Get quote based on time of day
  String getTimeBasedQuote() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return getRandomQuote('morning');
    } else if (hour >= 12 && hour < 17) {
      return getRandomQuote('motivation');
    } else if (hour >= 17 && hour < 21) {
      return getRandomQuote('discipline');
    } else {
      return getRandomQuote('recovery');
    }
  }

  /// Get quote based on user state
  String getContextualQuote({
    required int currentStreak,
    required int totalWorkouts,
    required double weeklyCompletion,
    bool isWeekend = false,
  }) {
    // Struggling
    if (weeklyCompletion < 0.3) {
      return getRandomQuote('struggle');
    }

    // Weekend
    if (isWeekend) {
      return getRandomQuote('weekend');
    }

    // Great streak
    if (currentStreak >= 7) {
      return getRandomQuote('streak');
    }

    // Achievement milestone
    if (totalWorkouts % 50 == 0 && totalWorkouts > 0) {
      return getRandomQuote('achievement');
    }

    // Default motivational
    return getRandomQuote('motivation');
  }

  /// Get random quote from category
  String getRandomQuote(String category) {
    final quotes = QUOTES[category] ?? QUOTES['motivation']!;
    return quotes[_random.nextInt(quotes.length)];
  }

  /// Get all quotes from category
  List<String> getQuotesByCategory(String category) {
    return QUOTES[category] ?? QUOTES['motivation']!;
  }

  /// Get quote of the day (consistent for the day)
  String getQuoteOfTheDay() {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final random = Random(seed);

    final allQuotes = QUOTES.values.expand((list) => list).toList();
    return allQuotes[random.nextInt(allQuotes.length)];
  }

  /// Get random motivational emoji
  String getMotivationalEmoji() {
    final emojis = MOOD_EMOJIS.values.toList();
    return emojis[_random.nextInt(emojis.length)];
  }

  /// Get personalized workout encouragement
  String getWorkoutEncouragement({
    required int setsCompleted,
    required int totalSets,
  }) {
    final progress = setsCompleted / totalSets;

    if (progress < 0.25) {
      return [
        "Great start! Keep that energy up! 💪",
        "You're just getting warmed up! 🔥",
        "Looking good! Let's keep going! 💯",
        "Smooth start! Keep the momentum! 🚀",
      ][_random.nextInt(4)];
    } else if (progress < 0.50) {
      return [
        "Halfway there! You're crushing it! 💪",
        "Keep pushing! You're doing amazing! 🔥",
        "50% done! No stopping now! ⚡",
        "Halfway mark! You got this! 🎯",
      ][_random.nextInt(4)];
    } else if (progress < 0.75) {
      return [
        "Almost there! Finish strong! 💪",
        "You're in the home stretch! 🏁",
        "So close! Don't stop now! 🔥",
        "Final push! You're killing it! 💯",
      ][_random.nextInt(4)];
    } else if (progress < 1.0) {
      return [
        "One more! You're ALMOST DONE! 🎯",
        "Final set! Give it EVERYTHING! 💪",
        "Last one! Make it count! 🔥",
        "Finish line in sight! PUSH! 🏆",
      ][_random.nextInt(4)];
    } else {
      return [
        "WORKOUT COMPLETE! You're a BEAST! 🏆",
        "DONE! You absolutely CRUSHED it! 💪",
        "FINISHED! That's what I'm talking about! 🔥",
        "COMPLETE! You're unstoppable! 👑",
      ][_random.nextInt(4)];
    }
  }

  /// Get rest day message
  String getRestDayMessage() {
    return [
      "Recovery day! Your muscles are growing right now! 💪",
      "Smart choice! Rest is when the magic happens! ✨",
      "Your body is thanking you today! 🙏",
      "Recovery = Progress. You're doing it right! 💎",
      "Rest today, dominate tomorrow! 🔥",
    ][_random.nextInt(5)];
  }

  /// Get streak protection message
  String getStreakProtectionMessage(int streakDays) {
    if (streakDays >= 30) {
      return "Your $streakDays-day streak is LEGENDARY! Protect it at all costs! 👑";
    } else if (streakDays >= 14) {
      return "Two weeks strong! Don't let your $streakDays-day streak die today! 🔥";
    } else if (streakDays >= 7) {
      return "A full week! Your $streakDays-day streak is too precious to lose! ⭐";
    } else {
      return "Keep your $streakDays-day streak alive! You've got this! 💪";
    }
  }

  /// Get challenge encouragement
  String getChallengeEncouragement(double progressPercent) {
    if (progressPercent < 25) {
      return "Challenge accepted! Let's build momentum! 🚀";
    } else if (progressPercent < 50) {
      return "Making progress! Keep grinding! 💪";
    } else if (progressPercent < 75) {
      return "Over halfway! You're crushing this challenge! 🔥";
    } else if (progressPercent < 100) {
      return "Almost there! Finish strong! 🏆";
    } else {
      return "CHALLENGE COMPLETE! You're a champion! 👑";
    }
  }

  /// Get level up teaser
  String getLevelUpTeaser(int xpToNextLevel) {
    if (xpToNextLevel <= 50) {
      return "SO CLOSE to leveling up! Just $xpToNextLevel XP away! 🎯";
    } else if (xpToNextLevel <= 100) {
      return "Level up incoming! Only $xpToNextLevel XP to go! ⚡";
    } else {
      return "Keep grinding XP! $xpToNextLevel away from next level! 💪";
    }
  }

  /// Get comeback message (for users who haven't worked out in a while)
  String getComebackMessage(int daysSinceLastWorkout) {
    if (daysSinceLastWorkout <= 1) {
      return "Welcome back! Let's pick up where we left off! 💪";
    } else if (daysSinceLastWorkout <= 3) {
      return "Hey stranger! Ready to jump back in? Let's go! 🔥";
    } else if (daysSinceLastWorkout <= 7) {
      return "Missed you! Today's the perfect day for a comeback! 🚀";
    } else {
      return "Every champion has setbacks. Today is your comeback story! 👑";
    }
  }

  /// Get all quote categories
  List<String> getAllCategories() {
    return QUOTES.keys.toList();
  }

  /// Get daily affirmation
  String getDailyAffirmation() {
    final affirmations = [
      "I am strong, capable, and unstoppable.",
      "My body is getting stronger every day.",
      "I choose health and vitality.",
      "I am committed to my fitness journey.",
      "Every workout makes me stronger mentally and physically.",
      "I am building the body I deserve.",
      "My dedication is transforming my life.",
      "I am worthy of investing in myself.",
      "I show up for myself every single day.",
      "I am becoming the best version of myself.",
    ];
    return affirmations[_random.nextInt(affirmations.length)];
  }
}
