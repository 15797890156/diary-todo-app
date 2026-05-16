import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_record_model.dart';
import '../services/health_data_service.dart';
import '../services/time_management_service.dart';
import 'auth_provider.dart';

/// 健康数据同步服务提供者
final healthDataServiceProvider = Provider<HealthDataService>((ref) {
  return HealthDataService();
});

/// 健康数据授权状态
enum HealthAuthStatus {
  unknown,    // 未检测
  authorized, // 已授权
  denied,     // 拒绝授权
  unsupported,// 平台不支持
}

/// 健康数据授权状态提供者
final healthAuthStatusProvider =
    StateNotifierProvider<HealthAuthNotifier, HealthAuthStatus>((ref) {
  final service = ref.watch(healthDataServiceProvider);
  return HealthAuthNotifier(service);
});

/// 健康数据授权状态管理
class HealthAuthNotifier extends StateNotifier<HealthAuthStatus> {
  final HealthDataService _service;

  HealthAuthNotifier(this._service) : super(HealthAuthStatus.unknown);

  /// 检查当前授权状态
  Future<void> checkStatus() async {
    try {
      final hasPermission = await _service.checkAuthorization();
      state = hasPermission ? HealthAuthStatus.authorized : HealthAuthStatus.denied;
    } catch (e) {
      state = HealthAuthStatus.unsupported;
    }
  }

  /// 请求授权
  Future<bool> requestAuthorization() async {
    state = HealthAuthStatus.unknown;
    try {
      final granted = await _service.requestAuthorization();
      state = granted ? HealthAuthStatus.authorized : HealthAuthStatus.denied;
      return granted;
    } catch (e) {
      state = HealthAuthStatus.unsupported;
      return false;
    }
  }
}

/// 同步结果
class SyncResult {
  final bool success;
  final int sleepRecords;
  final int workoutRecords;
  final int steps;
  final String? error;

  SyncResult({
    required this.success,
    this.sleepRecords = 0,
    this.workoutRecords = 0,
    this.steps = 0,
    this.error,
  });

  String get summary {
    if (!success) return '同步失败: $error';
    final parts = <String>[];
    if (sleepRecords > 0) parts.add('睡眠 $sleepRecords 条');
    if (workoutRecords > 0) parts.add('运动 $workoutRecords 条');
    if (steps > 0) parts.add('步数 $steps 步');
    return parts.isEmpty ? '暂无新数据' : '已同步: ${parts.join("，")}';
  }
}

/// 健康数据同步操作
class HealthSyncNotifier extends StateNotifier<AsyncValue<SyncResult?>> {
  final HealthDataService _healthService;
  final TimeManagementService _timeService;
  final String _userId;

  HealthSyncNotifier(this._healthService, this._timeService, this._userId)
      : super(const AsyncValue.data(null));

  /// 同步指定日期的健康数据到时间记录
  Future<SyncResult> syncDate(DateTime date) async {
    state = const AsyncValue.loading();
    try {
      // 1. 获取睡眠数据
      final sleepSessions = await _healthService.getSleepData(date);
      final sleepRecords = _healthService.sleepToTimeRecords(
        sessions: sleepSessions,
        userId: _userId,
        date: date,
      );

      // 2. 获取运动数据
      final workouts = await _healthService.getWorkouts(date);
      final workoutRecords = _healthService.workoutsToTimeRecords(
        workouts: workouts,
        userId: _userId,
        date: date,
      );

      // 3. 获取步数
      final steps = await _healthService.getSteps(date);

      // 4. 写入时间记录（睡眠 + 运动）
      int savedSleep = 0;
      int savedWorkout = 0;

      for (final record in sleepRecords) {
        await _timeService.createTimeRecord(record);
        savedSleep++;
      }

      for (final record in workoutRecords) {
        await _timeService.createTimeRecord(record);
        savedWorkout++;
      }

      final result = SyncResult(
        success: true,
        sleepRecords: savedSleep,
        workoutRecords: savedWorkout,
        steps: steps,
      );

      state = AsyncValue.data(result);
      return result;
    } catch (e) {
      final result = SyncResult(success: false, error: e.toString());
      state = AsyncValue.data(result);
      return result;
    }
  }

  /// 同步指定日期范围的健康数据
  Future<SyncResult> syncDateRange(DateTime start, DateTime end) async {
    state = const AsyncValue.loading();
    try {
      int totalSleep = 0;
      int totalWorkout = 0;
      int totalSteps = 0;

      // 逐天同步
      var current = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);

      while (!current.isAfter(endDate)) {
        final sleepSessions = await _healthService.getSleepData(current);
        final sleepRecords = _healthService.sleepToTimeRecords(
          sessions: sleepSessions,
          userId: _userId,
          date: current,
        );

        final workouts = await _healthService.getWorkouts(current);
        final workoutRecords = _healthService.workoutsToTimeRecords(
          workouts: workouts,
          userId: _userId,
          date: current,
        );

        final steps = await _healthService.getSteps(current);

        for (final record in sleepRecords) {
          await _timeService.createTimeRecord(record);
          totalSleep++;
        }

        for (final record in workoutRecords) {
          await _timeService.createTimeRecord(record);
          totalWorkout++;
        }

        totalSteps += steps;
        current = current.add(const Duration(days: 1));
      }

      final result = SyncResult(
        success: true,
        sleepRecords: totalSleep,
        workoutRecords: totalWorkout,
        steps: totalSteps,
      );

      state = AsyncValue.data(result);
      return result;
    } catch (e) {
      final result = SyncResult(success: false, error: e.toString());
      state = AsyncValue.data(result);
      return result;
    }
  }
}

/// 健康数据同步操作提供者
final healthSyncNotifierProvider =
    StateNotifierProvider<HealthSyncNotifier, AsyncValue<SyncResult?>>((ref) {
  final healthService = ref.watch(healthDataServiceProvider);
  final timeService = ref.watch(timeManagementServiceProvider);
  final user = ref.watch(currentUserProvider);
  return HealthSyncNotifier(healthService, timeService, user?.uid ?? '');
});

/// 是否开启自动同步
final autoSyncEnabledProvider = StateProvider<bool>((ref) => false);

/// 自动同步时段（0=关闭, 1=每天, 7=每周）
final autoSyncIntervalProvider = StateProvider<int>((ref) => 0);

/// 上次同步时间
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);
