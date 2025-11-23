import '../services/database_helper_enhanced.dart';
import 'dart:math';

/// Transformation Timeline Engine - Your Journey Visualized! 📈
///
/// This creates a compelling visual story of the user's fitness transformation,
/// showing progress photos, milestones, and emotional wins over time.
class TransformationTimelineEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  TransformationTimelineEngine({required this.userId});

  /// Add transformation checkpoint
  Future<int> addCheckpoint({
    required String checkpointType, // 'photo', 'measurement', 'achievement', 'milestone'
    required String title,
    String? description,
    String? photoUrl,
    Map<String, dynamic>? measurements,
    Map<String, dynamic>? metadata,
    String? emotionalNote,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transformation_checkpoints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        checkpoint_type TEXT,
        title TEXT,
        description TEXT,
        photo_url TEXT,
        measurements TEXT,
        metadata TEXT,
        emotional_note TEXT,
        checkpoint_date TEXT,
        is_milestone INTEGER DEFAULT 0,
        likes_count INTEGER DEFAULT 0
      )
    ''');

    return await db.insert('transformation_checkpoints', {
      'user_id': userId,
      'checkpoint_type': checkpointType,
      'title': title,
      'description': description,
      'photo_url': photoUrl,
      'measurements': _encodeMap(measurements),
      'metadata': _encodeMap(metadata),
      'emotional_note': emotionalNote,
      'checkpoint_date': DateTime.now().toIso8601String(),
      'is_milestone': 0,
    });
  }

  /// Get full transformation timeline
  Future<List<Map<String, dynamic>>> getFullTimeline({
    int? daysBack,
    String? checkpointType,
  }) async {
    final db = await _dbHelper.database;

    try {
      String whereClause = 'user_id = ?';
      List<dynamic> whereArgs = [userId];

      if (checkpointType != null) {
        whereClause += ' AND checkpoint_type = ?';
        whereArgs.add(checkpointType);
      }

      if (daysBack != null) {
        final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
        whereClause += ' AND checkpoint_date >= ?';
        whereArgs.add(cutoffDate.toIso8601String());
      }

      final results = await db.query(
        'transformation_checkpoints',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'checkpoint_date DESC',
      );

      return results.map((r) {
        return {
          ...r,
          'measurements': _decodeMap(r['measurements'] as String?),
          'metadata': _decodeMap(r['metadata'] as String?),
          'time_ago': _getTimeAgo(r['checkpoint_date'] as String),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get timeline by month
  Future<Map<String, List<Map<String, dynamic>>>> getTimelineByMonth() async {
    final timeline = await getFullTimeline();
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var checkpoint in timeline) {
      final date = DateTime.parse(checkpoint['checkpoint_date'] as String);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(checkpoint);
    }

    return grouped;
  }

  /// Get transformation stats
  Future<Map<String, dynamic>> getTransformationStats() async {
    final db = await _dbHelper.database;

    try {
      // Get first and latest checkpoints
      final checkpoints = await db.query(
        'transformation_checkpoints',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'checkpoint_date ASC',
      );

      if (checkpoints.isEmpty) {
        return {
          'total_checkpoints': 0,
          'days_on_journey': 0,
          'total_photos': 0,
          'total_milestones': 0,
        };
      }

      final firstCheckpoint = checkpoints.first;
      final latestCheckpoint = checkpoints.last;

      final startDate = DateTime.parse(firstCheckpoint['checkpoint_date'] as String);
      final currentDate = DateTime.now();
      final daysOnJourney = currentDate.difference(startDate).inDays;

      final photoCount = checkpoints.where((c) => c['checkpoint_type'] == 'photo').length;
      final milestoneCount = checkpoints.where((c) => c['is_milestone'] == 1).length;

      // Calculate weight change if available
      double? weightChange;
      final firstMeasurements = _decodeMap(firstCheckpoint['measurements'] as String?);
      final latestMeasurements = _decodeMap(latestCheckpoint['measurements'] as String?);

      if (firstMeasurements != null && latestMeasurements != null) {
        final firstWeight = firstMeasurements['weight'] as double?;
        final latestWeight = latestMeasurements['weight'] as double?;

        if (firstWeight != null && latestWeight != null) {
          weightChange = latestWeight - firstWeight;
        }
      }

      return {
        'total_checkpoints': checkpoints.length,
        'days_on_journey': daysOnJourney,
        'total_photos': photoCount,
        'total_milestones': milestoneCount,
        'weight_change': weightChange,
        'start_date': firstCheckpoint['checkpoint_date'],
        'latest_checkpoint': latestCheckpoint['checkpoint_date'],
      };
    } catch (e) {
      return {
        'total_checkpoints': 0,
        'days_on_journey': 0,
        'total_photos': 0,
        'total_milestones': 0,
      };
    }
  }

  /// Create side-by-side comparison
  Future<Map<String, dynamic>> createComparison({
    required int checkpoint1Id,
    required int checkpoint2Id,
  }) async {
    final db = await _dbHelper.database;

    try {
      final checkpoint1 = await db.query(
        'transformation_checkpoints',
        where: 'id = ? AND user_id = ?',
        whereArgs: [checkpoint1Id, userId],
        limit: 1,
      );

      final checkpoint2 = await db.query(
        'transformation_checkpoints',
        where: 'id = ? AND user_id = ?',
        whereArgs: [checkpoint2Id, userId],
        limit: 1,
      );

      if (checkpoint1.isEmpty || checkpoint2.isEmpty) {
        return {};
      }

      final c1 = checkpoint1.first;
      final c2 = checkpoint2.first;

      final date1 = DateTime.parse(c1['checkpoint_date'] as String);
      final date2 = DateTime.parse(c2['checkpoint_date'] as String);
      final daysBetween = date2.difference(date1).inDays.abs();

      // Calculate measurement differences
      final measurements1 = _decodeMap(c1['measurements'] as String?);
      final measurements2 = _decodeMap(c2['measurements'] as String?);

      Map<String, double>? measurementChanges;
      if (measurements1 != null && measurements2 != null) {
        measurementChanges = {};
        for (var key in measurements1.keys) {
          if (measurements2.containsKey(key)) {
            final val1 = measurements1[key] as double?;
            final val2 = measurements2[key] as double?;
            if (val1 != null && val2 != null) {
              measurementChanges[key] = val2 - val1;
            }
          }
        }
      }

      return {
        'checkpoint_1': c1,
        'checkpoint_2': c2,
        'days_between': daysBetween,
        'measurement_changes': measurementChanges,
        'transformation_message': _generateTransformationMessage(daysBetween, measurementChanges),
      };
    } catch (e) {
      return {};
    }
  }

  /// Add body measurements
  Future<int> addBodyMeasurements({
    required double weight,
    double? bodyFatPercentage,
    double? muscleMass,
    double? chest,
    double? waist,
    double? hips,
    double? biceps,
    double? thighs,
    String? notes,
  }) async {
    final measurements = {
      'weight': weight,
      if (bodyFatPercentage != null) 'body_fat_percentage': bodyFatPercentage,
      if (muscleMass != null) 'muscle_mass': muscleMass,
      if (chest != null) 'chest': chest,
      if (waist != null) 'waist': waist,
      if (hips != null) 'hips': hips,
      if (biceps != null) 'biceps': biceps,
      if (thighs != null) 'thighs': thighs,
    };

    return await addCheckpoint(
      checkpointType: 'measurement',
      title: 'Body Measurements',
      description: notes,
      measurements: measurements,
    );
  }

  /// Get measurement trends
  Future<Map<String, List<Map<String, dynamic>>>> getMeasurementTrends({
    int daysBack = 90,
  }) async {
    final db = await _dbHelper.database;

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      final results = await db.query(
        'transformation_checkpoints',
        where: 'user_id = ? AND checkpoint_type = ? AND checkpoint_date >= ?',
        whereArgs: [userId, 'measurement', cutoffDate.toIso8601String()],
        orderBy: 'checkpoint_date ASC',
      );

      // Organize by measurement type
      final Map<String, List<Map<String, dynamic>>> trends = {
        'weight': [],
        'body_fat_percentage': [],
        'muscle_mass': [],
        'chest': [],
        'waist': [],
        'hips': [],
        'biceps': [],
        'thighs': [],
      };

      for (var result in results) {
        final measurements = _decodeMap(result['measurements'] as String?);
        final date = result['checkpoint_date'] as String;

        if (measurements != null) {
          for (var key in trends.keys) {
            if (measurements.containsKey(key)) {
              trends[key]!.add({
                'date': date,
                'value': measurements[key],
              });
            }
          }
        }
      }

      // Remove empty trends
      trends.removeWhere((key, value) => value.isEmpty);

      return trends;
    } catch (e) {
      return {};
    }
  }

  /// Mark checkpoint as milestone
  Future<void> markAsMilestone(int checkpointId, {String? milestoneTitle}) async {
    final db = await _dbHelper.database;

    await db.update(
      'transformation_checkpoints',
      {
        'is_milestone': 1,
        'title': milestoneTitle ?? 'Milestone Achievement',
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [checkpointId, userId],
    );
  }

  /// Get milestone moments
  Future<List<Map<String, dynamic>>> getMilestones() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'transformation_checkpoints',
        where: 'user_id = ? AND is_milestone = 1',
        whereArgs: [userId],
        orderBy: 'checkpoint_date DESC',
      );

      return results.map((r) {
        return {
          ...r,
          'measurements': _decodeMap(r['measurements'] as String?),
          'metadata': _decodeMap(r['metadata'] as String?),
          'time_ago': _getTimeAgo(r['checkpoint_date'] as String),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Generate transformation summary
  Future<Map<String, dynamic>> generateTransformationSummary() async {
    final stats = await getTransformationStats();
    final milestones = await getMilestones();
    final timeline = await getFullTimeline(daysBack: 30);

    final recentPhotos = timeline.where((c) => c['checkpoint_type'] == 'photo').take(4).toList();

    String summaryText = _generateSummaryText(stats, milestones.length);

    return {
      'stats': stats,
      'milestone_count': milestones.length,
      'recent_milestones': milestones.take(3).toList(),
      'recent_photos': recentPhotos,
      'recent_activity_count': timeline.length,
      'summary_text': summaryText,
      'motivation_level': _calculateMotivationLevel(stats, timeline.length),
    };
  }

  /// Private helper methods
  String _encodeMap(Map<String, dynamic>? map) {
    if (map == null) return '';
    return map.entries.map((e) => '${e.key}:${e.value}').join('|||');
  }

  Map<String, dynamic>? _decodeMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;

    final Map<String, dynamic> result = {};
    final pairs = encoded.split('|||');

    for (var pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0];
        final value = double.tryParse(parts[1]) ?? parts[1];
        result[key] = value;
      }
    }

    return result.isEmpty ? null : result;
  }

  String _getTimeAgo(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  String _generateTransformationMessage(int days, Map<String, double>? changes) {
    if (changes == null || changes.isEmpty) {
      return 'Amazing transformation over $days days! Keep pushing!';
    }

    final weightChange = changes['weight'];

    if (weightChange != null) {
      final absChange = weightChange.abs();
      if (weightChange < 0) {
        return 'INCREDIBLE! You\'ve lost ${absChange.toStringAsFixed(1)} kg in $days days! 🔥';
      } else if (weightChange > 0) {
        return 'BEAST MODE! You\'ve gained ${absChange.toStringAsFixed(1)} kg in $days days! 💪';
      }
    }

    return 'Your dedication over $days days is inspiring! 🌟';
  }

  String _generateSummaryText(Map<String, dynamic> stats, int milestoneCount) {
    final days = stats['days_on_journey'] as int;
    final checkpoints = stats['total_checkpoints'] as int;

    if (days < 7) {
      return 'Your journey has just begun! $checkpoints checkpoints in $days days. Every legend starts somewhere. 🌅';
    } else if (days < 30) {
      return 'You\'re building momentum! $checkpoints checkpoints, $milestoneCount milestones in $days days. The foundation is strong! 💪';
    } else if (days < 90) {
      return 'The transformation is real! $days days of dedication, $checkpoints moments captured. You\'re unstoppable! 🔥';
    } else {
      return 'LEGENDARY! $days days on this journey, $checkpoints checkpoints, $milestoneCount milestones. You\'re an inspiration! 👑';
    }
  }

  String _calculateMotivationLevel(Map<String, dynamic> stats, int recentActivity) {
    final days = stats['days_on_journey'] as int;

    if (days < 7) {
      return 'building';
    } else if (recentActivity > 5 && days > 30) {
      return 'on_fire';
    } else if (recentActivity > 2) {
      return 'strong';
    } else {
      return 'steady';
    }
  }
}
