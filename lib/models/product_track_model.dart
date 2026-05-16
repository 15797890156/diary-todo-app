/// 产品追踪类型
enum ProductTrackType {
  consumable,   // 消耗品：护肤品、保健品等（按次数/容量）
  goal,         // 目标进度：读书页数、课程进度等
  subscription, // 订阅服务：会员、周期性服务
  habit,        // 习惯养成：早起、冥想、喝水等（打卡天数）
}

/// 产品追踪状态
enum ProductTrackStatus {
  active,       // 使用中
  paused,       // 暂停
  completed,    // 已完成
  abandoned,    // 已放弃
}

/// 长期主义产品追踪模型
/// 记录产品的使用消耗次数或进度，以及寿命周期
class ProductTrackModel {
  final String id;
  final String userId;
  final String name;             // 产品名称
  final String? description;     // 描述
  final String? icon;            // 图标
  final String? imageUrl;        // 产品图片
  final ProductTrackType type;   // 追踪类型
  final ProductTrackStatus status; // 状态

  // ===== 进度相关 =====
  final double currentProgress;  // 当前进度（次数/页数/毫升等）
  final double targetProgress;   // 目标进度
  final String? unit;            // 单位（次、页、ml、天等）

  // ===== 寿命周期 =====
  final DateTime startDate;      // 开始使用日期
  final DateTime? endDate;       // 结束日期（完成/放弃时记录）
  final int? expectedDays;       // 预计使用天数（可选）

  // ===== 统计 =====
  final int totalCheckIns;       // 总打卡/使用次数
  final int currentStreak;       // 当前连续天数
  final int longestStreak;       // 最长连续天数
  final DateTime? lastCheckInAt; // 最后一次打卡时间

  // ===== 提醒 =====
  final String? reminderTime;    // 每日提醒时间（HH:mm）
  final bool reminderEnabled;    // 是否开启提醒

  final DateTime createdAt;
  final DateTime updatedAt;

  ProductTrackModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.icon,
    this.imageUrl,
    this.type = ProductTrackType.consumable,
    this.status = ProductTrackStatus.active,
    this.currentProgress = 0,
    this.targetProgress = 100,
    this.unit,
    required this.startDate,
    this.endDate,
    this.expectedDays,
    this.totalCheckIns = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckInAt,
    this.reminderTime,
    this.reminderEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON Map 创建
  factory ProductTrackModel.fromJson(Map<String, dynamic> json) {
    return ProductTrackModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      imageUrl: json['imageUrl'],
      type: ProductTrackType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ProductTrackType.consumable,
      ),
      status: ProductTrackStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductTrackStatus.active,
      ),
      currentProgress: (json['currentProgress'] ?? 0).toDouble(),
      targetProgress: (json['targetProgress'] ?? 100).toDouble(),
      unit: json['unit'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      expectedDays: json['expectedDays'],
      totalCheckIns: json['totalCheckIns'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastCheckInAt: json['lastCheckInAt'] != null
          ? DateTime.parse(json['lastCheckInAt'])
          : null,
      reminderTime: json['reminderTime'],
      reminderEnabled: json['reminderEnabled'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'icon': icon,
      'imageUrl': imageUrl,
      'type': type.name,
      'status': status.name,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'unit': unit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'expectedDays': expectedDays,
      'totalCheckIns': totalCheckIns,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCheckInAt': lastCheckInAt?.toIso8601String(),
      'reminderTime': reminderTime,
      'reminderEnabled': reminderEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ProductTrackModel copyWith({
    String? name,
    String? description,
    String? icon,
    String? imageUrl,
    ProductTrackType? type,
    ProductTrackStatus? status,
    double? currentProgress,
    double? targetProgress,
    String? unit,
    DateTime? endDate,
    int? expectedDays,
    int? totalCheckIns,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCheckInAt,
    String? reminderTime,
    bool? reminderEnabled,
    DateTime? updatedAt,
  }) {
    return ProductTrackModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
      unit: unit ?? this.unit,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      expectedDays: expectedDays ?? this.expectedDays,
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== 计算属性 ====================

  /// 进度百分比 (0.0 ~ 1.0)
  double get progressPercent {
    if (targetProgress <= 0) return 0;
    return (currentProgress / targetProgress).clamp(0.0, 1.0);
  }

  /// 剩余进度
  double get remainingProgress {
    return (targetProgress - currentProgress).clamp(0, double.infinity);
  }

  /// 已坚持天数
  int get persistedDays {
    final end = endDate ?? DateTime.now();
    return end.difference(startDate).inDays + 1;
  }

  /// 寿命周期文本
  String get lifespanText {
    final days = persistedDays;
    if (days < 30) return '$days天';
    if (days < 365) {
      final m = days ~/ 30;
      final d = days % 30;
      return d > 0 ? '$m个月$d天' : '$m个月';
    }
    final y = days ~/ 365;
    final m = (days % 365) ~/ 30;
    return m > 0 ? '$y年$m个月' : '$y年';
  }

  /// 预计完成日期
  DateTime? get estimatedCompletionDate {
    if (expectedDays == null) return null;
    return startDate.add(Duration(days: expectedDays!));
  }

  /// 是否已过期（超过预计天数）
  bool get isOverdue {
    final est = estimatedCompletionDate;
    if (est == null) return false;
    return DateTime.now().isAfter(est) && status == ProductTrackStatus.active;
  }

  /// 类型图标
  String get typeIcon {
    switch (type) {
      case ProductTrackType.consumable: return '🧴';
      case ProductTrackType.goal: return '🎯';
      case ProductTrackType.subscription: return '💳';
      case ProductTrackType.habit: return '🔥';
    }
  }

  /// 类型名称
  String get typeName {
    switch (type) {
      case ProductTrackType.consumable: return '消耗品';
      case ProductTrackType.goal: return '目标进度';
      case ProductTrackType.subscription: return '订阅服务';
      case ProductTrackType.habit: return '习惯养成';
    }
  }

  /// 状态名称
  String get statusName {
    switch (status) {
      case ProductTrackStatus.active: return '进行中';
      case ProductTrackStatus.paused: return '已暂停';
      case ProductTrackStatus.completed: return '已完成';
      case ProductTrackStatus.abandoned: return '已放弃';
    }
  }

  /// 状态颜色
  String get statusColor {
    switch (status) {
      case ProductTrackStatus.active: return '#4CAF50';
      case ProductTrackStatus.paused: return '#FF9800';
      case ProductTrackStatus.completed: return '#2196F3';
      case ProductTrackStatus.abandoned: return '#9E9E9E';
    }
  }

  /// 格式化进度显示
  String get formattedProgress {
    return '${currentProgress.toInt()}${unit ?? ''}/${targetProgress.toInt()}${unit ?? ''}';
  }

  /// 格式化进度百分比
  String get formattedPercent {
    return '${(progressPercent * 100).toStringAsFixed(1)}%';
  }
}

/// 产品每日打卡记录
class ProductCheckInModel {
  final String id;
  final String productId;
  final String userId;
  final DateTime date;           // 打卡日期
  final double increment;        // 当日增量（次数/页数等）
  final String? note;            // 备注
  final DateTime createdAt;

  ProductCheckInModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.date,
    this.increment = 1,
    this.note,
    required this.createdAt,
  });

  /// 从 JSON Map 创建
  factory ProductCheckInModel.fromJson(Map<String, dynamic> json) {
    return ProductCheckInModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date']),
      increment: (json['increment'] ?? 1).toDouble(),
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'date': date.toIso8601String(),
      'increment': increment,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
