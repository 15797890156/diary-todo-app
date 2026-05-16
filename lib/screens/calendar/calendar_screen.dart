import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/themes/themes.dart';

/// 日历页面
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  CalendarViewType _viewType = CalendarViewType.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(eventsByDateProvider(_selectedDate));
    final todosAsync = ref.watch(todosByDateProvider(_selectedDate));
    final diariesAsync = ref.watch(diariesByDateProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '日历',
          style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 日历组件
          CalendarWidget(
            initialDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
            onViewChanged: (type) {
              setState(() => _viewType = type);
            },
          ),

          const Divider(height: 1),

          // 月视图：显示月度收支汇总
          if (_viewType == CalendarViewType.month)
            MonthlyTransactionSummaryWidget(
              year: _selectedDate.year,
              month: _selectedDate.month,
            ),

          // 日视图：显示当天收支记录
          if (_viewType == CalendarViewType.day)
            Expanded(
              child: DailyTransactionWidget(date: _selectedDate),
            ),

          // 月/周视图：显示选中日期的事件列表
          if (_viewType != CalendarViewType.day)
            Expanded(
              child: _buildEventList(
                theme,
                eventsAsync,
                todosAsync,
                diariesAsync,
              ),
            ),
        ],
      ),

      // 悬浮添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建事件列表
  Widget _buildEventList(
    ThemeData theme,
    AsyncValue<List<CalendarEventModel>> eventsAsync,
    AsyncValue<List<TodoModel>> todosAsync,
    AsyncValue<List<DiaryModel>> diariesAsync,
  ) {
    return eventsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => EmptyState(
        icon: '😕',
        title: '加载失败',
        subtitle: error.toString(),
      ),
      data: (events) {
        final todos = todosAsync.valueOrNull ?? [];
        final diaries = diariesAsync.valueOrNull ?? [];

        if (events.isEmpty && todos.isEmpty && diaries.isEmpty) {
          return EmptyState(
            icon: '📅',
            title: '今天还没有安排',
            subtitle: '点击右下角按钮添加新事件',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 待办事项
            if (todos.isNotEmpty) ...[
              _buildSectionHeader(theme, '待办事项', Icons.check_circle),
              ...todos.map((todo) => TodoItem(
                    todo: todo,
                    onTap: () => _showTodoDetail(todo),
                    onDelete: () => _deleteTodo(todo),
                  )),
            ],

            // 日记
            if (diaries.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader(theme, '日记', Icons.book),
              ...diaries.map((diary) => DiaryCard(
                    diary: diary,
                    onTap: () => _showDiaryDetail(diary),
                    onDelete: () => _deleteDiary(diary),
                  )),
            ],

            // 日历事件
            if (events.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader(theme, '事件', Icons.event),
              ...events.map((event) => _buildEventCard(theme, event)),
            ],
          ],
        );
      },
    );
  }

  /// 构建分区标题
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.h4(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  /// 构建事件卡片
  Widget _buildEventCard(ThemeData theme, CalendarEventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border(
          left: BorderSide(
            color: _parseColor(event.color),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(event.typeIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTextStyles.bodyMedium(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(event.startTime),
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

  /// 显示添加选项
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('添加待办'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTodoDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('写日记'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddDiaryDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('添加事件'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEventDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('记一笔收支'),
                onTap: () {
                  Navigator.pop(context);
                  _showTransactionForm();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示添加待办对话框
  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => TodoFormDialog(
        onSave: (todo) {
          ref.read(todoNotifierProvider.notifier).createTodo(
                title: todo.title,
                description: todo.description,
                dueDate: _selectedDate,
                priority: todo.priority,
                icon: todo.icon,
              );
        },
      ),
    );
  }

  /// 显示添加日记对话框
  void _showAddDiaryDialog() {
    // 导航到日记编辑页面
  }

  /// 显示添加事件对话框
  void _showAddEventDialog() {
    // 显示事件添加对话框
  }

  /// 显示收支记录表单
  void _showTransactionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionFormDialog(
        date: _selectedDate,
      ),
    );
  }

  /// 显示待办详情
  void _showTodoDetail(TodoModel todo) {
    // 导航到待办详情页面
  }

  /// 显示日记详情
  void _showDiaryDetail(DiaryModel diary) {
    // 导航到日记详情页面
  }

  /// 删除待办
  Future<void> _deleteTodo(TodoModel todo) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除待办',
      content: '确定要删除"${todo.title}"吗？',
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true) {
      ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
    }
  }

  /// 删除日记
  Future<void> _deleteDiary(DiaryModel diary) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除日记',
      content: '确定要删除这篇日记吗？',
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true) {
      ref.read(diaryNotifierProvider.notifier).deleteDiary(
            diary.id,
            imageUrls: diary.images,
          );
    }
  }

  /// 解析颜色
  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.green;
    }
  }
}
