/// 心情类型
enum MoodType {
  happy,     // 开心 😊
  excited,   // 兴奋 🎉
  calm,      // 平静 😌
  sad,       // 难过 😢
  angry,     // 生气 😠
  tired,     // 疲惫 😴
  love,      // 爱心 ❤️
  thinking,  // 思考 🤔
}

/// 日记模型
/// 类似私人朋友圈，记录每日心情和重要时刻
class DiaryModel {
  final String id;
  final String userId;
  final String content;
  final List<String> images; // 图片 URL 列表
  final MoodType? mood;
  final String? location;
  final String? weather;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryModel({
    required this.id,
    required this.userId,
    required this.content,
    this.images = const [],
    this.mood,
    this.location,
    this.weather,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON Map 创建日记模型
  factory DiaryModel.fromJson(Map<String, dynamic> json) {
    return DiaryModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      mood: json['mood'] != null
          ? MoodType.values.firstWhere(
              (e) => e.name == json['mood'],
              orElse: () => MoodType.calm,
            )
          : null,
      location: json['location'],
      weather: json['weather'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'images': images,
      'mood': mood?.name,
      'location': location,
      'weather': weather,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  DiaryModel copyWith({
    String? content,
    List<String>? images,
    MoodType? mood,
    String? location,
    String? weather,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return DiaryModel(
      id: id,
      userId: userId,
      content: content ?? this.content,
      images: images ?? this.images,
      mood: mood ?? this.mood,
      location: location ?? this.location,
      weather: weather ?? this.weather,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取心情表情
  String get moodEmoji {
    switch (mood) {
      case MoodType.happy:
        return '😊';
      case MoodType.excited:
        return '🎉';
      case MoodType.calm:
        return '😌';
      case MoodType.sad:
        return '😢';
      case MoodType.angry:
        return '😠';
      case MoodType.tired:
        return '😴';
      case MoodType.love:
        return '❤️';
      case MoodType.thinking:
        return '🤔';
      default:
        return '📝';
    }
  }

  /// 获取心情文本
  String get moodText {
    switch (mood) {
      case MoodType.happy:
        return '开心';
      case MoodType.excited:
        return '兴奋';
      case MoodType.calm:
        return '平静';
      case MoodType.sad:
        return '难过';
      case MoodType.angry:
        return '生气';
      case MoodType.tired:
        return '疲惫';
      case MoodType.love:
        return '爱心';
      case MoodType.thinking:
        return '思考';
      default:
        return '记录';
    }
  }
}
