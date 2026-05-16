import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_archive_model.dart';
import '../models/product_track_model.dart';
import '../services/analytics_service.dart';
import 'auth_provider.dart';

/// 统计分析服务提供者
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// 指定日期的时间归档列表
final archivesByDateProvider =
    StreamProvider.family<List<TimeArchiveModel>, DateTime>((ref, date) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(analyticsServiceProvider);
  return service.getArchivesByDate(user.uid, date);
});

/// 指定事项+月份的每日归档
final archivesByItemAndMonthProvider =
    StreamProvider.family<List<TimeArchiveModel>, ({String itemName, int year, int month})>((ref, params) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(analyticsServiceProvider);
  return service.getArchivesByItemAndMonth(user.uid, params.itemName, params.year, params.month);
});

/// 指定事项+年份的每日归档
final archivesByItemAndYearProvider =
    StreamProvider.family<List<TimeArchiveModel>, ({String itemName, int year})>((ref, params) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(analyticsServiceProvider);
  return service.getArchivesByItemAndYear(user.uid, params.itemName, params.year);
});

/// 月度摘要（异步获取）
final monthlySummaryProvider =
    FutureProvider.family<List<TimeArchiveSummary>, ({int year, int month})>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.watch(analyticsServiceProvider);
  return service.getMonthlySummary(user.uid, params.year, params.month);
});

/// 年度摘要（异步获取）
final yearlySummaryProvider =
    FutureProvider.family<List<TimeArchiveSummary>, int>((ref, year) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.watch(analyticsServiceProvider);
  return service.getYearlySummary(user.uid, year);
});

/// 所有产品追踪列表
final productsProvider = StreamProvider<List<ProductTrackModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(analyticsServiceProvider);
  return service.getProducts(user.uid);
});

/// 活跃中的产品
final activeProductsProvider = StreamProvider<List<ProductTrackModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(analyticsServiceProvider);
  return service.getActiveProducts(user.uid);
});

/// 指定产品的打卡记录
final checkInsProvider =
    StreamProvider.family<List<ProductCheckInModel>, String>((ref, productId) {
  final service = ref.watch(analyticsServiceProvider);
  return service.getCheckIns(productId);
});

/// 产品操作
class ProductsNotifier extends StateNotifier<AsyncValue<void>> {
  final AnalyticsService _service;
  final String _userId;

  ProductsNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  /// 创建产品
  Future<ProductTrackModel?> createProduct({
    required String name,
    required ProductTrackType type,
    double targetProgress = 100,
    String? unit,
    String? description,
    String? icon,
    DateTime? startDate,
    int? expectedDays,
  }) async {
    state = const AsyncValue.loading();
    try {
      final product = ProductTrackModel(
        id: '',
        userId: _userId,
        name: name,
        description: description,
        icon: icon,
        type: type,
        targetProgress: targetProgress,
        unit: unit,
        startDate: startDate ?? DateTime.now(),
        expectedDays: expectedDays,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _service.createProduct(product);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 打卡
  Future<ProductTrackModel?> checkIn({
    required String productId,
    double increment = 1,
    String? note,
  }) async {
    try {
      return await _service.checkIn(
        productId: productId,
        userId: _userId,
        increment: increment,
        note: note,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 撤销打卡
  Future<void> undoCheckIn(String productId) async {
    try {
      await _service.undoLastCheckIn(productId: productId, userId: _userId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 更新产品
  Future<void> updateProduct(ProductTrackModel product) async {
    try {
      await _service.updateProduct(product);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 删除产品
  Future<void> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteProduct(productId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 产品操作提供者
final productsNotifierProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(analyticsServiceProvider);
  return ProductsNotifier(service, user?.uid ?? '');
});

/// 时间归档操作
class ArchivesNotifier extends StateNotifier<AsyncValue<void>> {
  final AnalyticsService _service;
  final String _userId;

  ArchivesNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  /// 创建或更新归档
  Future<void> upsertArchive({
    required String itemName,
    required String itemIcon,
    required DateTime date,
    required int totalSeconds,
  }) async {
    try {
      await _service.upsertArchive(TimeArchiveModel(
        id: '',
        userId: _userId,
        itemName: itemName,
        itemIcon: itemIcon,
        date: date,
        totalSeconds: totalSeconds,
        createdAt: DateTime.now(),
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 时间归档操作提供者
final archivesNotifierProvider =
    StateNotifierProvider<ArchivesNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(analyticsServiceProvider);
  return ArchivesNotifier(service, user?.uid ?? '');
});
