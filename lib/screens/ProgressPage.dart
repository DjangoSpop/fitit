import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/DataBaseHelper.dart';


class ProgressPage extends StatefulWidget {
  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final List<ProgressEntry> _progressEntries = [];
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProgressEntries();
  }

  Future<void> _loadProgressEntries() async {
    final entries = await _dbHelper.getProgressEntries();
    setState(() {
      _progressEntries.clear();
      _progressEntries.addAll(entries.map((e) => ProgressEntry.fromMap(e)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Tracker'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _progressEntries.length,
              itemBuilder: (context, index) {
                return _buildProgressEntryCard(_progressEntries[index]);
              },
            ),
          ),
          _buildAddProgressForm(),
        ],
      ),
    );
  }

  Widget _buildProgressEntryCard(ProgressEntry entry) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(entry.date),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${entry.weight} kg',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(entry.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProgressForm() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _addProgressEntry,
            child: Text('Add Progress Entry'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProgressEntry() async {
    if (_weightController.text.isNotEmpty) {
      final newEntry = ProgressEntry(
        date: DateTime.now(),
        weight: double.parse(_weightController.text),
        notes: _notesController.text,
      );

      await _dbHelper.insertProgressEntry(newEntry.toMap());
      await _loadProgressEntries();

      _weightController.clear();
      _notesController.clear();
    }
  }
}

class ProgressEntry {
  final int? id;
  final DateTime date;
  final double weight;
  final String notes;

  ProgressEntry({this.id, required this.date, required this.weight, required this.notes});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'weight': weight,
      'notes': notes,
    };
  }

  static ProgressEntry fromMap(Map<String, dynamic> map) {
    return ProgressEntry(
      id: map['id'],
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      weight: map['weight'],
      notes: map['notes'],
    );
  }
}