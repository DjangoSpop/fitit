import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/AiService.dart';
import '../services/DataBaseHelper.dart';
import '../widgets/LoadingOverlayWidget.dart';
import '../widgets/LoadingStateProvider.dart';

class MealPlanPage extends StatefulWidget {
  @override
  _MealPlanPageState createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<String, dynamic> _mealPlan = {};

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    final loadingProvider = Provider.of<LoadingStateProvider>(context, listen: false);
    loadingProvider.setLoading(true);

    try {
      final userProfile = await _dbHelper.getUserProfile();
      if (userProfile != null) {
        _mealPlan = await AIService.generateMealPlan(userProfile);
      } else {
        _mealPlan = {'error': 'Please complete your user profile first.'};
      }
    } catch (e) {
      _mealPlan = {'error': 'Failed to generate meal plan. Please try again later.'};
    }

    loadingProvider.setLoading(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingStateProvider>(
      builder: (context, loadingProvider, child) {
        return LoadingOverlay(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Meal Plan'),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadMealPlan,
                ),
              ],
            ),
            body: _mealPlan.containsKey('error')
                ? Center(child: Text(_mealPlan['error']))
                : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _mealPlan['plan']?.length ?? 0,
                    itemBuilder: (context, index) {
                      final meal = _mealPlan['plan'][index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CheckboxListTile(
                          title: Text(meal['name']),
                          subtitle: Text(
                            'Calories: ${meal['calories']}, '
                                'Protein: ${meal['protein']}g, '
                                'Carbs: ${meal['carbs']}g, '
                                'Fats: ${meal['fats']}g',
                          ),
                          value: meal['completed'],
                          onChanged: (bool? value) {
                            setState(() {
                              meal['completed'] = value;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (_mealPlan['recommendations'] != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recommendations: ${_mealPlan['recommendations']}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}