import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/providers.dart';
import '../config/themes/themes.dart';

/// 日记账组件
/// 用于在日视图下展示和记录当天的收入与支出
class DailyTransactionWidget extends ConsumerWidget {
  final DateTime date;

  const DailyTransactionWidget({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsByDateProvider(date));

    return transactionsAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(context, theme);
        }
        return _buildTransactionList(context, theme, ref, transactions);
      },
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💰', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '今天还没有收支记录',
              style: AppTextStyles.bodyMedium(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showTransactionForm(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('记一笔'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建收支列表
  Widget _buildTransactionList(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    List<TransactionModel> transactions,
  ) {
    // 按时间分组
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    return Column(
      children: [
        // 顶部汇总栏
        _buildDailySummaryBar(theme, totalIncome, totalExpense),

        // 收支记录列表
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              return _buildTransactionItem(
                context,
                theme,
                ref,
                transactions[index],
              );
            },
          ),
        ),

        // 底部添加按钮
        _buildAddButton(context, theme),
      ],
    );
  }

  /// 构建日汇总栏
  Widget _buildDailySummaryBar(ThemeData theme, double income, double expense) {
    final balance = income - expense;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            theme,
            label: '收入',
            value: '+¥${income.toStringAsFixed(2)}',
            color: Colors.green,
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.colorScheme.outlineVariant,
          ),
          _buildSummaryItem(
            theme,
            label: '支出',
            value: '-¥${expense.toStringAsFixed(2)}',
            color: Colors.red,
          ),
          Container(
            width: 1,
            height: 28,
            color: theme.colorScheme.outlineVariant,
          ),
          _buildSummaryItem(
            theme,
            label: '结余',
            value: '${balance >= 0 ? '+' : ''}¥${balance.toStringAsFixed(2)}',
            color: balance >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  /// 汇总项
  Widget _buildSummaryItem(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodySmall(
              color: color,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 构建收支条目
  Widget _buildTransactionItem(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    TransactionModel transaction,
  ) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(transactionNotifierProvider.notifier).deleteTransaction(transaction.id);
      },
      child: GestureDetector(
        onTap: () => _showTransactionForm(context, transaction: transaction),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              // 分类图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (transaction.isExpense
                          ? theme.colorScheme.error
                          : Colors.green)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    transaction.categoryIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 分类名称 + 备注
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryName,
                      style: AppTextStyles.bodyMedium(
                        color: theme.colorScheme.onSurface,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (transaction.note != null && transaction.note!.isNotEmpty)
                      Text(
                        transaction.note!,
                        style: AppTextStyles.caption(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 金额
              Text(
                transaction.formattedAmount,
                style: AppTextStyles.bodyMedium(
                  color: transaction.isExpense
                      ? theme.colorScheme.error
                      : Colors.green,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 底部添加按钮
  Widget _buildAddButton(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showTransactionForm(
                context,
                type: TransactionType.expense,
              ),
              icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
              label: Text(
                '记支出',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showTransactionForm(
                context,
                type: TransactionType.income,
              ),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                '记收入',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示收支表单对话框
  void _showTransactionForm(
    BuildContext context, {
    TransactionType? type,
    TransactionModel? transaction,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormDialog(
        date: date,
        type: type ?? transaction?.type,
        transaction: transaction,
      ),
    );
  }
}

/// 收支记录表单对话框
class TransactionFormDialog extends StatefulWidget {
  final DateTime date;
  final TransactionType? type;
  final TransactionModel? transaction;

  const TransactionFormDialog({
    super.key,
    required this.date,
    this.type,
    this.transaction,
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  late TransactionType _type;
  late TransactionCategory _category;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _type = widget.type ?? TransactionType.expense;
    _category = widget.transaction?.category ??
        (_type == TransactionType.expense
            ? TransactionCategory.food
            : TransactionCategory.salary);
    _amountController = TextEditingController(
      text: widget.transaction != null
          ? widget.transaction!.amount.toStringAsFixed(2)
          : '',
    );
    _noteController = TextEditingController(
      text: widget.transaction?.note ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.transaction != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 拖拽指示条
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? '编辑记录' : '记一笔',
                    style: AppTextStyles.h3(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 收入/支出切换
            _buildTypeSwitcher(theme),

            const SizedBox(height: 16),

            // 分类选择网格
            _buildCategoryGrid(theme),

            const SizedBox(height: 20),

            // 金额输入
            _buildAmountInput(theme),

            const SizedBox(height: 16),

            // 备注输入
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: '备注（选填）',
                  hintText: '添加备注...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
            ),

            const Spacer(),

            // 保存按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _save(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium,
                      ),
                    ),
                  ),
                  child: Text(
                    isEditing ? '保存修改' : '确认记录',
                    style: AppTextStyles.bodyMedium(
                      color: theme.colorScheme.onPrimary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 收入/支出切换
  Widget _buildTypeSwitcher(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Row(
          children: TransactionType.values.map((type) {
            final isSelected = _type == type;
            final color = type == TransactionType.expense
                ? theme.colorScheme.error
                : Colors.green;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _type = type;
                    // 切换类型时重置分类为默认
                    _category = type == TransactionType.expense
                        ? TransactionCategory.food
                        : TransactionCategory.salary;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == TransactionType.expense
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type == TransactionType.expense ? '支出' : '收入',
                        style: AppTextStyles.bodyMedium(
                          color: isSelected ? Colors.white : color,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 分类选择网格
  Widget _buildCategoryGrid(ThemeData theme) {
    final categories = _type == TransactionType.expense
        ? TransactionModel.expenseCategories
        : TransactionModel.incomeCategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择分类',
            style: AppTextStyles.bodySmall(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _category == category;
              return GestureDetector(
                onTap: () => setState(() => _category = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getCategoryIcon(category),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getCategoryName(category),
                        style: AppTextStyles.caption(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 金额输入
  Widget _buildAmountInput(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '金额',
            style: AppTextStyles.bodySmall(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '¥',
                  style: AppTextStyles.h2(
                    color: _type == TransactionType.expense
                        ? theme.colorScheme.error
                        : Colors.green,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\d.]'),
                      ),
                    ],
                    style: AppTextStyles.h2(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 保存
  void _save(BuildContext context) {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    final notifier = ProviderScope.containerOf(context)
        .read(transactionNotifierProvider.notifier);

    if (widget.transaction != null) {
      // 编辑模式
      notifier.updateTransaction(
        widget.transaction!.copyWith(
          type: _type,
          category: _category,
          amount: amount,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        ),
      );
    } else {
      // 新建模式
      notifier.createTransaction(
        type: _type,
        category: _category,
        amount: amount,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: widget.date,
      );
    }

    Navigator.pop(context);
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
