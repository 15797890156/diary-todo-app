/// 待办事项优先级
enum TodoPriority {
  low,    // 低优先级
  medium, // 中优先级
  high,   // 高优先级
}

/// 待办事项模型
/// 用于管理用户的待办任务
class TodoModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final TodoPriority priority;
  final String? icon; // 关联的图标名称
  final String? color; // 自定义颜色
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
    this.icon,
    this.color,
    required this.createdAt,
    this.completedAt,
    required this.updatedAt,
  });

  /// 从 JSON Map 创建待办模型
  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      priority: TodoPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      icon: json['icon'],
      color: json['color'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
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
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority.name,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  TodoModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    TodoPriority? priority,
    String? icon,
    String? color,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return TodoModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取优先级显示文本
  String get priorityText {
    switch (priority) {
      case TodoPriority.high:
        return '高';
      case TodoPriority.medium:
        return '中';
      case TodoPriority.low:
        return '低';
    }
  }

  /// 获取优先级颜色
  String get priorityColor {
    switch (priority) {
      case TodoPriority.high:
        return '#F44336';
      case TodoPriority.medium:
        return '#FF9800';
      case TodoPriority.low:
        return '#4CAF50';
    }
  }
}
