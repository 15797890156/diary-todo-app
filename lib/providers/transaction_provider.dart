import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';

/// 收支服务提供者
final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService();
});

/// 指定日期的收支记录列表
final transactionsByDateProvider =
    StreamProvider.family<List<TransactionModel>, DateTime>((ref, date) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(transactionServiceProvider);
  return service.getTransactionsByDate(user.uid, date);
});

/// 指定月份的收支记录列表
final transactionsByMonthProvider =
    StreamProvider.family<List<TransactionModel>, ({int year, int month})>((ref, params) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final service = ref.watch(transactionServiceProvider);
  return service.getTransactionsByMonth(user.uid, params.year, params.month);
});

/// 月度收支汇总（异步获取）
final monthlyTransactionSummaryProvider =
    FutureProvider.family<MonthlyTransactionSummary?, ({int year, int month})>((ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.watch(transactionServiceProvider);
  return service.getMonthlySummary(user.uid, params.year, params.month);
});

/// 日度收支汇总（异步获取）
final dailyTransactionSummaryProvider =
    FutureProvider.family<DailyTransactionSummary?, DateTime>((ref, date) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.watch(transactionServiceProvider);
  return service.getDailySummary(user.uid, date);
});

/// 收支操作
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionService _service;
  final String _userId;

  TransactionNotifier(this._service, this._userId)
      : super(const AsyncValue.data(null));

  /// 创建收支记录
  Future<TransactionModel?> createTransaction({
    required TransactionType type,
    required TransactionCategory category,
    required double amount,
    String? note,
    String? icon,
    required DateTime date,
  }) async {
    state = const AsyncValue.loading();
    try {
      final transaction = TransactionModel(
        id: '',
        userId: _userId,
        type: type,
        category: category,
        amount: amount,
        note: note,
        icon: icon,
        date: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _service.createTransaction(transaction);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 更新收支记录
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _service.updateTransaction(transaction.copyWith(
        updatedAt: DateTime.now(),
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 删除收支记录
  Future<void> deleteTransaction(String transactionId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteTransaction(transactionId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 收支操作提供者
final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(transactionServiceProvider);
  return TransactionNotifier(service, user?.uid ?? '');
});
