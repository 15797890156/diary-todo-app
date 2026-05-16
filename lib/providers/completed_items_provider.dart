import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/completed_item_model.dart';
import '../services/completed_items_service.dart';
import 'auth_provider.dart';

/// 完成事项服务提供者
final completedItemsServiceProvider = Provider<CompletedItemsService>((ref) {
  return CompletedItemsService();
});

/// 当前选中的时间筛选
final timeFilterProvider = StateProvider<TimeFilter>((ref) => TimeFilter.all);

/// 当前选中的完成事项类型（null表示全部）
final selectedCompletedTypeProvider = StateProvider<CompletedItemType?>((ref) => null);

/// 所有已完成事项
final allCompletedItemsProvider = StreamProvider<List<CompletedItemModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(completedItemsServiceProvider);
  return service.getAllCompletedItems(user.uid);
});

/// 按时间筛选的已完成事项
final filteredCompletedItemsProvider = StreamProvider<List<CompletedItemModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(completedItemsServiceProvider);
  final filter = ref.watch(timeFilterProvider);
  return service.getCompletedItemsByFilter(user.uid, filter);
});

/// 按类型和时间筛选的已完成事项
final completedItemsByTypeProvider = StreamProvider.family<
    List<CompletedItemModel>,
    ({CompletedItemType type, TimeFilter filter})>((ref, params) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(completedItemsServiceProvider);
  return service.getCompletedItemsByType(
    user.uid,
    params.type,
    filter: params.filter,
  );
});

/// 完成事项汇总统计
final completedSummaryProvider = StreamProvider<CompletedSummary>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(CompletedSummary.empty());
  final service = ref.watch(completedItemsServiceProvider);
  return service.getCompletedSummary(user.uid);
});

/// 当前显示的完成事项（根据筛选条件）
final displayedCompletedItemsProvider = Provider<AsyncValue<List<CompletedItemModel>>>((ref) {
  final selectedType = ref.watch(selectedCompletedTypeProvider);
  final filter = ref.watch(timeFilterProvider);

  if (selectedType == null) {
    // 显示全部类型
    return ref.watch(filteredCompletedItemsProvider);
  } else {
    // 显示指定类型
    return ref.watch(completedItemsByTypeProvider((type: selectedType, filter: filter)));
  }
});

/// 完成事项操作
class CompletedItemsNotifier extends StateNotifier<AsyncValue<void>> {
  final CompletedItemsService _service;
  final String _userId;

  CompletedItemsNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  /// 刷新数据
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      // 数据流会自动刷新，这里只是触发状态变化
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 完成事项操作提供者
final completedItemsNotifierProvider =
    StateNotifierProvider<CompletedItemsNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(completedItemsServiceProvider);
  return CompletedItemsNotifier(service, user?.uid ?? '');
});
