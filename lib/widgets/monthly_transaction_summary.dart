import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/providers.dart';
import '../config/themes/themes.dart';

/// 月度收支汇总组件
/// 用于在月视图下展示当月的收入、支出和结余概况
class MonthlyTransactionSummaryWidget extends ConsumerWidget {
  final int year;
  final int month;

  const MonthlyTransactionSummaryWidget({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(monthlyTransactionSummaryProvider((year: year, month: month)));

    return summaryAsync.when(
      loading: () => _buildSkeleton(theme),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary == null || (summary.totalIncome == 0 && summary.totalExpense == 0)) {
          return const SizedBox.shrink();
        }
        return _buildSummary(context, theme, summary);
      },
    );
  }

  /// 构建汇总卡片
  Widget _buildSummary(BuildContext context, ThemeData theme, MonthlyTransactionSummary summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$year年${month}月 收支概览',
                    style: AppTextStyles.bodyMedium(
                      color: theme.colorScheme.onPrimaryContainer,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              _buildBalanceBadge(theme, summary),
            ],
          ),

          const SizedBox(height: 16),

          // 三栏数据
          Row(
            children: [
              _buildDataColumn(
                theme,
                label: '收入',
                value: summary.formattedIncome,
                icon: Icons.arrow_downward,
                color: Colors.green,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
              _buildDataColumn(
                theme,
                label: '支出',
                value: summary.formattedExpense,
                icon: Icons.arrow_upward,
                color: Colors.red,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
              _buildDataColumn(
                theme,
                label: '日均支出',
                value: '¥${summary.dailyAvgExpense.toStringAsFixed(2)}',
                icon: Icons.show_chart,
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),

          // 支出分类排行
          if (summary.expenseRanking.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              '支出排行',
              style: AppTextStyles.caption(
                color: theme.colorScheme.onPrimaryContainer,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildCategoryRanking(theme, summary),
          ],
        ],
      ),
    );
  }

  /// 构建结余标签
  Widget _buildBalanceBadge(ThemeData theme, MonthlyTransactionSummary summary) {
    final isPositive = summary.balance >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        summary.formattedBalance,
        style: AppTextStyles.bodySmall(
          color: isPositive ? Colors.green : Colors.red,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 构建数据列
  Widget _buildDataColumn(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium(
              color: color,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 构建分类排行
  Widget _buildCategoryRanking(ThemeData theme, MonthlyTransactionSummary summary) {
    final ranking = summary.expenseRanking.take(5).toList();
    final maxAmount = ranking.isNotEmpty ? ranking.first.value : 1;

    return Column(
      children: ranking.map((entry) {
        final percent = maxAmount > 0 ? entry.value / maxAmount : 0;
        final category = entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              // 分类图标
              Text(
                _getCategoryIcon(category),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              // 分类名称
              SizedBox(
                width: 56,
                child: Text(
                  _getCategoryName(category),
                  style: AppTextStyles.caption(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 进度条
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.error.withOpacity(0.7),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 金额
              SizedBox(
                width: 64,
                child: Text(
                  '¥${entry.value.toStringAsFixed(0)}',
                  style: AppTextStyles.caption(
                    color: theme.colorScheme.onPrimaryContainer,
                  ).copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 加载骨架屏
  Widget _buildSkeleton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: const SizedBox(
        height: 80,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  /// 获取分类图标
  String _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food: return '🍽️';
      case TransactionCategory.transport: return '🚗';
      case TransactionCategory.shopping: return '🛒';
      case TransactionCategory.housing: return '🏠';
      case TransactionCategory.entertainment: return '🎬';
      case TransactionCategory.medical: return '💊';
      case TransactionCategory.education: return '📚';
      case TransactionCategory.clothing: return '👔';
      case TransactionCategory.communication: return '📱';
      case TransactionCategory.daily: return '🧴';
      case TransactionCategory.social: return '👥';
      case TransactionCategory.pet: return '🐱';
      case TransactionCategory.gift: return '🎁';
      case TransactionCategory.otherExpense: return '📌';
      case TransactionCategory.salary: return '💰';
      case TransactionCategory.bonus: return '🎉';
      case TransactionCategory.investment: return '📈';
      case TransactionCategory.parttime: return '💼';
      case TransactionCategory.freelance: return '💻';
      case TransactionCategory.refund: return '↩️';
      case TransactionCategory.otherIncome: return '💵';
    }
  }

  /// 获取分类名称
  String _getCategoryName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food: return '餐饮';
      case TransactionCategory.transport: return '交通';
      case TransactionCategory.shopping: return '购物';
      case TransactionCategory.housing: return '住房';
      case TransactionCategory.entertainment: return '娱乐';
      case TransactionCategory.medical: return '医疗';
      case TransactionCategory.education: return '教育';
      case TransactionCategory.clothing: return '服饰';
      case TransactionCategory.communication: return '通讯';
      case TransactionCategory.daily: return '日用';
      case TransactionCategory.social: return '社交';
      case TransactionCategory.pet: return '宠物';
      case TransactionCategory.gift: return '礼物';
      case TransactionCategory.otherExpense: return '其他';
      case TransactionCategory.salary: return '工资';
      case TransactionCategory.bonus: return '奖金';
      case TransactionCategory.investment: return '投资';
      case TransactionCategory.parttime: return '兼职';
      case TransactionCategory.freelance: return '自由职业';
      case TransactionCategory.refund: return '退款';
      case TransactionCategory.otherIncome: return '其他';
    }
  }
}
