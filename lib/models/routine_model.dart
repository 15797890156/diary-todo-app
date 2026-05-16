/// 作息类型
enum RoutineType {
  sleep,      // 睡眠
  wakeUp,     // 起床
  work,       // 工作
  rest,       // 休息
  exercise,   // 运动
  meal,       // 用餐
  study,      // 学习
  entertainment, // 娱乐
  other,      // 其他
}

/// 作息记录模型
/// 用于记录每日作息时间
class RoutineModel {
  final String id;
  final String userId;
  final RoutineType type;
  final String? customName;     // 自定义名称（当type为other时使用）
  final DateTime startTime;     // 开始时间
  final DateTime? endTime;      // 结束时间
  final String? color;          // 自定义颜色
  final String? icon;           // 图标
  final bool isRecurring;       // 是否重复
  final List<int>? weekDays;    // 重复的星期（1-7）
  final DateTime createdAt;

  RoutineModel({
    required this.id,
    required this.userId,
    required this.type,
    this.customName,
    required this.startTime,
    this.endTime,
    this.color,
    this.icon,
    this.isRecurring = false,
    this.weekDays,
    required this.createdAt,
  });

  /// 从 JSON Map 创建
  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: RoutineType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RoutineType.other,
      ),
      customName: json['customName'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      color: json['color'],
      icon: json['icon'],
      isRecurring: json['isRecurring'] ?? false,
      weekDays: json['weekDays'] != null
          ? List<int>.from(json['weekDays'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'customName': customName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'color': color,
      'icon': icon,
      'isRecurring': isRecurring,
      'weekDays': weekDays,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  RoutineModel copyWith({
    RoutineType? type,
    String? customName,
    DateTime? startTime,
    DateTime? endTime,
    String? color,
    String? icon,
    bool? isRecurring,
    List<int>? weekDays,
  }) {
    return RoutineModel(
      id: id,
      userId: userId,
      type: type ?? this.type,
      customName: customName ?? this.customName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isRecurring: isRecurring ?? this.isRecurring,
      weekDays: weekDays ?? this.weekDays,
      createdAt: createdAt,
    );
  }

  /// 获取类型图标
  String get typeIcon {
    switch (type) {
      case RoutineType.sleep:
        return icon ?? '😴';
      case RoutineType.wakeUp:
        return icon ?? '⏰';
      case RoutineType.work:
        return icon ?? '💼';
      case RoutineType.rest:
        return icon ?? '☕';
      case RoutineType.exercise:
        return icon ?? '🏃';
      case RoutineType.meal:
        return icon ?? '🍽️';
      case RoutineType.study:
        return icon ?? '📖';
      case RoutineType.entertainment:
        return icon ?? '🎮';
      case RoutineType.other:
        return icon ?? '📌';
    }
  }

  /// 获取类型名称
  String get typeName {
    switch (type) {
      case RoutineType.sleep:
        return '睡眠';
      case RoutineType.wakeUp:
        return '起床';
      case RoutineType.work:
        return '工作';
      case RoutineType.rest:
        return '休息';
      case RoutineType.exercise:
        return '运动';
      case RoutineType.meal:
        return '用餐';
      case RoutineType.study:
        return '学习';
      case RoutineType.entertainment:
        return '娱乐';
      case RoutineType.other:
        return customName ?? '其他';
    }
  }

  /// 获取类型颜色
  String get typeColor {
    switch (type) {
      case RoutineType.sleep:
        return color ?? '#3F51B5';
      case RoutineType.wakeUp:
        return color ?? '#FF9800';
      case RoutineType.work:
        return color ?? '#F44336';
      case RoutineType.rest:
        return color ?? '#4CAF50';
      case RoutineType.exercise:
        return color ?? '#2196F3';
      case RoutineType.meal:
        return color ?? '#FF5722';
      case RoutineType.study:
        return color ?? '#9C27B0';
      case RoutineType.entertainment:
        return color ?? '#E91E63';
      case RoutineType.other:
        return color ?? '#607D8B';
    }
  }

  /// 获取显示名称
  String get displayName {
    if (type == RoutineType.other && customName != null) {
      return customName!;
    }
    return typeName;
  }

  /// 获取时长
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// 格式化时长
  String get formattedDuration {
    final d = duration;
    if (d == null) return '进行中';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}小时${minutes > 0 ? '${minutes}分' : ''}';
    }
    return '${minutes}分钟';
  }

  /// 格式化开始时间
  String get formattedStartTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化结束时间
  String get formattedEndTime {
    if (endTime == null) return '--:--';
    return '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
  }
}
