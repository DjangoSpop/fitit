import 'package:flutter/material.dart';
import 'package:getfitnot/screens/HomePage.dart';
import 'package:getfitnot/screens/Onboarding.dart';
import 'package:getfitnot/widgets/LoadingStateProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Apptheme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingStateProvider()),
      ],
      child: FitnessApp(onboardingComplete: onboardingComplete),
    ),
  );
}

class FitnessApp extends StatelessWidget {
  final bool onboardingComplete;

  FitnessApp({required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Fitness Planner',
      theme: AppTheme.lightTheme,
      home: onboardingComplete ? const Homepage() : OnboardingPage(),
    );
  }
}