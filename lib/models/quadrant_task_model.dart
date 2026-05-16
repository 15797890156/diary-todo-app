/// 四象限类型
enum QuadrantType {
  urgentImportant,      // 第一象限：紧急且重要
  notUrgentImportant,   // 第二象限：不紧急但重要
  urgentNotImportant,   // 第三象限：紧急但不重要
  notUrgentNotImportant, // 第四象限：不紧急不重要
}

/// 四象限任务模型
class QuadrantTaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final QuadrantType quadrant;
  final bool isCompleted;
  final DateTime? dueDate;
  final int priority; // 0-10，数值越大优先级越高
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuadrantTaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.quadrant,
    this.isCompleted = false,
    this.dueDate,
    this.priority = 5,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON Map 创建
  factory QuadrantTaskModel.fromJson(Map<String, dynamic> json) {
    return QuadrantTaskModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      quadrant: QuadrantType.values.firstWhere(
        (e) => e.name == json['quadrant'],
        orElse: () => QuadrantType.notUrgentNotImportant,
      ),
      isCompleted: json['isCompleted'] ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
      priority: json['priority'] ?? 5,
      icon: json['icon'],
      color: json['color'],
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
      'quadrant': quadrant.name,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'icon': icon,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  QuadrantTaskModel copyWith({
    String? title,
    String? description,
    QuadrantType? quadrant,
    bool? isCompleted,
    DateTime? dueDate,
    int? priority,
    String? icon,
    String? color,
    DateTime? updatedAt,
  }) {
    return QuadrantTaskModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      quadrant: quadrant ?? this.quadrant,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取象限标题
  String get quadrantTitle {
    switch (quadrant) {
      case QuadrantType.urgentImportant:
        return '紧急且重要';
      case QuadrantType.notUrgentImportant:
        return '重要不紧急';
      case QuadrantType.urgentNotImportant:
        return '紧急不重要';
      case QuadrantType.notUrgentNotImportant:
        return '不紧急不重要';
    }
  }

  /// 获取象限颜色
  String get quadrantColor {
    switch (quadrant) {
      case QuadrantType.urgentImportant:
        return '#F44336'; // 红色
      case QuadrantType.notUrgentImportant:
        return '#4CAF50'; // 绿色
      case QuadrantType.urgentNotImportant:
        return '#FF9800'; // 橙色
      case QuadrantType.notUrgentNotImportant:
        return '#9E9E9E'; // 灰色
    }
  }

  /// 获取象限图标
  String get quadrantIcon {
    switch (quadrant) {
      case QuadrantType.urgentImportant:
        return '🔥';
      case QuadrantType.notUrgentImportant:
        return '💎';
      case QuadrantType.urgentNotImportant:
        return '⏰';
      case QuadrantType.notUrgentNotImportant:
        return '☕';
    }
  }

  /// 获取象限建议
  String get quadrantAdvice {
    switch (quadrant) {
      case QuadrantType.urgentImportant:
        return '立即做';
      case QuadrantType.notUrgentImportant:
        return '计划做';
      case QuadrantType.urgentNotImportant:
        return '委托做';
      case QuadrantType.notUrgentNotImportant:
        return '少做';
    }
  }
}
