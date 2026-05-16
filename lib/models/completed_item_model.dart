/// 完成事项类型
enum CompletedItemType {
  todo,       // 待办事项
  timeRecord, // 时间记录
  book,       // 书籍阅读
  movie,      // 电影观看
  product,    // 产品追踪
  diary,      // 日记
}

/// 时间维度筛选
enum TimeFilter {
  all,    // 全部
  today,  // 今日
  week,   // 本周
  month,  // 本月
  year,   // 本年
}

/// 完成事项模型
/// 统一封装各种已完成事项的展示数据
class CompletedItemModel {
  final String id;
  final String userId;
  final CompletedItemType type;
  final String title;
  final String? subtitle;      // 副标题/描述
  final String? category;      // 分类（如书籍类型、电影类型等）
  final DateTime completedAt;  // 完成时间
  final String? icon;          // 图标
  final String? color;         // 颜色
  final Map<String, dynamic>? extraData; // 额外数据

  CompletedItemModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.subtitle,
    this.category,
    required this.completedAt,
    this.icon,
    this.color,
    this.extraData,
  });

  /// 从待办事项转换
  factory CompletedItemModel.fromTodo(dynamic todo) {
    return CompletedItemModel(
      id: todo.id,
      userId: todo.userId,
      type: CompletedItemType.todo,
      title: todo.title,
      subtitle: todo.description,
      category: '待办事项',
      completedAt: todo.completedAt ?? DateTime.now(),
      icon: todo.icon ?? '✅',
      color: todo.color,
      extraData: {
        'priority': todo.priority?.toString(),
      },
    );
  }

  /// 从时间记录转换
  factory CompletedItemModel.fromTimeRecord(dynamic record) {
    String categoryName = '事项';
    switch (record.type?.toString()) {
      case 'RecordType.routine':
        categoryName = '作息';
        break;
      case 'RecordType.focus':
        categoryName = '专注';
        break;
      case 'RecordType.event':
        categoryName = '事项';
        break;
    }

    return CompletedItemModel(
      id: record.id,
      userId: record.userId,
      type: CompletedItemType.timeRecord,
      title: record.title,
      subtitle: record.formattedDuration,
      category: categoryName,
      completedAt: record.endTime ?? record.startTime,
      icon: record.typeIcon,
      color: record.color,
      extraData: {
        'duration': record.duration?.inSeconds,
        'recordType': record.type?.toString(),
      },
    );
  }

  /// 从产品追踪转换
  factory CompletedItemModel.fromProduct(dynamic product) {
    return CompletedItemModel(
      id: product.id,
      userId: product.userId,
      type: CompletedItemType.product,
      title: product.name,
      subtitle: product.description,
      category: _getProductTypeName(product.type),
      completedAt: product.updatedAt,
      icon: product.icon ?? '📦',
      extraData: {
        'progress': product.currentProgress,
        'target': product.targetProgress,
        'unit': product.unit,
        'checkIns': product.totalCheckIns,
      },
    );
  }

  /// 从日记转换
  factory CompletedItemModel.fromDiary(dynamic diary) {
    return CompletedItemModel(
      id: diary.id,
      userId: diary.userId,
      type: CompletedItemType.diary,
      title: diary.title ?? '无标题日记',
      subtitle: diary.content != null && diary.content!.length > 50
          ? '${diary.content!.substring(0, 50)}...'
          : diary.content,
      category: '日记',
      completedAt: diary.createdAt,
      icon: diary.moodIcon ?? '📝',
      extraData: {
        'mood': diary.mood,
        'imageCount': diary.images?.length ?? 0,
      },
    );
  }

  /// 获取类型图标
  String get typeIcon {
    switch (type) {
      case CompletedItemType.todo:
        return icon ?? '✅';
      case CompletedItemType.timeRecord:
        return icon ?? '⏱️';
      case CompletedItemType.book:
        return icon ?? '📚';
      case CompletedItemType.movie:
        return icon ?? '🎬';
      case CompletedItemType.product:
        return icon ?? '📦';
      case CompletedItemType.diary:
        return icon ?? '📝';
    }
  }

  /// 获取类型名称
  String get typeName {
    switch (type) {
      case CompletedItemType.todo:
        return '待办';
      case CompletedItemType.timeRecord:
        return '时间记录';
      case CompletedItemType.book:
        return '书籍';
      case CompletedItemType.movie:
        return '电影';
      case CompletedItemType.product:
        return '产品';
      case CompletedItemType.diary:
        return '日记';
    }
  }

  /// 获取类型颜色
  String get typeColor {
    switch (type) {
      case CompletedItemType.todo:
        return '#4CAF50';
      case CompletedItemType.timeRecord:
        return '#2196F3';
      case CompletedItemType.book:
        return '#9C27B0';
      case CompletedItemType.movie:
        return '#FF5722';
      case CompletedItemType.product:
        return '#795548';
      case CompletedItemType.diary:
        return '#607D8B';
    }
  }

  /// 检查是否在指定时间筛选范围内
  bool isInTimeFilter(TimeFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );

    switch (filter) {
      case TimeFilter.all:
        return true;
      case TimeFilter.today:
        return itemDate.isAtSameMomentAs(today);
      case TimeFilter.week:
        // 本周（周一到周日）
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return !itemDate.isBefore(weekStart) && !itemDate.isAfter(weekEnd);
      case TimeFilter.month:
        return completedAt.year == now.year && completedAt.month == now.month;
      case TimeFilter.year:
        return completedAt.year == now.year;
    }
  }

  /// 获取产品类型名称
  static String _getProductTypeName(dynamic type) {
    final typeStr = type.toString();
    if (typeStr.contains('consumable')) return '消耗品';
    if (typeStr.contains('goal')) return '目标';
    if (typeStr.contains('subscription')) return '订阅';
    if (typeStr.contains('habit')) return '习惯';
    return '产品';
  }
}

/// 完成事项分类统计
class CompletedCategoryStats {
  final CompletedItemType type;
  final String name;
  final String icon;
  final int count;
  final List<CompletedItemModel> items;

  CompletedCategoryStats({
    required this.type,
    required this.name,
    required this.icon,
    required this.count,
    required this.items,
  });
}

/// 完成事项汇总统计
class CompletedSummary {
  final int totalCount;
  final int todayCount;
  final int weekCount;
  final int monthCount;
  final Map<CompletedItemType, int> countByType;
  final List<CompletedCategoryStats> categories;

  CompletedSummary({
    required this.totalCount,
    required this.todayCount,
    required this.weekCount,
    required this.monthCount,
    required this.countByType,
    required this.categories,
  });

  factory CompletedSummary.empty() {
    return CompletedSummary(
      totalCount: 0,
      todayCount: 0,
      weekCount: 0,
      monthCount: 0,
      countByType: {},
      categories: [],
    );
  }
}
