import 'package:health/health.dart';
import '../models/time_record_model.dart';

/// 睡眠时段数据
class SleepSession {
  final DateTime startTime;
  final DateTime endTime;
  final int totalMinutes;
  final int deepMinutes;
  final int remMinutes;
  final int lightMinutes;

  SleepSession({
    required this.startTime,
    required this.endTime,
    required this.totalMinutes,
    required this.deepMinutes,
    required this.remMinutes,
    required this.lightMinutes,
  });

  /// 睡眠质量评分（0-100）
  int get qualityScore {
    if (totalMinutes == 0) return 0;
    // 深睡占比越高分数越高
    final deepRatio = deepMinutes / totalMinutes;
    // REM占比适中最好（20-25%）
    final remRatio = remMinutes / totalMinutes;
    final remScore = remRatio >= 0.15 && remRatio <= 0.30 ? 30 : 15;
    return (deepRatio * 50 + remScore + 20).clamp(0, 100).round();
  }

  /// 质量描述
  String get qualityLabel {
    final score = qualityScore;
    if (score >= 80) return '优秀';
    if (score >= 60) return '良好';
    if (score >= 40) return '一般';
    return '较差';
  }

  /// 格式化时长
  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '$hours小时${minutes > 0 ? '$minutes分' : ''}';
    }
    return '$minutes分钟';
  }
}

/// 运动时段数据
class WorkoutSession {
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final double calories;
  final double distance; // 公里
  final int durationMinutes;

  WorkoutSession({
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.calories,
    required this.distance,
    required this.durationMinutes,
  });

  /// 格式化时长
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '$hours小时${minutes > 0 ? '$minutes分' : ''}';
    }
    return '$minutes分钟';
  }

  /// 格式化距离
  String get formattedDistance {
    if (distance <= 0) return '';
    return '${distance.toStringAsFixed(1)}公里';
  }
}

/// 健康数据同步服务
/// 通过 Apple HealthKit / Google Fit 读取手环/手表的睡眠和运动数据
/// 并转换为 TimeRecordModel 写入作息模块
class HealthDataService {
  final HealthFactory _health = HealthFactory();

  // ==================== 权限管理 ====================

  /// 需要请求的健康数据类型
  static final List<HealthDataType> _dataTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.STEPS,
    HealthDataType.WORKOUT,
  ];

  /// 请求健康数据读取权限
  /// 返回 true 表示用户授权成功
  Future<bool> requestAuthorization() async {
    try {
      final permissions = _dataTypes.map((_) => HealthDataAccess.READ).toList();
      final hasPermissions = await _health.requestAuthorization(
        _dataTypes,
        permissions: permissions,
      );
      return hasPermissions;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否已授权
  Future<bool> checkAuthorization() async {
    try {
      final hasPermissions = await _health.hasPermissions(
        _dataTypes,
        permissions: _dataTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      return hasPermissions;
    } catch (e) {
      return false;
    }
  }

  // ==================== 睡眠数据 ====================

  /// 获取指定日期的睡眠数据
  Future<List<SleepSession>> getSleepData(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final sleepTypes = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_IN_BED,
      ];

      final healthData = await _health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: startOfDay,
        endTime: endOfDay,
      );

      return _parseSleepSessions(healthData);
    } catch (e) {
      return [];
    }
  }

  /// 获取指定日期范围的睡眠数据
  Future<List<SleepSession>> getSleepDataRange(DateTime start, DateTime end) async {
    try {
      final sleepTypes = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_IN_BED,
      ];

      final healthData = await _health.getHealthDataFromTypes(
        types: sleepTypes,
        startTime: start,
        endTime: end,
      );

      return _parseSleepSessions(healthData);
    } catch (e) {
      return [];
    }
  }

  /// 解析原始健康数据为睡眠时段
  List<SleepSession> _parseSleepSessions(List<HealthDataPoint> dataPoints) {
    if (dataPoints.isEmpty) return [];

    dataPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    final sessions = <SleepSession>[];
    DateTime? sessionStart;
    DateTime? sessionEnd;
    int deepMinutes = 0;
    int remMinutes = 0;
    int lightMinutes = 0;

    for (final point in dataPoints) {
      final type = point.type;
      final start = point.dateFrom;
      final end = point.dateTo;
      final duration = end.difference(start).inMinutes;

      if (type == HealthDataType.SLEEP_IN_BED) {
        if (sessionStart == null) sessionStart = start;
      } else if (type == HealthDataType.SLEEP_ASLEEP) {
        if (sessionStart == null) sessionStart = start;
        lightMinutes += duration;
        sessionEnd = end;
      } else if (type == HealthDataType.SLEEP_DEEP) {
        if (sessionStart == null) sessionStart = start;
        deepMinutes += duration;
        sessionEnd = end;
      } else if (type == HealthDataType.SLEEP_REM) {
        if (sessionStart == null) sessionStart = start;
        remMinutes += duration;
        sessionEnd = end;
      } else if (type == HealthDataType.SLEEP_AWAKE) {
        // 清醒间隔超过60分钟视为不同睡眠时段
        if (sessionStart != null && duration > 60) {
          sessions.add(SleepSession(
            startTime: sessionStart!,
            endTime: sessionEnd ?? start,
            totalMinutes: (sessionEnd ?? start).difference(sessionStart!).inMinutes,
            deepMinutes: deepMinutes,
            remMinutes: remMinutes,
            lightMinutes: lightMinutes,
          ));
          sessionStart = null;
          sessionEnd = null;
          deepMinutes = 0;
          remMinutes = 0;
          lightMinutes = 0;
        }
      }
    }

    // 保存最后一个时段
    if (sessionStart != null && sessionEnd != null) {
      sessions.add(SleepSession(
        startTime: sessionStart,
        endTime: sessionEnd,
        totalMinutes: sessionEnd.difference(sessionStart).inMinutes,
        deepMinutes: deepMinutes,
        remMinutes: remMinutes,
        lightMinutes: lightMinutes,
      ));
    }

    return sessions;
  }

  // ==================== 运动数据 ====================

  /// 获取指定日期的步数
  Future<int> getSteps(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      int totalSteps = 0;
      for (final point in healthData) {
        totalSteps += (point.value as num).toInt();
      }
      return totalSteps;
    } catch (e) {
      return 0;
    }
  }

  /// 获取指定日期的运动记录
  Future<List<WorkoutSession>> getWorkouts(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      return healthData.map((point) {
        final metadata = point.metadata;
        return WorkoutSession(
          startTime: point.dateFrom,
          endTime: point.dateTo,
          type: _parseWorkoutType(metadata),
          calories: metadata?['HKMetadataKeyEnergyBurned'] as double? ?? 0,
          distance: metadata?['HKMetadataKeyDistance'] as double? ?? 0,
          durationMinutes: point.dateTo.difference(point.dateFrom).inMinutes,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// 解析运动类型
  String _parseWorkoutType(Map<String, dynamic>? metadata) {
    if (metadata == null) return '运动';
    final typeValue = metadata['HKWorkoutActivityType'] ??
        metadata['workoutType'] ?? '';
    final typeStr = typeValue.toString().toLowerCase();

    if (typeStr.contains('run') || typeStr.contains('running')) return '跑步';
    if (typeStr.contains('walk') || typeStr.contains('walking')) return '步行';
    if (typeStr.contains('cycl') || typeStr.contains('bike')) return '骑行';
    if (typeStr.contains('swim')) return '游泳';
    if (typeStr.contains('yoga')) return '瑜伽';
    if (typeStr.contains('strength') || typeStr.contains('gym')) return '力量训练';
    if (typeStr.contains('hiit')) return 'HIIT';
    if (typeStr.contains('dance')) return '舞蹈';
    if (typeStr.contains('hike') || typeStr.contains('hiking')) return '徒步';
    if (typeStr.contains('basketball')) return '篮球';
    if (typeStr.contains('football') || typeStr.contains('soccer')) return '足球';
    if (typeStr.contains('tennis')) return '网球';
    if (typeStr.contains('badminton')) return '羽毛球';
    return '运动';
  }

  // ==================== 数据转换 ====================

  /// 将睡眠数据转换为时间记录模型列表
  List<TimeRecordModel> sleepToTimeRecords({
    required List<SleepSession> sessions,
    required String userId,
    required DateTime date,
  }) {
    return sessions.map((session) {
      return TimeRecordModel(
        id: '',
        userId: userId,
        title: _getSleepTitle(session),
        description: _getSleepDescription(session),
        date: DateTime(date.year, date.month, date.day),
        startTime: session.startTime,
        endTime: session.endTime,
        duration: Duration(minutes: session.totalMinutes),
        type: RecordType.routine,
        icon: _getSleepIcon(session),
        color: '#7C4DFF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  /// 将运动数据转换为时间记录模型列表
  List<TimeRecordModel> workoutsToTimeRecords({
    required List<WorkoutSession> workouts,
    required String userId,
    required DateTime date,
  }) {
    return workouts.map((workout) {
      return TimeRecordModel(
        id: '',
        userId: userId,
        title: workout.type,
        description: workout.formattedDuration +
            (workout.calories > 0 ? ' · ${workout.calories.round()}千卡' : ''),
        date: DateTime(date.year, date.month, date.day),
        startTime: workout.startTime,
        endTime: workout.endTime,
        duration: Duration(minutes: workout.durationMinutes),
        type: RecordType.routine,
        icon: _getWorkoutIcon(workout.type),
        color: '#FF6D00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  // ==================== 辅助方法 ====================

  String _getSleepTitle(SleepSession session) {
    if (session.totalMinutes >= 360) return '夜间睡眠';
    if (session.totalMinutes >= 60) return '午休';
    return '小憩';
  }

  String _getSleepDescription(SleepSession session) {
    final parts = <String>[];
    if (session.deepMinutes > 0) parts.add('深睡${session.deepMinutes}分');
    if (session.remMinutes > 0) parts.add('REM${session.remMinutes}分');
    if (session.lightMinutes > 0) parts.add('浅睡${session.lightMinutes}分');
    return parts.isEmpty ? '睡眠质量数据' : parts.join(' · ');
  }

  String _getSleepIcon(SleepSession session) {
    if (session.totalMinutes >= 360) return '🌙';
    if (session.totalMinutes >= 60) return '😴';
    return '💤';
  }

  String _getWorkoutIcon(String workoutType) {
    switch (workoutType) {
      case '跑步': return '🏃';
      case '步行': return '🚶';
      case '骑行': return '🚴';
      case '游泳': return '🏊';
      case '瑜伽': return '🧘';
      case '力量训练': return '💪';
      case 'HIIT': return '🔥';
      case '舞蹈': return '💃';
      case '徒步': return '🥾';
      case '篮球': return '🏀';
      case '足球': return '⚽';
      case '网球': return '🎾';
      case '羽毛球': return '🏸';
      default: return '🏅';
    }
  }
}
