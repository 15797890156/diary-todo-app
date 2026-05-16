import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

/// 收支数据库服务（本地存储版本）
/// 使用SharedPreferences替代Firestore
class TransactionService {
  static const String _keyTransactions = 'transactions';

  late SharedPreferences _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取所有收支记录
  Future<List<TransactionModel>> _getTransactions() async {
    final json = _prefs.getString(_keyTransactions);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有收支记录
  Future<void> _saveTransactions(List<TransactionModel> transactions) async {
    final list = transactions.map((t) => t.toJson()).toList();
    await _prefs.setString(_keyTransactions, jsonEncode(list));
  }

  // ==================== CRUD ====================

  /// 创建收支记录
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final transactions = await _getTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
    return transaction;
  }

  /// 更新收支记录
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    final transactions = await _getTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await _saveTransactions(transactions);
    }
    return transaction;
  }

  /// 删除收支记录
  Future<void> deleteTransaction(String transactionId) async {
    final transactions = await _getTransactions();
    transactions.removeWhere((t) => t.id == transactionId);
    await _saveTransactions(transactions);
  }

  // ==================== 查询 ====================

  /// 获取指定日期的收支记录
  Stream<List<TransactionModel>> getTransactionsByDate(String userId, DateTime date) async* {
    final transactions = await _getTransactions();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    yield transactions.where((t) {
      if (t.userId != userId) return false;
      return t.date.isAfter(startOfDay) && t.date.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取指定月份的收支记录
  Stream<List<TransactionModel>> getTransactionsByMonth(String userId, int year, int month) async* {
    final transactions = await _getTransactions();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    yield transactions.where((t) {
      if (t.userId != userId) return false;
      return t.date.isAfter(startOfMonth) && t.date.isBefore(endOfMonth);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 获取指定月份的月度汇总（一次性查询）
  Future<MonthlyTransactionSummary> getMonthlySummary(String userId, int year, int month) async {
    final transactions = await _getTransactions();
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final monthTransactions = transactions.where((t) {
      if (t.userId != userId) return false;
      return t.date.isAfter(startOfMonth) && t.date.isBefore(endOfMonth);
    }).toList();

    return _buildMonthlySummary(year, month, monthTransactions);
  }

  /// 获取指定日期的日度汇总
  Future<DailyTransactionSummary> getDailySummary(String userId, DateTime date) async {
    final transactions = await _getTransactions();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final dayTransactions = transactions.where((t) {
      if (t.userId != userId) return false;
      return t.date.isAfter(startOfDay) && t.date.isBefore(endOfDay);
    }).toList();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in dayTransactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    return DailyTransactionSummary(
      date: date,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      transactions: dayTransactions,
    );
  }

  // ==================== 聚合工具 ====================

  /// 构建月度汇总
  MonthlyTransactionSummary _buildMonthlySummary(
    int year,
    int month,
    List<TransactionModel> transactions,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;
    final expenseByCategory = <TransactionCategory, double>{};
    final incomeByCategory = <TransactionCategory, double>{};

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
        incomeByCategory[t.category] = (incomeByCategory[t.category] ?? 0) + t.amount;
      } else {
        totalExpense += t.amount;
        expenseByCategory[t.category] = (expenseByCategory[t.category] ?? 0) + t.amount;
      }
    }

    return MonthlyTransactionSummary(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      expenseByCategory: expenseByCategory,
      incomeByCategory: incomeByCategory,
      transactions: transactions,
    );
  }
}
