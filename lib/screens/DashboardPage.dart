import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/DataBaseHelper.dart';
import '../widgets/AnimatedLogo.dart';


class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ProgressEntry> _progressEntries = [];

  @override
  void initState() {
    super.initState();
    _loadProgressEntries();
  }

  Future<void> _loadProgressEntries() async {
    final entries = await _dbHelper.getProgressEntries();
    setState(() {
      _progressEntries = entries.map((e) => ProgressEntry.fromMap(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: AnimatedLogo()),
          SizedBox(height: 20),
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 20),
          _buildProgressCard(context),
          SizedBox(height: 20),
          _buildWeightChart(),
          SizedBox(height: 20),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressItem('Workouts', '12', Icons.fitness_center),
                _buildProgressItem('Calories', '1500', Icons.local_fire_department),
                _buildProgressItem('Weight', '-2.5 kg', Icons.monitor_weight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Theme.of(context).secondaryHeaderColor),
        SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }

  Widget _buildWeightChart() {
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: _progressEntries.length.toDouble() - 1,
          minY: _progressEntries.map((e) => e.weight).reduce((a, b) => a < b ? a : b),
          maxY: _progressEntries.map((e) => e.weight).reduce((a, b) => a > b ? a : b),
          lineBarsData: [
            LineChartBarData(
              spots: _progressEntries.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.weight);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Recent Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.fitness_center, color: Theme.of(context).secondaryHeaderColor),
            title: Text('Upper Body Workout'),
            subtitle: Text('Completed on Sep 24, 2024'),
          ),
          ListTile(
            leading: Icon(Icons.restaurant_menu, color: Theme.of(context).secondaryHeaderColor),
            title: Text('Logged Lunch'),
            subtitle: Text('Grilled Chicken Salad - 450 calories'),
          ),
          ListTile(
            leading: Icon(Icons.directions_run, color: Theme.of(context).secondaryHeaderColor),
            title: Text('Morning Run'),
            subtitle: Text('5 km in 30 minutes'),
          ),
        ],
      ),
    );
  }
}

class ProgressEntry {
  final int? id;
  final DateTime date;
  final double weight;
  final String notes;

  ProgressEntry({this.id, required this.date, required this.weight, required this.notes});

  factory ProgressEntry.fromMap(Map<String, dynamic> map) {
    return ProgressEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      weight: map['weight'],
      notes: map['notes'],
    );
  }
}