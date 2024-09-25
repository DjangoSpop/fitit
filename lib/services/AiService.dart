import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'https://your-ai-api-endpoint.com';

  static Future<Map<String, dynamic>> generateWorkoutPlan(Map<String, dynamic> userProfile) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate-workout-plan'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userProfile),
    );

    if (response.statusCode == 200) {
      final rawResponse = json.decode(response.body);
      return _processAIResponse(rawResponse, 'workout');
    } else {
      throw Exception('Failed to generate workout plan');
    }
  }

  static Future<Map<String, dynamic>> generateMealPlan(Map<String, dynamic> userProfile) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate-meal-plan'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userProfile),
    );

    if (response.statusCode == 200) {
      final rawResponse = json.decode(response.body);
      return _processAIResponse(rawResponse, 'meal');
    } else {
      throw Exception('Failed to generate meal plan');
    }
  }

  static Map<String, dynamic> _processAIResponse(Map<String, dynamic> rawResponse, String type) {
    // Process and structure the AI response
    List<Map<String, dynamic>> structuredPlan = [];

    if (type == 'workout') {
      for (var exercise in rawResponse['exercises']) {
        structuredPlan.add({
          'name': exercise['name'],
          'sets': exercise['sets'],
          'reps': exercise['reps'],
          'completed': false,
        });
      }
    } else if (type == 'meal') {
      for (var meal in rawResponse['meals']) {
        structuredPlan.add({
          'name': meal['name'],
          'calories': meal['calories'],
          'protein': meal['protein'],
          'carbs': meal['carbs'],
          'fats': meal['fats'],
          'completed': false,
        });
      }
    }

    return {
      'plan': structuredPlan,
      'recommendations': rawResponse['recommendations'] ?? '',
    };
  }
}