/// 时间归档记录模型
/// 按事项 + 日期维度，存储每日累计时长
/// 支持按月/年聚合查询
class TimeArchiveModel {
  final String id;
  final String userId;
  final String itemName;       // 事项名称（如"学习英语"、"跑步"）
  final String itemIcon;       // 事项图标
  final DateTime date;         // 归档日期
  final int totalSeconds;      // 当日累计秒数
  final int recordCount;       // 当日记录条数
  final String? sourceRecordId;// 来源记录 ID（关联 time_records）
  final DateTime createdAt;

  TimeArchiveModel({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.itemIcon,
    required this.date,
    required this.totalSeconds,
    this.recordCount = 1,
    this.sourceRecordId,
    required this.createdAt,
  });

  /// 从 JSON Map 创建
  factory TimeArchiveModel.fromJson(Map<String, dynamic> json) {
    return TimeArchiveModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      itemName: json['itemName'] ?? '',
      itemIcon: json['itemIcon'] ?? '📌',
      date: DateTime.parse(json['date']),
      totalSeconds: json['totalSeconds'] ?? 0,
      recordCount: json['recordCount'] ?? 1,
      sourceRecordId: json['sourceRecordId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'itemName': itemName,
      'itemIcon': itemIcon,
      'date': date.toIso8601String(),
      'totalSeconds': totalSeconds,
      'recordCount': recordCount,
      'sourceRecordId': sourceRecordId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 获取格式化时长
  String get formattedDuration {
    final d = Duration(seconds: totalSeconds);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h${m > 0 ? '${m}m' : ''}';
    if (m > 0) return '${m}m${s > 0 ? '${s}s' : ''}';
    return '${s}s';
  }

  /// 获取格式化时长（详细）
  String get formattedDurationFull {
    final d = Duration(seconds: totalSeconds);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '$h小时$m分钟';
    if (h > 0) return '$h小时';
    if (m > 0) return '$m分钟';
    return '${d.inSeconds}秒';
  }

  TimeArchiveModel copyWith({
    int? totalSeconds,
    int? recordCount,
  }) {
    return TimeArchiveModel(
      id: id,
      userId: userId,
      itemName: itemName,
      itemIcon: itemIcon,
      date: date,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      recordCount: recordCount ?? this.recordCount,
      sourceRecordId: sourceRecordId,
      createdAt: createdAt,
    );
  }
}

/// 时间归档聚合结果
/// 用于月/年维度的统计展示
class TimeArchiveSummary {
  final String itemName;
  final String itemIcon;
  final int totalSeconds;      // 周期内总秒数
  final int activeDays;        // 有记录的天数
  final int totalRecords;      // 总记录条数
  final List<TimeArchiveModel> dailyDetails; // 每日明细

  TimeArchiveSummary({
    required this.itemName,
    required this.itemIcon,
    required this.totalSeconds,
    required this.activeDays,
    required this.totalRecords,
    required this.dailyDetails,
  });

  /// 平均每日时长（秒）
  int get avgDailySeconds => activeDays > 0 ? totalSeconds ~/ activeDays : 0;

  /// 格式化总时长
  String get formattedTotal {
    final d = Duration(seconds: totalSeconds);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h小时${m > 0 ? '$m分' : ''}';
    return '$m分钟';
  }

  /// 格式化平均时长
  String get formattedAvg {
    final d = Duration(seconds: avgDailySeconds);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h小时${m > 0 ? '$m分' : ''}';
    return '$m分钟';
  }

  /// 完成率（有记录天数 / 周期总天数）
  double completionRate(int totalDaysInPeriod) {
    if (totalDaysInPeriod <= 0) return 0;
    return activeDays / totalDaysInPeriod;
  }
}
