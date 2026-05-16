import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_record_model.dart';
import '../providers/health_data_provider.dart';
import '../config/themes/themes.dart';

/// 时间表格组件
/// 以时间为纵向轴，横向展示作息、专注、事项三栏
/// 支持可拖拽调整列宽、当前时间线、已完成标记
class TimeTableWidget extends ConsumerStatefulWidget {
  final DateTime date;
  final List<TimeRecordModel> records;
  final Function(TimeRecordModel)? onRecordTap;
  final Function(TimeRecordModel)? onTimerToggle;
  final VoidCallback? onAddRecord;

  const TimeTableWidget({
    super.key,
    required this.date,
    required this.records,
    this.onRecordTap,
    this.onTimerToggle,
    this.onAddRecord,
  });

  @override
  ConsumerState<TimeTableWidget> createState() => _TimeTableWidgetState();
}

class _TimeTableWidgetState extends ConsumerState<TimeTableWidget> {
  // 时间范围：早上6点到凌晨2点
  static const int _startHour = 6;
  static const int _endHour = 26;

  // 列宽配置（可拖拽调整）
  double _timeColWidth = 52;
  double _routineColWidth = 120;
  double _focusColWidth = 120;
  double _eventColWidth = 120;

  // 拖拽状态
  int? _draggingColIndex; // 0=时间, 1=作息, 2=专注, 3=事项
  double _dragStartX = 0;
  double _dragStartWidth = 0;

  // 当前时间线刷新
  Timer? _timer;

  // 滚动控制器，用于自动滚动到当前时间
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 每分钟刷新一次当前时间线
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    // 延迟滚动到当前时间
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动到当前时间附近
  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final isToday = widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
    if (isToday && _scrollController.hasClients) {
      final currentHour = now.hour;
      final targetRow = (currentHour - _startHour) * 52.0; // 每行约52像素
      final target = (targetRow - 100).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalWidth = _timeColWidth + _routineColWidth + _focusColWidth + _eventColWidth;

    return Column(
      children: [
        // 表头
        _buildHeader(theme, totalWidth),

        // 表格内容（固定宽度，水平不滚动）
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              width: totalWidth,
              child: Column(
                children: [
                  for (int hour = _startHour; hour < _endHour; hour++)
                    _buildTimeRow(theme, hour),
                ],
              ),
            ),
          ),
        ),

        // 底部统计栏
        _buildSummaryBar(theme),
      ],
    );
  }

  // ==================== 表头 ====================

  Widget _buildHeader(ThemeData theme, double totalWidth) {
    final borderColor = theme.colorScheme.outlineVariant;

    return Container(
      width: totalWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 时间列头
          _buildHeaderCell(
            theme: theme,
            width: _timeColWidth,
            label: '时间',
            icon: '🕐',
            borderColor: borderColor,
          ),
          // 作息列头
          _buildHeaderCell(
            theme: theme,
            width: _routineColWidth,
            label: '作息',
            icon: '🛏️',
            borderColor: borderColor,
            showRightHandle: true,
            handleIndex: 1,
          ),
          // 专注列头
          _buildHeaderCell(
            theme: theme,
            width: _focusColWidth,
            label: '专注',
            icon: '🎯',
            borderColor: borderColor,
            showRightHandle: true,
            handleIndex: 2,
          ),
          // 事项列头
          _buildHeaderCell(
            theme: theme,
            width: _eventColWidth,
            label: '事项',
            icon: '📌',
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell({
    required ThemeData theme,
    required double width,
    required String label,
    required String icon,
    required Color borderColor,
    bool showRightHandle = false,
    int? handleIndex,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall(
                color: theme.colorScheme.onPrimaryContainer,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 时间行 ====================

  Widget _buildTimeRow(ThemeData theme, int hour) {
    final displayHour = hour >= 24 ? hour - 24 : hour;
    final timeStr = '${displayHour.toString().padLeft(2, '0')}:00';
    final isCurrentHour = _isCurrentHour(hour);
    final borderColor = theme.colorScheme.outlineVariant;

    // 获取该小时的记录
    final hourRecords = widget.records.where((r) {
      final rh = r.startTime.hour;
      return rh == hour || (hour >= 24 && rh == hour - 24);
    }).toList();

    final routineRecords = hourRecords.where((r) => r.type == RecordType.routine).toList();
    final focusRecords = hourRecords.where((r) => r.type == RecordType.focus).toList();
    final eventRecords = hourRecords.where((r) => r.type == RecordType.event).toList();

    return Stack(
      children: [
        // 行内容
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间列
            _buildTimeCell(theme, timeStr, isCurrentHour, borderColor),

            // 作息列
            _buildRecordCell(
              theme: theme,
              records: routineRecords,
              type: RecordType.routine,
              width: _routineColWidth,
              borderColor: borderColor,
              showRightHandle: true,
              handleIndex: 1,
            ),

            // 专注列
            _buildRecordCell(
              theme: theme,
              records: focusRecords,
              type: RecordType.focus,
              width: _focusColWidth,
              borderColor: borderColor,
              showRightHandle: true,
              handleIndex: 2,
            ),

            // 事项列
            _buildRecordCell(
              theme: theme,
              records: eventRecords,
              type: RecordType.event,
              width: _eventColWidth,
              borderColor: borderColor,
            ),
          ],
        ),

        // 当前时间线指示器（叠加在行上方）
        if (isCurrentHour)
          Positioned(
            left: 0,
            right: 0,
            top: _getCurrentTimeLineOffset(),
            child: _buildCurrentTimeLine(theme),
          ),
      ],
    );
  }

  /// 时间单元格
  Widget _buildTimeCell(ThemeData theme, String timeStr, bool isCurrentHour, Color borderColor) {
    return Container(
      width: _timeColWidth,
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentHour
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
        border: Border(
          right: BorderSide(color: borderColor, width: 0.5),
          bottom: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          timeStr,
          style: AppTextStyles.caption(
            color: isCurrentHour
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ).copyWith(
            fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w500,
            fontSize: isCurrentHour ? 13 : 11,
          ),
        ),
      ),
    );
  }

  /// 记录单元格（带边框样式）
  Widget _buildRecordCell({
    required ThemeData theme,
    required List<TimeRecordModel> records,
    required RecordType type,
    required double width,
    required Color borderColor,
    bool showRightHandle = false,
    int? handleIndex,
  }) {
    return Stack(
      children: [
        Container(
          width: width,
          height: 52,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              right: BorderSide(color: borderColor, width: 0.5),
              bottom: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          child: records.isEmpty
              ? _buildEmptyCell(theme, type)
              : _buildFilledCell(theme, records.first, records.length, type),
        ),

        // 右侧拖拽手柄
        if (showRightHandle)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                setState(() {
                  _draggingColIndex = handleIndex;
                  _dragStartX = details.globalPosition.dx;
                  _dragStartWidth = _getColWidth(handleIndex!);
                });
              },
              onHorizontalDragUpdate: (details) {
                if (_draggingColIndex != null) {
                  final dx = details.globalPosition.dx - _dragStartX;
                  final newWidth = (_dragStartWidth + dx).clamp(80.0, 250.0);
                  setState(() {
                    _setColWidth(_draggingColIndex!, newWidth);
                  });
                }
              },
              onHorizontalDragEnd: (_) {
                setState(() => _draggingColIndex = null);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 6,
                  color: _draggingColIndex == handleIndex
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 3,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _draggingColIndex == handleIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 空单元格
  Widget _buildEmptyCell(ThemeData theme, RecordType type) {
    return GestureDetector(
      onTap: () => widget.onAddRecord?.call(),
      child: Center(
        child: Icon(
          Icons.add,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.25),
        ),
      ),
    );
  }

  /// 有内容的单元格
  Widget _buildFilledCell(
    ThemeData theme,
    TimeRecordModel record,
    int totalCount,
    RecordType type,
  ) {
    final typeColor = _getTypeColor(type);
    final isCompleted = record.endTime != null &&
        record.duration != null &&
        record.duration!.inMinutes > 0 &&
        !record.isTimerRunning;

    return GestureDetector(
      onTap: () => widget.onRecordTap?.call(record),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: typeColor,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 第一行：图标 + 标题 + 完成标记
            Row(
              children: [
                // 完成勾选标记
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                // 图标
                Text(record.typeIcon, style: const TextStyle(fontSize: 12)),

                const SizedBox(width: 3),

                // 标题
                Expanded(
                  child: Text(
                    record.title,
                    style: AppTextStyles.caption(
                      color: isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ).copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // 多条记录提示
                if (totalCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${totalCount - 1}',
                      style: AppTextStyles.overline(
                        color: typeColor,
                      ).copyWith(fontSize: 9),
                    ),
                  ),
              ],
            ),

            // 第二行：计时按钮 + 时长
            if (type == RecordType.focus || record.duration != null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  children: [
                    // 计时按钮（仅专注类型）
                    if (type == RecordType.focus)
                      GestureDetector(
                        onTap: () => widget.onTimerToggle?.call(record),
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: record.isTimerRunning
                                ? theme.colorScheme.error.withOpacity(0.15)
                                : typeColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            record.isTimerRunning ? Icons.stop : Icons.play_arrow,
                            size: 10,
                            color: record.isTimerRunning
                                ? theme.colorScheme.error
                                : typeColor,
                          ),
                        ),
                      ),

                    if (type == RecordType.focus) const SizedBox(width: 4),

                    // 时长
                    Text(
                      record.formattedDuration,
                      style: AppTextStyles.overline(
                        color: theme.colorScheme.onSurfaceVariant,
                      ).copyWith(fontSize: 9),
                    ),

                    const Spacer(),

                    // 计时中闪烁指示器
                    if (record.isTimerRunning)
                      _buildPulsingDot(theme),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 计时中闪烁圆点
  Widget _buildPulsingDot(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  // ==================== 当前时间线 ====================

  /// 获取当前时间线在行内的垂直偏移
  double _getCurrentTimeLineOffset() {
    final now = DateTime.now();
    final minuteFraction = now.minute / 60.0;
    return 52.0 * minuteFraction; // 52是行高
  }

  /// 当前时间线
  Widget _buildCurrentTimeLine(ThemeData theme) {
    return Row(
      children: [
        // 时间列的圆点标记
        Container(
          width: _timeColWidth,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 2),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
        // 横跨内容列的线
        Expanded(
          child: Container(
            height: 2,
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  // ==================== 底部统计栏 ====================

  Widget _buildSummaryBar(ThemeData theme) {
    final now = DateTime.now();
    final isToday = widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;

    // 计算各类总时长
    final routineTotal = _calcTotalDuration(RecordType.routine);
    final focusTotal = _calcTotalDuration(RecordType.focus);
    final eventTotal = _calcTotalDuration(RecordType.event);
    final completedCount = widget.records.where((r) =>
        r.endTime != null && r.duration != null && r.duration!.inMinutes > 0 && !r.isTimerRunning).length;
    final totalCount = widget.records.length;
    final runningCount = widget.records.where((r) => r.isTimerRunning).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildSummaryChip(
            theme,
            icon: '🛏️',
            label: '作息',
            value: _formatDuration(routineTotal),
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildSummaryChip(
            theme,
            icon: '🎯',
            label: '专注',
            value: _formatDuration(focusTotal),
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildSummaryChip(
            theme,
            icon: '📌',
            label: '事项',
            value: '$completedCount/$totalCount',
            color: Colors.green,
          ),
          const Spacer(),
          if (runningCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$runningCount个计时中',
                    style: AppTextStyles.caption(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),

          // 手环数据同步按钮
          _buildSyncButton(theme, ref),
        ],
      ),
    );
  }

  /// 构建手环同步按钮
  Widget _buildSyncButton(ThemeData theme, WidgetRef ref) {
    final authStatus = ref.watch(healthAuthStatusProvider);
    final syncResult = ref.watch(healthSyncNotifierProvider);

    // 未授权时显示授权引导按钮
    if (authStatus != HealthAuthStatus.authorized) {
      return GestureDetector(
        onTap: () async {
          await ref.read(healthAuthStatusProvider.notifier).requestAuthorization();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⌚', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '连接手环',
                style: AppTextStyles.caption(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 已授权时显示同步按钮
    return GestureDetector(
      onTap: syncResult is AsyncLoading
          ? null
          : () async {
              final result = await ref
                  .read(healthSyncNotifierProvider.notifier)
                  .syncDate(widget.date);
              if (!mounted) return;
              ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.summary),
                  backgroundColor: result.success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncResult is AsyncLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              )
            else
              const Icon(Icons.sync, size: 14),
            const SizedBox(width: 4),
            Text(
              syncResult is AsyncLoading ? '同步中' : '同步',
              style: AppTextStyles.caption(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(
    ThemeData theme, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: AppTextStyles.caption(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption(
            color: color,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ==================== 工具方法 ====================

  Duration _calcTotalDuration(RecordType type) {
    var total = Duration.zero;
    for (final r in widget.records) {
      if (r.type == type) {
        total += r.getCurrentDuration();
      }
    }
    return total;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h${m > 0 ? '${m}m' : ''}';
    return '${m}m';
  }

  bool _isCurrentHour(int hour) {
    final now = DateTime.now();
    if (widget.date.year != now.year ||
        widget.date.month != now.month ||
        widget.date.day != now.day) return false;
    return hour == now.hour || (hour >= 24 && now.hour == hour - 24);
  }

  double _getColWidth(int index) {
    switch (index) {
      case 1: return _routineColWidth;
      case 2: return _focusColWidth;
      case 3: return _eventColWidth;
      default: return _timeColWidth;
    }
  }

  void _setColWidth(int index, double width) {
    switch (index) {
      case 1: _routineColWidth = width;
      case 2: _focusColWidth = width;
      case 3: _eventColWidth = width;
    }
  }

  Color _getTypeColor(RecordType type) {
    switch (type) {
      case RecordType.routine: return Colors.blue;
      case RecordType.focus: return Colors.orange;
      case RecordType.event: return Colors.green;
    }
  }
}

/// 时间记录添加/编辑弹窗
class TimeRecordFormDialog extends StatefulWidget {
  final TimeRecordModel? record;
  final DateTime? initialDate;
  final RecordType? initialType;
  final Function(TimeRecordModel) onSave;

  const TimeRecordFormDialog({
    super.key,
    this.record,
    this.initialDate,
    this.initialType,
    required this.onSave,
  });

  @override
  State<TimeRecordFormDialog> createState() => _TimeRecordFormDialogState();
}

class _TimeRecordFormDialogState extends State<TimeRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _date;
  late DateTime _startTime;
  DateTime? _endTime;
  RecordType _type = RecordType.event;
  String? _selectedIcon;

  final Map<RecordType, List<String>> _typeIcons = {
    RecordType.routine: ['🛏️', '🍽️', '🚿', '🏃', '🧘', '📺', '🎮', '💤'],
    RecordType.focus: ['📚', '💼', '🎨', '🎵', '✍️', '💻', '🔬', '🧠'],
    RecordType.event: ['📅', '🎉', '✈️', '🏠', '🛒', '👥', '🎁', '📞'],
  };

  @override
  void initState() {
    super.initState();
    _date = widget.record?.date ?? widget.initialDate ?? DateTime.now();
    _startTime = widget.record?.startTime ?? DateTime.now();
    _endTime = widget.record?.endTime;
    _type = widget.record?.type ?? widget.initialType ?? RecordType.event;
    _selectedIcon = widget.record?.icon;
    _titleController.text = widget.record?.title ?? '';
    _descriptionController.text = widget.record?.description ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.record == null ? '添加记录' : '编辑记录',
        style: AppTextStyles.h4(color: theme.colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 类型选择
              _buildTypeSelector(theme),
              const SizedBox(height: 16),
              // 标题
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '输入活动名称',
                ),
                validator: (v) => (v == null || v.isEmpty) ? '请输入标题' : null,
              ),
              const SizedBox(height: 12),
              // 描述
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // 时间选择
              _buildTimeSelectors(theme),
              const SizedBox(height: 16),
              // 图标选择
              _buildIconSelector(theme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('类型', style: AppTextStyles.bodySmall(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Row(
          children: RecordType.values.map((type) {
            final sel = _type == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() { _type = type; _selectedIcon = null; }),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? _color(type).withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: sel ? Border.all(color: _color(type), width: 2) : null,
                  ),
                  child: Column(
                    children: [
                      Text(type == RecordType.routine ? '🛏️' : type == RecordType.focus ? '🎯' : '📌',
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        type == RecordType.routine ? '作息' : type == RecordType.focus ? '专注' : '事项',
                        style: AppTextStyles.caption(color: sel ? _color(type) : theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSelectors(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time, size: 20),
            title: const Text('开始', style: TextStyle(fontSize: 13)),
            subtitle: Text(DateFormat('HH:mm').format(_startTime), style: const TextStyle(fontSize: 13)),
            dense: true,
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startTime));
              if (t != null) setState(() => _startTime = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
            },
          ),
        ),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_filled, size: 20),
            title: const Text('结束', style: TextStyle(fontSize: 13)),
            subtitle: Text(_endTime != null ? DateFormat('HH:mm').format(_endTime!) : '未设置', style: const TextStyle(fontSize: 13)),
            dense: true,
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _endTime != null
                    ? TimeOfDay.fromDateTime(_endTime!)
                    : TimeOfDay.fromDateTime(_startTime.add(const Duration(hours: 1))),
              );
              if (t != null) setState(() => _endTime = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('图标', style: AppTextStyles.bodySmall(color: theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _typeIcons[_type]!.map((icon) {
            final sel = _selectedIcon == icon;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = icon),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: sel ? _color(_type).withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: sel ? Border.all(color: _color(_type), width: 2) : null,
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(TimeRecordModel(
      id: widget.record?.id ?? '',
      userId: widget.record?.userId ?? '',
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      date: _date,
      startTime: _startTime,
      endTime: _endTime,
      duration: _endTime != null ? _endTime!.difference(_startTime) : widget.record?.duration,
      type: _type,
      icon: _selectedIcon,
      isTimerRunning: widget.record?.isTimerRunning ?? false,
      timerStartedAt: widget.record?.timerStartedAt,
      createdAt: widget.record?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  Color _color(RecordType t) {
    switch (t) {
      case RecordType.routine: return Colors.blue;
      case RecordType.focus: return Colors.orange;
      case RecordType.event: return Colors.green;
    }
  }
}
