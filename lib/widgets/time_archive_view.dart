import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/time_archive_model.dart';
import '../providers/analytics_provider.dart';
import '../config/themes/themes.dart';

/// 时间归档视图
/// 支持按月/年维度查看事项总耗时，展开查看每日时间清单
class TimeArchiveView extends ConsumerStatefulWidget {
  const TimeArchiveView({super.key});

  @override
  ConsumerState<TimeArchiveView> createState() => _TimeArchiveViewState();
}

class _TimeArchiveViewState extends ConsumerState<TimeArchiveView> {
  // 月/年切换
  bool _isYearView = false;
  late DateTime _currentMonth; // 当前查看的月份
  int _currentYear = DateTime.now().year;

  // 展开的事项（显示每日明细）
  final Set<String> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _currentYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 顶部切换栏
        _buildTopBar(theme),

        // 内容
        Expanded(
          child: _isYearView
              ? _buildYearContent(theme)
              : _buildMonthContent(theme),
        ),
      ],
    );
  }

  // ==================== 顶部栏 ====================

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      child: Row(
        children: [
          // 上一页
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousPage,
          ),

          // 当前标题
          Expanded(
            child: GestureDetector(
              onTap: _showPeriodPicker,
              child: Center(
                child: Text(
                  _isYearView ? '$_currentYear年' : DateFormat('yyyy年MM月').format(_currentMonth),
                  style: AppTextStyles.h4(color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),

          // 下一页
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextPage,
          ),

          const SizedBox(width: 8),

          // 月/年切换
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(theme, '月', !_isYearView, () => setState(() => _isYearView = false)),
                _buildViewToggle(theme, '年', _isYearView, () => setState(() => _isYearView = true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(ThemeData theme, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _previousPage() {
    setState(() {
      if (_isYearView) {
        _currentYear--;
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      }
    });
  }

  void _nextPage() {
    setState(() {
      if (_isYearView) {
        _currentYear++;
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      }
    });
  }

  void _showPeriodPicker() {
    if (_isYearView) {
      // 年份选择器
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择年份'),
          content: SizedBox(
            width: 200,
            height: 200,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              selectedDate: DateTime(_currentYear),
              onChanged: (date) {
                setState(() => _currentYear = date.year);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      );
    } else {
      // 月份选择器
      showDatePicker(
        context: context,
        initialDate: _currentMonth,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.year,
      ).then((date) {
        if (date != null) {
          setState(() => _currentMonth = DateTime(date.year, date.month, 1));
        }
      });
    }
  }

  // ==================== 月度内容 ====================

  Widget _buildMonthContent(ThemeData theme) {
    final summaryAsync = ref.watch(monthlySummaryProvider((
      year: _currentMonth.year,
      month: _currentMonth.month,
    )));

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
      data: (summaries) {
        if (summaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📊', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  '本月暂无时间记录',
                  style: AppTextStyles.bodyMedium(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            return _buildSummaryCard(theme, summaries[index], _currentMonth.year, _currentMonth.month);
          },
        );
      },
    );
  }

  // ==================== 年度内容 ====================

  Widget _buildYearContent(ThemeData theme) {
    final summaryAsync = ref.watch(yearlySummaryProvider(_currentYear));

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
      data: (summaries) {
        if (summaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📈', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  '$_currentYear年暂无时间记录',
                  style: AppTextStyles.bodyMedium(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            return _buildSummaryCard(theme, summaries[index], _currentYear, null);
          },
        );
      },
    );
  }

  // ==================== 摘要卡片 ====================

  Widget _buildSummaryCard(
    ThemeData theme,
    TimeArchiveSummary summary,
    int year,
    int? month,
  ) {
    final isExpanded = _expandedItems.contains(summary.itemName);
    final daysInPeriod = month != null
        ? DateTime(year, month + 1, 0).day
        : (DateTime(year).isLeapYear ? 366 : 365);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // 主信息行（可展开）
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(summary.itemName);
                } else {
                  _expandedItems.add(summary.itemName);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 图标
                  Text(summary.itemIcon, style: const TextStyle(fontSize: 24)),

                  const SizedBox(width: 12),

                  // 名称和统计
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.itemName,
                          style: AppTextStyles.bodyMedium(
                            color: theme.colorScheme.onSurface,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '总计 ${summary.formattedTotal}',
                              style: AppTextStyles.caption(
                                color: theme.colorScheme.primary,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '活跃${summary.activeDays}天',
                              style: AppTextStyles.caption(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '日均${summary.formattedAvg}',
                              style: AppTextStyles.caption(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 进度条
                  SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        Text(
                          '${(summary.completionRate(daysInPeriod) * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.caption(
                            color: theme.colorScheme.primary,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: summary.completionRate(daysInPeriod),
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 展开箭头
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // 展开的每日明细
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildDailyDetails(theme, summary),
          ],
        ],
      ),
    );
  }

  /// 每日时间清单
  Widget _buildDailyDetails(ThemeData theme, TimeArchiveSummary summary) {
    final details = summary.dailyDetails;

    return Container(
      maxHeight: 300,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: details.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
        itemBuilder: (context, index) {
          final d = details[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // 日期
                SizedBox(
                  width: 70,
                  child: Text(
                    DateFormat('MM/dd').format(d.date),
                    style: AppTextStyles.caption(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // 星期
                SizedBox(
                  width: 36,
                  child: Text(
                    DateFormat('E', 'zh_CN').format(d.date),
                    style: AppTextStyles.overline(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                // 时长条
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 找出最大值作为基准
                      final maxSeconds = details.fold<int>(
                        0, (max, item) => max > item.totalSeconds ? max : item.totalSeconds,
                      );
                      final ratio = maxSeconds > 0
                          ? d.totalSeconds / maxSeconds
                          : 0;

                      return Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 8,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      );
                    },
                  ),
                ),

                // 时长文字
                SizedBox(
                  width: 60,
                  child: Text(
                    d.formattedDuration,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption(
                      color: theme.colorScheme.onSurface,
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                ),

                // 记录数
                SizedBox(
                  width: 30,
                  child: Text(
                    '${d.recordCount}次',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.overline(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
