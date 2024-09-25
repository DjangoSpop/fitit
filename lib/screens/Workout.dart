import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:getfitnot/services/DataBaseHelper.dart';


import '../services/AiService.dart';
import '../services/DataBaseHelper.dart';
import '../widgets/LoadingOverlayWidget.dart';
import '../widgets/LoadingStateProvider.dart';

class WorkoutPage extends StatefulWidget {
  @override
  _WorkoutPageState createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<String, dynamic> _workoutPlan = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
  }

  Future<void> _loadWorkoutPlan() async {
    final loadingProvider = Provider.of<LoadingStateProvider>(context, listen: false);
    loadingProvider.setLoading(true);

    try {
      final userProfile = await _dbHelper.getUserProfile();
      if (userProfile != null) {
        _workoutPlan = await AIService.generateWorkoutPlan(userProfile);
      } else {
        _workoutPlan = {'error': 'Please complete your user profile first.'};
      }
    } catch (e) {
      _workoutPlan = {'error': 'Failed to generate workout plan. Please try again later.'};
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
              title: Text('Workout Plan'),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadWorkoutPlan,
                ),
              ],
            ),
            body: _workoutPlan.containsKey('error')
                ? Center(child: Text(_workoutPlan['error']))
                : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _workoutPlan['plan']?.length ?? 0,
                    itemBuilder: (context, index) {
                      final exercise = _workoutPlan['plan'][index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: CheckboxListTile(
                          title: Text(exercise['name']),
                          subtitle: Text('Sets: ${exercise['sets']}, Reps: ${exercise['reps']}'),
                          value: exercise['completed'],
                          onChanged: (bool? value) {
                            setState(() {
                              exercise['completed'] = value;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (_workoutPlan['recommendations'] != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recommendations: ${_workoutPlan['recommendations']}',
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