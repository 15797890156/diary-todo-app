import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../config/themes/themes.dart';

/// 日历视图类型
enum CalendarViewType { month, week, day }

/// 自定义日历组件
/// 支持月视图、周视图、日视图切换
class CalendarWidget extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final Function(CalendarViewType)? onViewChanged;

  const CalendarWidget({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    this.onViewChanged,
  });

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarViewType _viewType = CalendarViewType.month;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = ref.watch(datesWithEventsProvider);

    return Column(
      children: [
        // 视图切换按钮
        _buildViewSwitcher(theme),

        // 日历主体
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _getCalendarFormat(),
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: AppTextStyles.h3(color: theme.colorScheme.onSurface),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: theme.colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTextStyles.bodySmall(
                color: theme.colorScheme.onSurface,
              ),
              weekendStyle: AppTextStyles.bodySmall(
                color: theme.colorScheme.error,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: AppTextStyles.calendarDay(
                color: theme.colorScheme.onSurface,
              ),
              weekendTextStyle: AppTextStyles.calendarDay(
                color: theme.colorScheme.error,
              ),
              todayTextStyle: AppTextStyles.calendarToday(
                color: theme.colorScheme.onPrimary,
              ),
              selectedTextStyle: AppTextStyles.calendarToday(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            eventLoader: (day) {
              if (events.contains(DateTime(day.year, day.month, day.day))) {
                return [true];
              }
              return [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDateSelected(selectedDay);
            },
            onFormatChanged: (format) {
              // 格式变化由按钮控制
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            rowHeight: _isExpanded ? 48 : 0,
          ),
        ),

        // 展开/收起按钮
        if (_viewType == CalendarViewType.month)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded ? '收起日历' : '展开日历',
                    style: AppTextStyles.bodySmall(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// 构建视图切换器
  Widget _buildViewSwitcher(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 月份标题
          Text(
            DateFormat('yyyy年MM月').format(_focusedDay),
            style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
          ),

          // 视图切换按钮组
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: CalendarViewType.values.map((type) {
                final isSelected = _viewType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _viewType = type;
                    });
                    widget.onViewChanged?.call(type);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusSmall,
                      ),
                    ),
                    child: Text(
                      _getViewTypeLabel(type),
                      style: AppTextStyles.bodySmall(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取日历格式
  CalendarFormat _getCalendarFormat() {
    switch (_viewType) {
      case CalendarViewType.month:
        return CalendarFormat.month;
      case CalendarViewType.week:
        return CalendarFormat.week;
      case CalendarViewType.day:
        return CalendarFormat.twoWeeks;
    }
  }

  /// 获取视图类型标签
  String _getViewTypeLabel(CalendarViewType type) {
    switch (type) {
      case CalendarViewType.month:
        return '月';
      case CalendarViewType.week:
        return '周';
      case CalendarViewType.day:
        return '日';
    }
  }
}

/// 时间轴组件
/// 用于显示一天内的事件时间线
class TimeLineWidget extends StatelessWidget {
  final DateTime date;
  final List<CalendarEventModel> events;

  const TimeLineWidget({
    super.key,
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              '今天还没有安排',
              style: AppTextStyles.bodyMedium(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildTimeLineItem(theme, event, index == events.length - 1);
      },
    );
  }

  Widget _buildTimeLineItem(
    ThemeData theme,
    CalendarEventModel event,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间列
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('HH:mm').format(event.startTime),
              style: AppTextStyles.bodySmall(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // 时间轴线
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _parseColor(event.color),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // 事件内容
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
                border: Border.all(
                  color: _parseColor(event.color).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.typeIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          style: AppTextStyles.bodyMedium(
                            color: theme.colorScheme.onSurface,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      style: AppTextStyles.bodySmall(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.green;
    }
  }
}
