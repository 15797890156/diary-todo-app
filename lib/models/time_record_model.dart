/// 记录类型
enum RecordType {
  routine,    // 作息
  focus,      // 专注
  event,      // 普通事项
}

/// 时间记录模型
/// 用于记录一天中的各项活动及其时长
class TimeRecordModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime date;           // 所属日期
  final DateTime startTime;      // 开始时间
  final DateTime? endTime;       // 结束时间
  final Duration? duration;      // 记录时长
  final RecordType type;         // 记录类型
  final String? icon;            // 图标
  final String? color;           // 颜色
  final bool isTimerRunning;     // 是否正在计时
  final DateTime? timerStartedAt; // 计时开始时间
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeRecordModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    this.duration,
    this.type = RecordType.event,
    this.icon,
    this.color,
    this.isTimerRunning = false,
    this.timerStartedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON Map 创建
  factory TimeRecordModel.fromJson(Map<String, dynamic> json) {
    return TimeRecordModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      type: RecordType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RecordType.event,
      ),
      icon: json['icon'],
      color: json['color'],
      isTimerRunning: json['isTimerRunning'] ?? false,
      timerStartedAt: json['timerStartedAt'] != null
          ? DateTime.parse(json['timerStartedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inSeconds,
      'type': type.name,
      'icon': icon,
      'color': color,
      'isTimerRunning': isTimerRunning,
      'timerStartedAt': timerStartedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  TimeRecordModel copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    RecordType? type,
    String? icon,
    String? color,
    bool? isTimerRunning,
    DateTime? timerStartedAt,
    DateTime? updatedAt,
  }) {
    return TimeRecordModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      timerStartedAt: timerStartedAt ?? this.timerStartedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取当前计时时长
  Duration getCurrentDuration() {
    if (!isTimerRunning || timerStartedAt == null) {
      return duration ?? Duration.zero;
    }
    final elapsed = DateTime.now().difference(timerStartedAt!);
    return (duration ?? Duration.zero) + elapsed;
  }

  /// 格式化时长显示
  String get formattedDuration {
    final d = getCurrentDuration();
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) {
      return '${hours}小时${minutes > 0 ? '${minutes}分' : ''}';
    }
    return '${minutes}分钟';
  }

  /// 获取类型图标
  String get typeIcon {
    switch (type) {
      case RecordType.routine:
        return icon ?? '🕐';
      case RecordType.focus:
        return icon ?? '🎯';
      case RecordType.event:
        return icon ?? '📌';
    }
  }

  /// 获取类型标签
  String get typeLabel {
    switch (type) {
      case RecordType.routine:
        return '作息';
      case RecordType.focus:
        return '专注';
      case RecordType.event:
        return '事项';
    }
  }
}
