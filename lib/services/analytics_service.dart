import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_archive_model.dart';
import '../models/product_track_model.dart';

/// 统计分析服务（本地存储版本）
/// 处理时间归档和产品追踪的数据操作
/// 使用SharedPreferences替代Firestore
class AnalyticsService {
  static const String _keyArchives = 'time_archives';
  static const String _keyProducts = 'product_tracks';
  static const String _keyCheckIns = 'product_check_ins';

  late SharedPreferences _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 时间归档相关 ====================

  /// 获取所有归档记录
  Future<List<TimeArchiveModel>> _getArchives() async {
    final json = _prefs.getString(_keyArchives);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => TimeArchiveModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有归档记录
  Future<void> _saveArchives(List<TimeArchiveModel> archives) async {
    final list = archives.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyArchives, jsonEncode(list));
  }

  /// 创建或更新归档记录（同一天同一事项会累加）
  Future<TimeArchiveModel> upsertArchive(TimeArchiveModel archive) async {
    final archives = await _getArchives();

    // 查询当天该事项是否已有归档
    final existingIndex = archives.indexWhere((a) {
      return a.userId == archive.userId &&
          a.itemName == archive.itemName &&
          a.date.year == archive.date.year &&
          a.date.month == archive.date.month &&
          a.date.day == archive.date.day;
    });

    if (existingIndex != -1) {
      // 已存在，累加时长
      final existing = archives[existingIndex];
      final updated = existing.copyWith(
        totalSeconds: existing.totalSeconds + archive.totalSeconds,
        recordCount: existing.recordCount + 1,
      );
      archives[existingIndex] = updated;
      await _saveArchives(archives);
      return updated;
    } else {
      // 不存在，创建新记录
      archives.add(archive);
      await _saveArchives(archives);
      return archive;
    }
  }

  /// 获取指定日期的所有归档
  Stream<List<TimeArchiveModel>> getArchivesByDate(String userId, DateTime date) async* {
    final archives = await _getArchives();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    yield archives.where((a) {
      if (a.userId != userId) return false;
      return a.date.isAfter(startOfDay) && a.date.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));
  }

  /// 获取指定事项在月份内的每日归档
  Stream<List<TimeArchiveModel>> getArchivesByItemAndMonth(
    String userId,
    String itemName,
    int year,
    int month,
  ) async* {
    final archives = await _getArchives();
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    yield archives.where((a) {
      if (a.userId != userId) return false;
      if (a.itemName != itemName) return false;
      return a.date.isAfter(start) && a.date.isBefore(end);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 获取指定事项在年份内的每日归档
  Stream<List<TimeArchiveModel>> getArchivesByItemAndYear(
    String userId,
    String itemName,
    int year,
  ) async* {
    final archives = await _getArchives();
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    yield archives.where((a) {
      if (a.userId != userId) return false;
      if (a.itemName != itemName) return false;
      return a.date.isAfter(start) && a.date.isBefore(end);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 获取用户所有事项名称列表（去重）
  Future<List<String>> getAllItemNames(String userId) async {
    final archives = await _getArchives();
    final names = <String>{};

    for (final archive in archives) {
      if (archive.userId == userId) {
        names.add(archive.itemName);
      }
    }
    return names.toList()..sort();
  }

  /// 获取指定月份的所有归档，并聚合为摘要列表
  Future<List<TimeArchiveSummary>> getMonthlySummary(
    String userId,
    int year,
    int month,
  ) async {
    final archives = await _getArchives();
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final monthArchives = archives.where((a) {
      if (a.userId != userId) return false;
      return a.date.isAfter(start) && a.date.isBefore(end);
    }).toList();

    // 按事项名称分组
    final Map<String, List<TimeArchiveModel>> grouped = {};
    for (final archive in monthArchives) {
      grouped.putIfAbsent(archive.itemName, () => []).add(archive);
    }

    // 生成摘要
    return grouped.entries.map((entry) {
      final details = entry.value;
      final totalSeconds = details.fold<int>(
        0, (sum, a) => sum + a.totalSeconds,
      );
      final totalRecords = details.fold<int>(
        0, (sum, a) => sum + a.recordCount,
      );

      return TimeArchiveSummary(
        itemName: entry.key,
        itemIcon: details.first.itemIcon,
        totalSeconds: totalSeconds,
        activeDays: details.length,
        totalRecords: totalRecords,
        dailyDetails: details,
      );
    }).toList()
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));
  }

  /// 获取指定年份的所有归档，并聚合为摘要列表
  Future<List<TimeArchiveSummary>> getYearlySummary(
    String userId,
    int year,
  ) async {
    final archives = await _getArchives();
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    final yearArchives = archives.where((a) {
      if (a.userId != userId) return false;
      return a.date.isAfter(start) && a.date.isBefore(end);
    }).toList();

    final Map<String, List<TimeArchiveModel>> grouped = {};
    for (final archive in yearArchives) {
      grouped.putIfAbsent(archive.itemName, () => []).add(archive);
    }

    return grouped.entries.map((entry) {
      final details = entry.value;
      final totalSeconds = details.fold<int>(
        0, (sum, a) => sum + a.totalSeconds,
      );
      final totalRecords = details.fold<int>(
        0, (sum, a) => sum + a.recordCount,
      );

      return TimeArchiveSummary(
        itemName: entry.key,
        itemIcon: details.first.itemIcon,
        totalSeconds: totalSeconds,
        activeDays: details.length,
        totalRecords: totalRecords,
        dailyDetails: details,
      );
    }).toList()
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));
  }

  /// 删除归档记录
  Future<void> deleteArchive(String archiveId) async {
    final archives = await _getArchives();
    archives.removeWhere((a) => a.id == archiveId);
    await _saveArchives(archives);
  }

  // ==================== 产品追踪相关 ====================

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

  /// 保存所有产品
  Future<void> _saveProducts(List<ProductTrackModel> products) async {
    final list = products.map((p) => p.toJson()).toList();
    await _prefs.setString(_keyProducts, jsonEncode(list));
  }

  /// 获取所有打卡记录
  Future<List<ProductCheckInModel>> _getCheckIns() async {
    final json = _prefs.getString(_keyCheckIns);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => ProductCheckInModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有打卡记录
  Future<void> _saveCheckIns(List<ProductCheckInModel> checkIns) async {
    final list = checkIns.map((c) => c.toJson()).toList();
    await _prefs.setString(_keyCheckIns, jsonEncode(list));
  }

  /// 创建产品追踪
  Future<ProductTrackModel> createProduct(ProductTrackModel product) async {
    final products = await _getProducts();
    products.add(product);
    await _saveProducts(products);
    return product;
  }

  /// 更新产品追踪
  Future<ProductTrackModel> updateProduct(ProductTrackModel product) async {
    final products = await _getProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await _saveProducts(products);
    }
    return product;
  }

  /// 删除产品追踪
  Future<void> deleteProduct(String productId) async {
    final products = await _getProducts();
    products.removeWhere((p) => p.id == productId);
    await _saveProducts(products);

    // 同时删除所有打卡记录
    final checkIns = await _getCheckIns();
    checkIns.removeWhere((c) => c.productId == productId);
    await _saveCheckIns(checkIns);
  }

  /// 获取所有产品追踪
  Stream<List<ProductTrackModel>> getProducts(String userId) async* {
    final products = await _getProducts();
    yield products.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取活跃中的产品
  Stream<List<ProductTrackModel>> getActiveProducts(String userId) async* {
    final products = await _getProducts();
    yield products.where((p) =>
        p.userId == userId && p.status == ProductTrackStatus.active).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 打卡 / 增加进度
  Future<ProductTrackModel> checkIn({
    required String productId,
    required String userId,
    double increment = 1,
    String? note,
  }) async {
    final now = DateTime.now();

    // 创建打卡记录
    final checkIns = await _getCheckIns();
    final newCheckIn = ProductCheckInModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: productId,
      userId: userId,
      date: DateTime(now.year, now.month, now.day),
      increment: increment,
      note: note,
      createdAt: now,
    );
    checkIns.add(newCheckIn);
    await _saveCheckIns(checkIns);

    // 获取当前产品
    final products = await _getProducts();
    final productIndex = products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) throw Exception('产品不存在');

    final product = products[productIndex];

    // 计算连续天数
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final isNewStreak = product.lastCheckInAt == null ||
        product.lastCheckInAt!.isBefore(yesterday);

    final newStreak = isNewStreak ? 1 : product.currentStreak + 1;
    final newLongest = newStreak > product.longestStreak
        ? newStreak
        : product.longestStreak;

    // 更新产品
    var updated = product.copyWith(
      currentProgress: product.currentProgress + increment,
      totalCheckIns: product.totalCheckIns + 1,
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastCheckInAt: now,
      updatedAt: now,
    );

    // 检查是否完成
    if (updated.currentProgress >= updated.targetProgress &&
        updated.status == ProductTrackStatus.active) {
      updated = updated.copyWith(
        status: ProductTrackStatus.completed,
        endDate: now,
        updatedAt: now,
      );
    }

    products[productIndex] = updated;
    await _saveProducts(products);
    return updated;
  }

  /// 获取产品的打卡记录
  Stream<List<ProductCheckInModel>> getCheckIns(String productId) async* {
    final checkIns = await _getCheckIns();
    yield checkIns.where((c) => c.productId == productId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 获取产品指定月份的打卡记录
  Stream<List<ProductCheckInModel>> getCheckInsByMonth(
    String productId,
    int year,
    int month,
  ) async* {
    final checkIns = await _getCheckIns();
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    yield checkIns.where((c) {
      if (c.productId != productId) return false;
      return c.date.isAfter(start) && c.date.isBefore(end);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 撤销最近一次打卡
  Future<ProductTrackModel> undoLastCheckIn({
    required String productId,
    required String userId,
  }) async {
    // 获取最近一条打卡记录
    final checkIns = await _getCheckIns();
    final productCheckIns = checkIns
        .where((c) => c.productId == productId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (productCheckIns.isEmpty) throw Exception('没有可撤销的打卡记录');

    final lastCheckIn = productCheckIns.first;
    checkIns.removeWhere((c) => c.id == lastCheckIn.id);
    await _saveCheckIns(checkIns);

    // 更新产品进度
    final products = await _getProducts();
    final productIndex = products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) throw Exception('产品不存在');

    final product = products[productIndex];
    final updated = product.copyWith(
      currentProgress: (product.currentProgress - lastCheckIn.increment)
          .clamp(0, double.infinity),
      totalCheckIns: (product.totalCheckIns - 1).clamp(0, 999999),
      updatedAt: DateTime.now(),
    );

    products[productIndex] = updated;
    await _saveProducts(products);
    return updated;
  }
}
