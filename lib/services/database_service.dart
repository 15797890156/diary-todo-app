import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// 数据库服务（本地存储版本）
/// 处理待办事项、日记、日历事件的 CRUD 操作
/// 使用SharedPreferences替代Firestore
class DatabaseService {
  static const String _keyTodos = 'todos';
  static const String _keyDiaries = 'diaries';
  static const String _keyEvents = 'calendar_events';

  late SharedPreferences _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 待办事项相关 ====================

  /// 获取所有待办事项
  Future<List<TodoModel>> _getTodos() async {
    final json = _prefs.getString(_keyTodos);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => TodoModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有待办事项
  Future<void> _saveTodos(List<TodoModel> todos) async {
    final list = todos.map((t) => t.toJson()).toList();
    await _prefs.setString(_keyTodos, jsonEncode(list));
  }

  /// 创建待办事项
  Future<TodoModel> createTodo(TodoModel todo) async {
    final todos = await _getTodos();
    todos.add(todo);
    await _saveTodos(todos);
    return todo;
  }

  /// 更新待办事项
  Future<TodoModel> updateTodo(TodoModel todo) async {
    final todos = await _getTodos();
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = todo;
      await _saveTodos(todos);
    }
    return todo;
  }

  /// 删除待办事项
  Future<void> deleteTodo(String todoId) async {
    final todos = await _getTodos();
    todos.removeWhere((t) => t.id == todoId);
    await _saveTodos(todos);
  }

  /// 切换待办事项完成状态
  Future<TodoModel> toggleTodoComplete(String todoId, bool isCompleted) async {
    final todos = await _getTodos();
    final index = todos.indexWhere((t) => t.id == todoId);
    if (index != -1) {
      final updated = todos[index].copyWith(
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );
      todos[index] = updated;
      await _saveTodos(todos);
      return updated;
    }
    throw Exception('待办事项不存在');
  }

  /// 获取用户的所有待办事项
  Stream<List<TodoModel>> getTodos(String userId) async* {
    final todos = await _getTodos();
    yield todos.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取指定日期的待办事项
  Stream<List<TodoModel>> getTodosByDate(String userId, DateTime date) async* {
    final todos = await _getTodos();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    yield todos.where((t) {
      if (t.userId != userId) return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.isAfter(startOfDay) && t.dueDate!.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));
  }

  /// 获取待完成的待办事项
  Stream<List<TodoModel>> getPendingTodos(String userId) async* {
    final todos = await _getTodos();
    yield todos.where((t) => t.userId == userId && !t.isCompleted).toList()
      ..sort((a, b) => (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));
  }

  /// 获取已完成的待办事项
  Stream<List<TodoModel>> getCompletedTodos(String userId) async* {
    final todos = await _getTodos();
    yield todos.where((t) => t.userId == userId && t.isCompleted).toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
  }

  // ==================== 日记相关 ====================

  /// 获取所有日记
  Future<List<DiaryModel>> _getDiaries() async {
    final json = _prefs.getString(_keyDiaries);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => DiaryModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有日记
  Future<void> _saveDiaries(List<DiaryModel> diaries) async {
    final list = diaries.map((d) => d.toJson()).toList();
    await _prefs.setString(_keyDiaries, jsonEncode(list));
  }

  /// 创建日记
  Future<DiaryModel> createDiary(DiaryModel diary) async {
    final diaries = await _getDiaries();
    diaries.add(diary);
    await _saveDiaries(diaries);
    return diary;
  }

  /// 更新日记
  Future<DiaryModel> updateDiary(DiaryModel diary) async {
    final diaries = await _getDiaries();
    final index = diaries.indexWhere((d) => d.id == diary.id);
    if (index != -1) {
      diaries[index] = diary;
      await _saveDiaries(diaries);
    }
    return diary;
  }

  /// 删除日记
  Future<void> deleteDiary(String diaryId) async {
    final diaries = await _getDiaries();
    diaries.removeWhere((d) => d.id == diaryId);
    await _saveDiaries(diaries);
  }

  /// 获取用户的所有日记
  Stream<List<DiaryModel>> getDiaries(String userId) async* {
    final diaries = await _getDiaries();
    yield diaries.where((d) => d.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取指定日期的日记
  Stream<List<DiaryModel>> getDiariesByDate(String userId, DateTime date) async* {
    final diaries = await _getDiaries();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    yield diaries.where((d) {
      if (d.userId != userId) return false;
      return d.createdAt.isAfter(startOfDay) && d.createdAt.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取指定月份的日记
  Stream<List<DiaryModel>> getDiariesByMonth(String userId, int year, int month) async* {
    final diaries = await _getDiaries();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    yield diaries.where((d) {
      if (d.userId != userId) return false;
      return d.createdAt.isAfter(startOfMonth) && d.createdAt.isBefore(endOfMonth);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ==================== 日历事件相关 ====================

  /// 获取所有日历事件
  Future<List<CalendarEventModel>> _getEvents() async {
    final json = _prefs.getString(_keyEvents);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => CalendarEventModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有日历事件
  Future<void> _saveEvents(List<CalendarEventModel> events) async {
    final list = events.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyEvents, jsonEncode(list));
  }

  /// 创建日历事件
  Future<CalendarEventModel> createEvent(CalendarEventModel event) async {
    final events = await _getEvents();
    events.add(event);
    await _saveEvents(events);
    return event;
  }

  /// 更新日历事件
  Future<CalendarEventModel> updateEvent(CalendarEventModel event) async {
    final events = await _getEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      await _saveEvents(events);
    }
    return event;
  }

  /// 删除日历事件
  Future<void> deleteEvent(String eventId) async {
    final events = await _getEvents();
    events.removeWhere((e) => e.id == eventId);
    await _saveEvents(events);
  }

  /// 获取指定日期范围的事件
  Stream<List<CalendarEventModel>> getEventsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async* {
    final events = await _getEvents();
    yield events.where((e) {
      if (e.userId != userId) return false;
      return e.startTime.isAfter(start) && e.startTime.isBefore(end);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// 获取指定日期的事件
  Stream<List<CalendarEventModel>> getEventsByDate(String userId, DateTime date) async* {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    yield* getEventsByDateRange(userId, startOfDay, endOfDay);
  }

  /// 获取指定月份的事件
  Stream<List<CalendarEventModel>> getEventsByMonth(String userId, int year, int month) async* {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);
    yield* getEventsByDateRange(userId, startOfMonth, endOfMonth);
  }
}
