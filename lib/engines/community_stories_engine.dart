import '../services/database_helper_enhanced.dart';

/// Community Stories Engine - Inspire & Be Inspired! ✨
///
/// This creates a feed of transformation stories, struggles overcome,
/// and victories won. Real people, real stories, real inspiration.
class CommunityStoriesEngine {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int userId;

  CommunityStoriesEngine({required this.userId});

  /// Share transformation story
  Future<int> shareStory({
    required String storyTitle,
    required String storyContent,
    required String storyType, // 'transformation', 'milestone', 'struggle_overcome', 'inspiration'
    List<String>? photoUrls,
    Map<String, dynamic>? beforeAfterData,
    List<String>? tags,
    bool isAnonymous = false,
  }) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS community_stories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        story_title TEXT,
        story_content TEXT,
        story_type TEXT,
        photo_urls TEXT,
        before_after_data TEXT,
        tags TEXT,
        is_anonymous INTEGER,
        likes_count INTEGER DEFAULT 0,
        comments_count INTEGER DEFAULT 0,
        shares_count INTEGER DEFAULT 0,
        is_featured INTEGER DEFAULT 0,
        posted_date TEXT,
        created_at TEXT
      )
    ''');

    return await db.insert('community_stories', {
      'user_id': userId,
      'story_title': storyTitle,
      'story_content': storyContent,
      'story_type': storyType,
      'photo_urls': photoUrls?.join('|||') ?? '',
      'before_after_data': _encodeMap(beforeAfterData),
      'tags': tags?.join('|||') ?? '',
      'is_anonymous': isAnonymous ? 1 : 0,
      'likes_count': 0,
      'comments_count': 0,
      'shares_count': 0,
      'posted_date': DateTime.now().toIso8601String().split('T')[0],
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get community feed
  Future<List<Map<String, dynamic>>> getCommunityFeed({
    String? storyType,
    String? sortBy = 'recent', // 'recent', 'popular', 'trending'
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;

    try {
      String orderBy;
      switch (sortBy) {
        case 'popular':
          orderBy = 'likes_count DESC';
          break;
        case 'trending':
          orderBy = '(likes_count + comments_count + shares_count) DESC';
          break;
        default:
          orderBy = 'created_at DESC';
      }

      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (storyType != null) {
        whereClause += ' AND story_type = ?';
        whereArgs.add(storyType);
      }

      final results = await db.rawQuery('''
        SELECT
          cs.*,
          up.name as author_name,
          up.avatar_url as author_avatar
        FROM community_stories cs
        LEFT JOIN user_profile up ON cs.user_id = up.id
        WHERE $whereClause
        ORDER BY $orderBy
        LIMIT ? OFFSET ?
      ''', [...whereArgs, limit, offset]);

      return results.map((r) {
        return {
          ...r,
          'photo_urls': _decodeTags(r['photo_urls'] as String?),
          'tags': _decodeTags(r['tags'] as String?),
          'before_after_data': _decodeMap(r['before_after_data'] as String?),
          'time_ago': _getTimeAgo(r['created_at'] as String),
          'is_own_story': r['user_id'] == userId,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get featured stories (curated inspirational stories)
  Future<List<Map<String, dynamic>>> getFeaturedStories() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          cs.*,
          up.name as author_name,
          up.avatar_url as author_avatar
        FROM community_stories cs
        LEFT JOIN user_profile up ON cs.user_id = up.id
        WHERE cs.is_featured = 1
        ORDER BY cs.created_at DESC
        LIMIT 10
      ''');

      return results.map((r) {
        return {
          ...r,
          'photo_urls': _decodeTags(r['photo_urls'] as String?),
          'tags': _decodeTags(r['tags'] as String?),
          'time_ago': _getTimeAgo(r['created_at'] as String),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Like a story
  Future<void> likeStory(int storyId) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS story_likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER,
        user_id INTEGER,
        created_at TEXT,
        UNIQUE(story_id, user_id)
      )
    ''');

    try {
      await db.insert('story_likes', {
        'story_id': storyId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Increment like count
      await db.rawUpdate('''
        UPDATE community_stories
        SET likes_count = likes_count + 1
        WHERE id = ?
      ''', [storyId]);
    } catch (e) {
      // Already liked
    }
  }

  /// Unlike a story
  Future<void> unlikeStory(int storyId) async {
    final db = await _dbHelper.database;

    try {
      await db.delete(
        'story_likes',
        where: 'story_id = ? AND user_id = ?',
        whereArgs: [storyId, userId],
      );

      // Decrement like count
      await db.rawUpdate('''
        UPDATE community_stories
        SET likes_count = CASE WHEN likes_count > 0 THEN likes_count - 1 ELSE 0 END
        WHERE id = ?
      ''', [storyId]);
    } catch (e) {
      // Not liked
    }
  }

  /// Comment on a story
  Future<int> addComment(int storyId, String commentText) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS story_comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER,
        user_id INTEGER,
        comment_text TEXT,
        created_at TEXT
      )
    ''');

    final commentId = await db.insert('story_comments', {
      'story_id': storyId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Increment comment count
    await db.rawUpdate('''
      UPDATE community_stories
      SET comments_count = comments_count + 1
      WHERE id = ?
    ''', [storyId]);

    return commentId;
  }

  /// Get comments for a story
  Future<List<Map<String, dynamic>>> getStoryComments(int storyId) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          sc.*,
          up.name as author_name,
          up.avatar_url as author_avatar
        FROM story_comments sc
        LEFT JOIN user_profile up ON sc.user_id = up.id
        WHERE sc.story_id = ?
        ORDER BY sc.created_at DESC
      ''', [storyId]);

      return results.map((r) {
        return {
          ...r,
          'time_ago': _getTimeAgo(r['created_at'] as String),
          'is_own_comment': r['user_id'] == userId,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's own stories
  Future<List<Map<String, dynamic>>> getMyStories() async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'community_stories',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return results.map((r) {
        return {
          ...r,
          'photo_urls': _decodeTags(r['photo_urls'] as String?),
          'tags': _decodeTags(r['tags'] as String?),
          'before_after_data': _decodeMap(r['before_after_data'] as String?),
          'time_ago': _getTimeAgo(r['created_at'] as String),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search stories by tag
  Future<List<Map<String, dynamic>>> searchByTag(String tag) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.rawQuery('''
        SELECT
          cs.*,
          up.name as author_name,
          up.avatar_url as author_avatar
        FROM community_stories cs
        LEFT JOIN user_profile up ON cs.user_id = up.id
        WHERE cs.tags LIKE ?
        ORDER BY cs.created_at DESC
        LIMIT 50
      ''', ['%$tag%']);

      return results.map((r) {
        return {
          ...r,
          'photo_urls': _decodeTags(r['photo_urls'] as String?),
          'tags': _decodeTags(r['tags'] as String?),
          'time_ago': _getTimeAgo(r['created_at'] as String),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get daily inspiration story
  Future<Map<String, dynamic>?> getDailyInspiration() async {
    final db = await _dbHelper.database;

    try {
      // Get a high-engagement story
      final results = await db.rawQuery('''
        SELECT
          cs.*,
          up.name as author_name,
          up.avatar_url as author_avatar
        FROM community_stories cs
        LEFT JOIN user_profile up ON cs.user_id = up.id
        WHERE cs.story_type = 'transformation' OR cs.story_type = 'inspiration'
        ORDER BY (cs.likes_count + cs.comments_count) DESC
        LIMIT 1
      ''');

      if (results.isEmpty) return null;

      final story = results.first;

      return {
        ...story,
        'photo_urls': _decodeTags(story['photo_urls'] as String?),
        'tags': _decodeTags(story['tags'] as String?),
        'before_after_data': _decodeMap(story['before_after_data'] as String?),
      };
    } catch (e) {
      return null;
    }
  }

  /// Get trending tags
  Future<List<Map<String, dynamic>>> getTrendingTags({int limit = 10}) async {
    final db = await _dbHelper.database;

    try {
      final results = await db.query(
        'community_stories',
        columns: ['tags'],
        orderBy: 'created_at DESC',
        limit: 100,
      );

      // Count tag occurrences
      final Map<String, int> tagCounts = {};

      for (var result in results) {
        final tags = _decodeTags(result['tags'] as String?);
        for (var tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      // Sort and limit
      final sorted = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((e) => {
        'tag': e.key,
        'count': e.value,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Report story (moderation)
  Future<void> reportStory(int storyId, String reason) async {
    final db = await _dbHelper.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS story_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        story_id INTEGER,
        reported_by_user_id INTEGER,
        reason TEXT,
        created_at TEXT
      )
    ''');

    await db.insert('story_reports', {
      'story_id': storyId,
      'reported_by_user_id': userId,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get story engagement stats
  Future<Map<String, dynamic>> getStoryStats(int storyId) async {
    final db = await _dbHelper.database;

    try {
      final story = await db.query(
        'community_stories',
        where: 'id = ?',
        whereArgs: [storyId],
        limit: 1,
      );

      if (story.isEmpty) return {};

      final s = story.first;

      return {
        'likes': s['likes_count'] ?? 0,
        'comments': s['comments_count'] ?? 0,
        'shares': s['shares_count'] ?? 0,
        'total_engagement': (s['likes_count'] as int? ?? 0) +
            (s['comments_count'] as int? ?? 0) +
            (s['shares_count'] as int? ?? 0),
      };
    } catch (e) {
      return {};
    }
  }

  /// Generate story templates
  List<Map<String, dynamic>> getStoryTemplates() {
    return [
      {
        'type': 'transformation',
        'title': 'My Transformation Journey',
        'prompt': 'Share your before/after story! What changed? How do you feel?',
        'suggested_tags': ['transformation', 'journey', 'progress'],
      },
      {
        'type': 'milestone',
        'title': 'Milestone Achievement!',
        'prompt': 'What milestone did you hit? How does it feel to accomplish this?',
        'suggested_tags': ['milestone', 'achievement', 'victory'],
      },
      {
        'type': 'struggle_overcome',
        'title': 'Overcoming Obstacles',
        'prompt': 'What challenge did you face? How did you push through?',
        'suggested_tags': ['struggle', 'resilience', 'overcome'],
      },
      {
        'type': 'inspiration',
        'title': 'What Inspires Me',
        'prompt': 'What keeps you going? Share your inspiration with others!',
        'suggested_tags': ['inspiration', 'motivation', 'why'],
      },
    ];
  }

  /// Private helper methods
  List<String> _decodeTags(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];
    return encoded.split('|||');
  }

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
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
