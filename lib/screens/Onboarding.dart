import 'package:flutter/material.dart';
import 'package:getfitnot/screens/profile.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatelessWidget {
  final List<PageViewModel> pages = [
    PageViewModel(
      title: "Welcome to AI Fitness Planner",
      body: "Your personal AI-powered fitness companion.",
      image: Center(
        child: Image.asset("assets/welcome.png", height: 175.0),
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
        bodyTextStyle: TextStyle(fontSize: 18.0),
      ),
    ),
    PageViewModel(
      title: "Personalized Workout Plans",
      body: "Get AI-generated workout plans tailored to your fitness goals and level.",
      image: Center(
        child: Image.asset("assets/workout.png", height: 175.0),
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
        bodyTextStyle: TextStyle(fontSize: 18.0),
      ),
    ),
    PageViewModel(
      title: "Custom Meal Plans",
      body: "Receive personalized meal plans based on your dietary preferences and goals.",
      image: Center(
        child: Image.asset("assets/meal.png", height: 175.0),
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
        bodyTextStyle: TextStyle(fontSize: 18.0),
      ),
    ),
    PageViewModel(
      title: "Track Your Progress",
      body: "Monitor your fitness journey with easy-to-use tracking tools and visualizations.",
      image: Center(
        child: Image.asset("assets/progress.png", height: 175.0),
      ),
      decoration: PageDecoration(
        titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
        bodyTextStyle: TextStyle(fontSize: 18.0),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: pages,
      onDone: () async {
        // Mark onboarding as completed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);

        // Navigate to user profile setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => UserProfilePage(isInitialSetup: true)),
        );
      },
      onSkip: () async {
        // Mark onboarding as completed
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_complete', true);

        // Navigate to user profile setup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => UserProfilePage(isInitialSetup: true)),
        );
      },
      showSkipButton: true,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).colorScheme.secondary,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}