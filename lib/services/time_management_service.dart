import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_record_model.dart';
import '../models/quadrant_task_model.dart';

/// 时间记录和四象限任务的数据库服务（本地存储版本）
/// 使用SharedPreferences替代Firestore
class TimeManagementService {
  static const String _keyTimeRecords = 'time_records';
  static const String _keyQuadrantTasks = 'quadrant_tasks';

  late SharedPreferences _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 时间记录相关 ====================

  /// 获取所有时间记录
  Future<List<TimeRecordModel>> _getTimeRecords() async {
    final json = _prefs.getString(_keyTimeRecords);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => TimeRecordModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有时间记录
  Future<void> _saveTimeRecords(List<TimeRecordModel> records) async {
    final list = records.map((r) => r.toJson()).toList();
    await _prefs.setString(_keyTimeRecords, jsonEncode(list));
  }

  /// 创建时间记录
  Future<TimeRecordModel> createTimeRecord(TimeRecordModel record) async {
    final records = await _getTimeRecords();
    records.add(record);
    await _saveTimeRecords(records);
    return record;
  }

  /// 更新时间记录
  Future<TimeRecordModel> updateTimeRecord(TimeRecordModel record) async {
    final records = await _getTimeRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await _saveTimeRecords(records);
    }
    return record;
  }

  /// 删除时间记录
  Future<void> deleteTimeRecord(String recordId) async {
    final records = await _getTimeRecords();
    records.removeWhere((r) => r.id == recordId);
    await _saveTimeRecords(records);
  }

  /// 获取指定日期的时间记录
  Stream<List<TimeRecordModel>> getTimeRecordsByDate(String userId, DateTime date) async* {
    final records = await _getTimeRecords();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    yield records.where((r) {
      if (r.userId != userId) return false;
      return r.date.isAfter(startOfDay) && r.date.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// 获取正在计时的记录
  Stream<List<TimeRecordModel>> getRunningTimers(String userId) async* {
    final records = await _getTimeRecords();
    yield records.where((r) => r.userId == userId && r.isTimerRunning).toList();
  }

  /// 开始计时
  Future<TimeRecordModel> startTimer(TimeRecordModel record) async {
    final updated = record.copyWith(
      isTimerRunning: true,
      timerStartedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateTimeRecord(updated);
    return updated;
  }

  /// 停止计时
  Future<TimeRecordModel> stopTimer(TimeRecordModel record) async {
    final now = DateTime.now();
    final elapsed = record.timerStartedAt != null
        ? now.difference(record.timerStartedAt!)
        : Duration.zero;
    final totalDuration = (record.duration ?? Duration.zero) + elapsed;

    final updated = record.copyWith(
      isTimerRunning: false,
      timerStartedAt: null,
      endTime: now,
      duration: totalDuration,
      updatedAt: now,
    );
    await updateTimeRecord(updated);
    return updated;
  }

  // ==================== 四象限任务相关 ====================

  /// 获取所有四象限任务
  Future<List<QuadrantTaskModel>> _getQuadrantTasks() async {
    final json = _prefs.getString(_keyQuadrantTasks);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => QuadrantTaskModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有四象限任务
  Future<void> _saveQuadrantTasks(List<QuadrantTaskModel> tasks) async {
    final list = tasks.map((t) => t.toJson()).toList();
    await _prefs.setString(_keyQuadrantTasks, jsonEncode(list));
  }

  /// 创建四象限任务
  Future<QuadrantTaskModel> createQuadrantTask(QuadrantTaskModel task) async {
    final tasks = await _getQuadrantTasks();
    tasks.add(task);
    await _saveQuadrantTasks(tasks);
    return task;
  }

  /// 更新四象限任务
  Future<QuadrantTaskModel> updateQuadrantTask(QuadrantTaskModel task) async {
    final tasks = await _getQuadrantTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await _saveQuadrantTasks(tasks);
    }
    return task;
  }

  /// 删除四象限任务
  Future<void> deleteQuadrantTask(String taskId) async {
    final tasks = await _getQuadrantTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveQuadrantTasks(tasks);
  }

  /// 切换完成状态
  Future<QuadrantTaskModel> toggleQuadrantTaskComplete(
    String taskId,
    bool isCompleted,
  ) async {
    final tasks = await _getQuadrantTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updated = tasks[index].copyWith(
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );
      tasks[index] = updated;
      await _saveQuadrantTasks(tasks);
      return updated;
    }
    throw Exception('任务不存在');
  }

  /// 获取所有四象限任务
  Stream<List<QuadrantTaskModel>> getQuadrantTasks(String userId) async* {
    final tasks = await _getQuadrantTasks();
    yield tasks.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// 获取指定象限的任务
  Stream<List<QuadrantTaskModel>> getQuadrantTasksByType(
    String userId,
    QuadrantType quadrant,
  ) async* {
    final tasks = await _getQuadrantTasks();
    yield tasks.where((t) => t.userId == userId && t.quadrant == quadrant).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }
}
