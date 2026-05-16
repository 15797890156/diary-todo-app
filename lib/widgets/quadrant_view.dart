import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quadrant_task_model.dart';
import '../config/themes/themes.dart';

/// 四象限视图组件
/// 紧急/重要矩阵，四个象限分别管理任务
class QuadrantView extends ConsumerStatefulWidget {
  final List<QuadrantTaskModel> tasks;
  final Function(QuadrantTaskModel)? onTaskTap;
  final Function(QuadrantTaskModel)? onTaskComplete;
  final VoidCallback? onAddTask;

  const QuadrantView({
    super.key,
    required this.tasks,
    this.onTaskTap,
    this.onTaskComplete,
    this.onAddTask,
  });

  @override
  ConsumerState<QuadrantView> createState() => _QuadrantViewState();
}

class _QuadrantViewState extends ConsumerState<QuadrantView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 按象限分组
    final q1 = _getTasksByQuadrant(QuadrantType.urgentImportant);
    final q2 = _getTasksByQuadrant(QuadrantType.notUrgentImportant);
    final q3 = _getTasksByQuadrant(QuadrantType.urgentNotImportant);
    final q4 = _getTasksByQuadrant(QuadrantType.notUrgentNotImportant);

    return Column(
      children: [
        // 轴标签
        _buildAxisLabels(theme),

        const SizedBox(height: 4),

        // 四象限网格
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final halfWidth = (constraints.maxWidth - 1) / 2;
              final halfHeight = (constraints.maxHeight - 1) / 2;

              return Column(
                children: [
                  // 上半部分：紧急
                  Expanded(
                    child: Row(
                      children: [
                        // Q1: 紧急且重要
                        _buildQuadrant(
                          theme: theme,
                          tasks: q1,
                          quadrant: QuadrantType.urgentImportant,
                          width: halfWidth,
                          height: halfHeight,
                        ),
                        // Q2: 不紧急但重要
                        _buildQuadrant(
                          theme: theme,
                          tasks: q2,
                          quadrant: QuadrantType.notUrgentImportant,
                          width: halfWidth,
                          height: halfHeight,
                        ),
                      ],
                    ),
                  ),
                  // 下半部分：不紧急
                  Expanded(
                    child: Row(
                      children: [
                        // Q3: 紧急但不重要
                        _buildQuadrant(
                          theme: theme,
                          tasks: q3,
                          quadrant: QuadrantType.urgentNotImportant,
                          width: halfWidth,
                          height: halfHeight,
                        ),
                        // Q4: 不紧急不重要
                        _buildQuadrant(
                          theme: theme,
                          tasks: q4,
                          quadrant: QuadrantType.notUrgentNotImportant,
                          width: halfWidth,
                          height: halfHeight,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建轴标签
  Widget _buildAxisLabels(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // 左侧Y轴标签
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '紧急 ↑',
                style: AppTextStyles.caption(
                  color: theme.colorScheme.error,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          // 右侧Y轴标签
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '重要 →',
                style: AppTextStyles.caption(
                  color: theme.colorScheme.primary,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个象限
  Widget _buildQuadrant({
    required ThemeData theme,
    required List<QuadrantTaskModel> tasks,
    required QuadrantType quadrant,
    required double width,
    required double height,
  }) {
    final color = _getQuadrantColor(quadrant);
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = tasks.where((t) => t.isCompleted).toList();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 象限标题栏
          _buildQuadrantHeader(theme, quadrant, pendingTasks.length, completedTasks.length),

          // 任务列表
          Expanded(
            child: pendingTasks.isEmpty && completedTasks.isEmpty
                ? _buildEmptyQuadrant(theme, quadrant)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    children: [
                      // 待完成任务
                      ...pendingTasks.map((task) => _buildTaskItem(theme, task)),
                      // 已完成任务（折叠显示）
                      if (completedTasks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildCompletedSection(theme, completedTasks),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建象限标题栏
  Widget _buildQuadrantHeader(
    ThemeData theme,
    QuadrantType quadrant,
    int pendingCount,
    int completedCount,
  ) {
    final color = _getQuadrantColor(quadrant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            _getQuadrantIcon(quadrant),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _getQuadrantTitle(quadrant),
              style: AppTextStyles.bodySmall(
                color: color,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // 待完成数
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$pendingCount',
                style: AppTextStyles.overline(
                  color: color,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 4),
          // 添加按钮
          GestureDetector(
            onTap: () => widget.onAddTask?.call(),
            child: Icon(
              Icons.add_circle_outline,
              size: 18,
              color: color.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建任务项
  Widget _buildTaskItem(ThemeData theme, QuadrantTaskModel task) {
    final color = _getQuadrantColor(task.quadrant);

    return GestureDetector(
      onTap: () => widget.onTaskTap?.call(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // 完成复选框
            GestureDetector(
              onTap: () => widget.onTaskComplete?.call(task),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 图标
            if (task.icon != null) ...[
              Text(task.icon!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],

            // 标题
            Expanded(
              child: Text(
                task.title,
                style: AppTextStyles.caption(
                  color: theme.colorScheme.onSurface,
                ).copyWith(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 截止日期
            if (task.dueDate != null)
              Text(
                '${task.dueDate!.month}/${task.dueDate!.day}',
                style: AppTextStyles.overline(
                  color: theme.colorScheme.onSurfaceVariant,
                ).copyWith(fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建已完成区域
  Widget _buildCompletedSection(ThemeData theme, List<QuadrantTaskModel> completedTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '已完成 (${completedTasks.length})',
          style: AppTextStyles.overline(
            color: theme.colorScheme.onSurfaceVariant,
          ).copyWith(fontSize: 9),
        ),
        const SizedBox(height: 2),
        ...completedTasks.take(3).map((task) => Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.title,
                      style: AppTextStyles.overline(
                        color: theme.colorScheme.onSurfaceVariant,
                      ).copyWith(
                        decoration: TextDecoration.lineThrough,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
        if (completedTasks.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              '还有${completedTasks.length - 3}项...',
              style: AppTextStyles.overline(
                color: theme.colorScheme.onSurfaceVariant,
              ).copyWith(fontSize: 9),
            ),
          ),
      ],
    );
  }

  /// 空象限
  Widget _buildEmptyQuadrant(ThemeData theme, QuadrantType quadrant) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getQuadrantIcon(quadrant),
            style: TextStyle(fontSize: 28, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
          ),
          const SizedBox(height: 4),
          Text(
            _getQuadrantAdvice(quadrant),
            style: AppTextStyles.caption(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 工具方法 ====================

  List<QuadrantTaskModel> _getTasksByQuadrant(QuadrantType type) {
    return widget.tasks.where((t) => t.quadrant == type).toList();
  }

  Color _getQuadrantColor(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant: return const Color(0xFFF44336);
      case QuadrantType.notUrgentImportant: return const Color(0xFF4CAF50);
      case QuadrantType.urgentNotImportant: return const Color(0xFFFF9800);
      case QuadrantType.notUrgentNotImportant: return const Color(0xFF9E9E9E);
    }
  }

  String _getQuadrantIcon(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant: return '🔥';
      case QuadrantType.notUrgentImportant: return '💎';
      case QuadrantType.urgentNotImportant: return '⏰';
      case QuadrantType.notUrgentNotImportant: return '☕';
    }
  }

  String _getQuadrantTitle(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant: return '紧急且重要';
      case QuadrantType.notUrgentImportant: return '重要不紧急';
      case QuadrantType.urgentNotImportant: return '紧急不重要';
      case QuadrantType.notUrgentNotImportant: return '不紧急不重要';
    }
  }

  String _getQuadrantAdvice(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant: return '立即做';
      case QuadrantType.notUrgentImportant: return '计划做';
      case QuadrantType.urgentNotImportant: return '委托做';
      case QuadrantType.notUrgentNotImportant: return '少做';
    }
  }
}

/// 四象限任务添加/编辑弹窗
class QuadrantTaskFormDialog extends StatefulWidget {
  final QuadrantTaskModel? task;
  final QuadrantType? initialQuadrant;
  final Function(QuadrantTaskModel) onSave;

  const QuadrantTaskFormDialog({
    super.key,
    this.task,
    this.initialQuadrant,
    required this.onSave,
  });

  @override
  State<QuadrantTaskFormDialog> createState() => _QuadrantTaskFormDialogState();
}

class _QuadrantTaskFormDialogState extends State<QuadrantTaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late QuadrantType _quadrant;
  DateTime? _dueDate;
  int _priority = 5;
  String? _selectedIcon;

  final List<String> _icons = [
    '🔥', '⭐', '💡', '📚', '💼', '🎨', '🎵', '✍️',
    '💻', '🏃', '🧘', '🏠', '🛒', '👥', '🎁', '📞',
    '🎯', '🏆', '💪', '⚡', '📌', '📎', '🔔', '⏰',
  ];

  @override
  void initState() {
    super.initState();
    _quadrant = widget.task?.quadrant ?? widget.initialQuadrant ?? QuadrantType.urgentImportant;
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? 5;
    _selectedIcon = widget.task?.icon;
    _titleController.text = widget.task?.title ?? '';
    _descriptionController.text = widget.task?.description ?? '';
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
        widget.task == null ? '添加任务' : '编辑任务',
        style: AppTextStyles.h4(color: theme.colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 象限选择
              Text('象限', style: AppTextStyles.bodySmall(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              _buildQuadrantSelector(theme),

              const SizedBox(height: 16),

              // 标题
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '任务名称',
                  hintText: '输入任务名称',
                ),
                validator: (v) => (v == null || v.isEmpty) ? '请输入任务名称' : null,
              ),

              const SizedBox(height: 12),

              // 描述
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '描述（可选）'),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // 截止日期
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event, size: 20),
                title: const Text('截止日期', style: TextStyle(fontSize: 13)),
                subtitle: Text(
                  _dueDate != null
                      ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                      : '未设置',
                  style: const TextStyle(fontSize: 13),
                ),
                dense: true,
                onTap: _selectDueDate,
              ),

              const SizedBox(height: 8),

              // 优先级滑块
              Row(
                children: [
                  Text('优先级', style: AppTextStyles.bodySmall(color: theme.colorScheme.onSurface)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_priority',
                      onChanged: (v) => setState(() => _priority = v.toInt()),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(_priority).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_priority',
                        style: AppTextStyles.caption(
                          color: _getPriorityColor(_priority),
                        ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 图标选择
              Text('图标', style: AppTextStyles.bodySmall(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _icons.map((icon) {
                  final sel = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: sel
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: sel
                            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                            : null,
                      ),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
                    ),
                  );
                }).toList(),
              ),
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

  Widget _buildQuadrantSelector(ThemeData theme) {
    return Row(
      children: QuadrantType.values.map((q) {
        final sel = _quadrant == q;
        final color = _getQuadrantColor(q);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _quadrant = q),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? color.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: sel ? Border.all(color: color, width: 2) : null,
              ),
              child: Column(
                children: [
                  Text(_getQuadrantIcon(q), style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 3),
                  Text(
                    _getQuadrantShortTitle(q),
                    style: AppTextStyles.overline(
                      color: sel ? color : theme.colorScheme.onSurfaceVariant,
                    ).copyWith(fontWeight: sel ? FontWeight.bold : null, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(QuadrantTaskModel(
      id: widget.task?.id ?? '',
      userId: widget.task?.userId ?? '',
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      quadrant: _quadrant,
      isCompleted: widget.task?.isCompleted ?? false,
      dueDate: _dueDate,
      priority: _priority,
      icon: _selectedIcon,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  Color _getQuadrantColor(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant: return const Color(0xFFF44336);
      case QuadrantType.notUrgentImportant: return const Color(0xFF4CAF50);
      case QuadrantType.urgentNotImportant: return const Color(0xFFFF9800);
      case QuadrantType.notUrgentNotImportant: return const Color(0xFF9E9E9E);
    }
  }

  String _getQuadrantIcon(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant: return '🔥';
      case QuadrantType.notUrgentImportant: return '💎';
      case QuadrantType.urgentNotImportant: return '⏰';
      case QuadrantType.notUrgentNotImportant: return '☕';
    }
  }

  String _getQuadrantShortTitle(QuadrantType type) {
    switch (type) {
      case QuadrantType.urgentImportant: return '紧急重要';
      case QuadrantType.notUrgentImportant: return '重要';
      case QuadrantType.urgentNotImportant: return '紧急';
      case QuadrantType.notUrgentNotImportant: return '其他';
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return const Color(0xFFF44336);
    if (priority >= 5) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }
}
