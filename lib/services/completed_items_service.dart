import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/completed_item_model.dart';
import '../models/todo_model.dart';
import '../models/time_record_model.dart';
import '../models/product_track_model.dart';
import '../models/diary_model.dart';

/// 完成事项服务（本地存储版本）
/// 聚合各类已完成数据并提供统一查询接口
/// 使用SharedPreferences替代Firestore
class CompletedItemsService {
  static const String _keyTodos = 'todos';
  static const String _keyTimeRecords = 'time_records';
  static const String _keyProducts = 'product_tracks';
  static const String _keyDiaries = 'diaries';

  late SharedPreferences _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取所有待办
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

  /// 获取所有产品
  Future<List<ProductTrackModel>> _getProducts() async {
    final json = _prefs.getString(_keyProducts);
    if (json == null) return [];
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => ProductTrackModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

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

  /// 获取所有已完成事项
  Future<List<CompletedItemModel>> getAllCompletedItems(String userId) async {
    return _combineItems(userId);
  }

  /// 获取指定时间筛选的已完成事项
  Future<List<CompletedItemModel>> getCompletedItemsByFilter(
    String userId,
    TimeFilter filter,
  ) async {
    final items = await _combineItems(userId);

    if (filter == TimeFilter.all) {
      return items;
    }

    return items.where((item) => item.isInTimeFilter(filter)).toList();
  }

  /// 获取指定类型的已完成事项
  Future<List<CompletedItemModel>> getCompletedItemsByType(
    String userId,
    CompletedItemType type, {
    TimeFilter filter = TimeFilter.all,
  }) async {
    final items = await getCompletedItemsByFilter(userId, filter);
    return items.where((item) => item.type == type).toList();
  }

  /// 获取完成事项汇总统计
  Future<CompletedSummary> getCompletedSummary(String userId) async {
    final items = await getAllCompletedItems(userId);
    return _buildSummary(items);
  }

  /// 组合多个数据源
  Future<List<CompletedItemModel>> _combineItems(String userId) async {
    final todos = await _getCompletedTodos(userId);
    final timeRecords = await _getCompletedTimeRecords(userId);
    final products = await _getCompletedProducts(userId);
    final diaries = await _getCompletedDiaries(userId);

    var allItems = [...todos, ...timeRecords, ...products, ...diaries];

    // 按完成时间倒序排列
    allItems.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return allItems;
  }

  /// 获取已完成的待办事项
  Future<List<CompletedItemModel>> _getCompletedTodos(String userId) async {
    final todos = await _getTodos();
    return todos
        .where((t) => t.userId == userId && t.isCompleted)
        .map((t) => CompletedItemModel.fromTodo(t))
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.completedAt!).compareTo(a.completedAt ?? a.completedAt!));
  }

  /// 获取已完成的时间记录（有结束时间的）
  Future<List<CompletedItemModel>> _getCompletedTimeRecords(String userId) async {
    final records = await _getTimeRecords();
    return records
        .where((r) => r.userId == userId && r.endTime != null)
        .map((r) => CompletedItemModel.fromTimeRecord(r))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  /// 获取已完成的产品（进度达到目标的）
  Future<List<CompletedItemModel>> _getCompletedProducts(String userId) async {
    final products = await _getProducts();
    return products
        .where((p) => p.userId == userId && p.status == ProductTrackStatus.completed)
        .map((p) => CompletedItemModel.fromProduct(p))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  /// 获取日记（作为已完成的生活记录）
  Future<List<CompletedItemModel>> _getCompletedDiaries(String userId) async {
    final diaries = await _getDiaries();
    return diaries
        .where((d) => d.userId == userId)
        .map((d) => CompletedItemModel.fromDiary(d))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  /// 构建汇总统计
  CompletedSummary _buildSummary(List<CompletedItemModel> items) {
    final now = DateTime.now();

    // 计算各时间维度的数量
    int todayCount = 0;
    int weekCount = 0;
    int monthCount = 0;

    for (final item in items) {
      if (item.isInTimeFilter(TimeFilter.today)) todayCount++;
      if (item.isInTimeFilter(TimeFilter.week)) weekCount++;
      if (item.isInTimeFilter(TimeFilter.month)) monthCount++;
    }

    // 按类型统计
    final countByType = <CompletedItemType, int>{};
    for (final type in CompletedItemType.values) {
      countByType[type] = items.where((item) => item.type == type).length;
    }

    // 构建分类统计列表
    final categories = CompletedItemType.values.map((type) {
      final typeItems = items.where((item) => item.type == type).toList();
      return CompletedCategoryStats(
        type: type,
        name: _getTypeDisplayName(type),
        icon: _getTypeDisplayIcon(type),
        count: typeItems.length,
        items: typeItems,
      );
    }).where((cat) => cat.count > 0).toList();

    // 按数量排序
    categories.sort((a, b) => b.count.compareTo(a.count));

    return CompletedSummary(
      totalCount: items.length,
      todayCount: todayCount,
      weekCount: weekCount,
      monthCount: monthCount,
      countByType: countByType,
      categories: categories,
    );
  }

  /// 获取类型显示名称
  String _getTypeDisplayName(CompletedItemType type) {
    switch (type) {
      case CompletedItemType.todo:
        return '待办事项';
      case CompletedItemType.timeRecord:
        return '时间记录';
      case CompletedItemType.book:
        return '书籍阅读';
      case CompletedItemType.movie:
        return '电影观看';
      case CompletedItemType.product:
        return '产品追踪';
      case CompletedItemType.diary:
        return '日记记录';
    }
  }

  /// 获取类型显示图标
  String _getTypeDisplayIcon(CompletedItemType type) {
    switch (type) {
      case CompletedItemType.todo:
        return '✅';
      case CompletedItemType.timeRecord:
        return '⏱️';
      case CompletedItemType.book:
        return '📚';
      case CompletedItemType.movie:
        return '🎬';
      case CompletedItemType.product:
        return '📦';
      case CompletedItemType.diary:
        return '📝';
    }
  }
}
