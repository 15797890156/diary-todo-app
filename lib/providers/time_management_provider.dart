import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_record_model.dart';
import '../models/quadrant_task_model.dart';
import '../services/time_management_service.dart';
import 'auth_provider.dart';

/// 时间管理服务提供者
final timeManagementServiceProvider = Provider<TimeManagementService>((ref) {
  return TimeManagementService();
});

/// 指定日期的时间记录
final timeRecordsByDateProvider =
    Provider.family<List<TimeRecordModel>, DateTime>((ref, date) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  // 使用 StreamProvider 获取实时数据
  // 这里简化为直接返回空列表，实际使用时通过 TimeRecordsNotifier 管理
  return [];
});

/// 时间记录实时流
final timeRecordsStreamProvider =
    StreamProvider.family<List<TimeRecordModel>, DateTime>((ref, date) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final service = ref.watch(timeManagementServiceProvider);
  return service.getTimeRecordsByDate(user.uid, date);
});

/// 四象限任务列表
final quadrantTasksProvider = StreamProvider<List<QuadrantTaskModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final service = ref.watch(timeManagementServiceProvider);
  return service.getQuadrantTasks(user.uid);
});

/// 时间记录操作
class TimeRecordsNotifier extends StateNotifier<AsyncValue<void>> {
  final TimeManagementService _service;
  final String _userId;

  TimeRecordsNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  /// 创建时间记录
  Future<TimeRecordModel?> createRecord({
    required String title,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    RecordType type = RecordType.event,
    String? description,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final record = TimeRecordModel(
        id: '',
        userId: _userId,
        title: title,
        description: description,
        date: date,
        startTime: startTime,
        endTime: endTime,
        duration: endTime != null ? endTime.difference(startTime) : null,
        type: type,
        icon: icon,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _service.createTimeRecord(record);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 开始计时
  Future<void> startTimer(TimeRecordModel record) async {
    try {
      await _service.startTimer(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 停止计时
  Future<void> stopTimer(TimeRecordModel record) async {
    try {
      await _service.stopTimer(record);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 删除记录
  Future<void> deleteRecord(String recordId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteTimeRecord(recordId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 时间记录操作提供者
final timeRecordsNotifierProvider =
    StateNotifierProvider<TimeRecordsNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(timeManagementServiceProvider);
  return TimeRecordsNotifier(service, user?.uid ?? '');
});

/// 四象限任务操作
class QuadrantTasksNotifier extends StateNotifier<AsyncValue<void>> {
  final TimeManagementService _service;
  final String _userId;

  QuadrantTasksNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  /// 创建任务
  Future<QuadrantTaskModel?> createTask({
    required String title,
    required QuadrantType quadrant,
    String? description,
    DateTime? dueDate,
    int priority = 5,
    String? icon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final task = QuadrantTaskModel(
        id: '',
        userId: _userId,
        title: title,
        description: description,
        quadrant: quadrant,
        dueDate: dueDate,
        priority: priority,
        icon: icon,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _service.createQuadrantTask(task);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 切换完成状态
  Future<void> toggleComplete(String taskId, bool isCompleted) async {
    try {
      await _service.toggleQuadrantTaskComplete(taskId, isCompleted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 删除任务
  Future<void> deleteTask(String taskId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteQuadrantTask(taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 移动任务到另一个象限
  Future<void> moveTask(QuadrantTaskModel task, QuadrantType newQuadrant) async {
    try {
      final updated = task.copyWith(
        quadrant: newQuadrant,
        updatedAt: DateTime.now(),
      );
      await _service.updateQuadrantTask(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 四象限任务操作提供者
final quadrantTasksNotifierProvider =
    StateNotifierProvider<QuadrantTasksNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(timeManagementServiceProvider);
  return QuadrantTasksNotifier(service, user?.uid ?? '');
});
