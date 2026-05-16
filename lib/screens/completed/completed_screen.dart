import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/completed_item_model.dart';
import '../../providers/completed_items_provider.dart';
import '../../config/themes/themes.dart';

/// 完成板块页面
/// 汇总展示所有已完成的事项，支持按类型和时间筛选
class CompletedScreen extends ConsumerWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(completedSummaryProvider);
    final displayedItemsAsync = ref.watch(displayedCompletedItemsProvider);
    final selectedType = ref.watch(selectedCompletedTypeProvider);
    final currentFilter = ref.watch(timeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '完成事项',
          style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          // 时间筛选下拉
          PopupMenuButton<TimeFilter>(
            initialValue: currentFilter,
            onSelected: (filter) {
              ref.read(timeFilterProvider.notifier).state = filter;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TimeFilter.all,
                child: Text('全部'),
              ),
              const PopupMenuItem(
                value: TimeFilter.today,
                child: Text('今日'),
              ),
              const PopupMenuItem(
                value: TimeFilter.week,
                child: Text('本周'),
              ),
              const PopupMenuItem(
                value: TimeFilter.month,
                child: Text('本月'),
              ),
              const PopupMenuItem(
                value: TimeFilter.year,
                child: Text('本年'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _getFilterLabel(currentFilter),
                    style: AppTextStyles.bodyMedium(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计概览卡片
          summaryAsync.when(
            loading: () => _buildSkeletonCard(theme),
            error: (_, __) => const SizedBox.shrink(),
            data: (summary) => _buildSummaryCard(theme, summary),
          ),

          // 类型筛选标签栏
          _buildTypeFilterBar(theme, ref, selectedType),

          const Divider(height: 1),

          // 完成事项列表
          Expanded(
            child: displayedItemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  '加载失败: $error',
                  style: AppTextStyles.bodyMedium(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              data: (items) => _buildItemsList(theme, items, selectedType),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计概览卡片
  Widget _buildSummaryCard(ThemeData theme, CompletedSummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          // 总完成数
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🏆',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                '已完成 ${summary.totalCount} 项',
                style: AppTextStyles.h4(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 时间维度统计
          Row(
            children: [
              _buildStatItem(
                theme,
                label: '今日',
                value: '${summary.todayCount}',
                icon: Icons.today,
              ),
              _buildStatItem(
                theme,
                label: '本周',
                value: '${summary.weekCount}',
                icon: Icons.calendar_view_week,
              ),
              _buildStatItem(
                theme,
                label: '本月',
                value: '${summary.monthCount}',
                icon: Icons.calendar_month,
              ),
            ],
          ),

          // 分类统计（横向滚动）
          if (summary.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: summary.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = summary.categories[index];
                  return _buildCategoryChip(theme, category);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h4(
              color: theme.colorScheme.onPrimaryContainer,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: AppTextStyles.caption(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类统计卡片
  Widget _buildCategoryChip(ThemeData theme, CompletedCategoryStats category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            '${category.count}',
            style: AppTextStyles.bodySmall(
              color: theme.colorScheme.onPrimaryContainer,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            category.name,
            style: AppTextStyles.caption(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建类型筛选栏
  Widget _buildTypeFilterBar(
    ThemeData theme,
    WidgetRef ref,
    CompletedItemType? selectedType,
  ) {
    final types = [
      null, // 全部
      ...CompletedItemType.values,
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = selectedType == type;

          return ChoiceChip(
            label: Text(
              type == null ? '全部' : _getTypeLabel(type),
            ),
            selected: isSelected,
            onSelected: (_) {
              ref.read(selectedCompletedTypeProvider.notifier).state = type;
            },
            avatar: type != null
                ? Text(_getTypeIcon(type))
                : const Icon(Icons.all_inclusive, size: 16),
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: AppTextStyles.bodySmall(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }

  /// 构建事项列表
  Widget _buildItemsList(
    ThemeData theme,
    List<CompletedItemModel> items,
    CompletedItemType? selectedType,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(theme, selectedType);
    }

    // 按日期分组
    final groupedItems = _groupItemsByDate(items);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final dateGroup = groupedItems[index];
        return _buildDateGroup(theme, dateGroup);
      },
    );
  }

  /// 按日期分组
  List<DateGroup> _groupItemsByDate(List<CompletedItemModel> items) {
    final groups = <DateTime, List<CompletedItemModel>>{};

    for (final item in items) {
      final date = DateTime(
        item.completedAt.year,
        item.completedAt.month,
        item.completedAt.day,
      );
      groups.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedDates
        .map((date) => DateGroup(
              date: date,
              items: groups[date]!,
            ))
        .toList();
  }

  /// 构建日期分组
  Widget _buildDateGroup(ThemeData theme, DateGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDate(group.date),
                  style: AppTextStyles.caption(
                    color: theme.colorScheme.onPrimaryContainer,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${group.items.length} 项',
                style: AppTextStyles.caption(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // 该日期的事项列表
        ...group.items.map((item) => _buildItemCard(theme, item)),

        const SizedBox(height: 8),
      ],
    );
  }

  /// 构建事项卡片
  Widget _buildItemCard(ThemeData theme, CompletedItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // 类型图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _parseColor(item.typeColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                item.typeIcon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.bodyMedium(
                          color: theme.colorScheme.onSurface,
                        ).copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 分类标签
                    if (item.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category!,
                          style: AppTextStyles.caption(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: AppTextStyles.caption(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(item.completedAt),
                  style: AppTextStyles.caption(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(ThemeData theme, CompletedItemType? selectedType) {
    final typeLabel = selectedType == null ? '' : _getTypeLabel(selectedType);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎯', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            selectedType == null ? '还没有完成的事项' : '还没有完成的$typeLabel',
            style: AppTextStyles.bodyMedium(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '去完成一些事情吧！',
            style: AppTextStyles.caption(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建骨架屏卡片
  Widget _buildSkeletonCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      height: 150,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 获取筛选标签
  String _getFilterLabel(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.all:
        return '全部';
      case TimeFilter.today:
        return '今日';
      case TimeFilter.week:
        return '本周';
      case TimeFilter.month:
        return '本月';
      case TimeFilter.year:
        return '本年';
    }
  }

  /// 获取类型标签
  String _getTypeLabel(CompletedItemType type) {
    switch (type) {
      case CompletedItemType.todo:
        return '待办';
      case CompletedItemType.timeRecord:
        return '时间';
      case CompletedItemType.book:
        return '书籍';
      case CompletedItemType.movie:
        return '电影';
      case CompletedItemType.product:
        return '产品';
      case CompletedItemType.diary:
        return '日记';
    }
  }

  /// 获取类型图标
  String _getTypeIcon(CompletedItemType type) {
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

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAtSameMomentAs(today)) {
      return '今天';
    } else if (dateOnly.isAtSameMomentAs(yesterday)) {
      return '昨天';
    } else {
      return DateFormat('MM月dd日').format(date);
    }
  }

  /// 解析颜色
  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// 日期分组数据类
class DateGroup {
  final DateTime date;
  final List<CompletedItemModel> items;

  DateGroup({
    required this.date,
    required this.items,
  });
}
