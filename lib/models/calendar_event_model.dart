/// 日历事件类型
enum CalendarEventType {
  todo,     // 待办事项
  diary,    // 日记
  event,    // 自定义事件
  reminder, // 提醒
}

/// 日历事件模型
/// 用于在日历上显示各种事件标记
class CalendarEventModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final CalendarEventType type;
  final String? relatedId; // 关联的待办/日记 ID
  final String color;
  final String? icon;
  final bool isAllDay;
  final DateTime createdAt;

  CalendarEventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    this.type = CalendarEventType.event,
    this.relatedId,
    this.color = '#4CAF50',
    this.icon,
    this.isAllDay = false,
    required this.createdAt,
  });

  /// 从 JSON Map 创建日历事件模型
  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      type: CalendarEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CalendarEventType.event,
      ),
      relatedId: json['relatedId'],
      color: json['color'] ?? '#4CAF50',
      icon: json['icon'],
      isAllDay: json['isAllDay'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type.name,
      'relatedId': relatedId,
      'color': color,
      'icon': icon,
      'isAllDay': isAllDay,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  CalendarEventModel copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    CalendarEventType? type,
    String? color,
    String? icon,
    bool? isAllDay,
  }) {
    return CalendarEventModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      relatedId: relatedId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isAllDay: isAllDay ?? this.isAllDay,
      createdAt: createdAt,
    );
  }

  /// 获取事件类型图标
  String get typeIcon {
    switch (type) {
      case CalendarEventType.todo:
        return '✅';
      case CalendarEventType.diary:
        return '📝';
      case CalendarEventType.event:
        return '📌';
      case CalendarEventType.reminder:
        return '⏰';
    }
  }

  /// 获取事件类型文本
  String get typeText {
    switch (type) {
      case CalendarEventType.todo:
        return '待办';
      case CalendarEventType.diary:
        return '日记';
      case CalendarEventType.event:
        return '事件';
      case CalendarEventType.reminder:
        return '提醒';
    }
  }
}
