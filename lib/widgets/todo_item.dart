import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../config/themes/themes.dart';

/// 待办事项列表项组件
class TodoItem extends ConsumerWidget {
  final TodoModel todo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TodoItem({
    super.key,
    required this.todo,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: todo.isCompleted
                ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            border: Border.all(
              color: _getPriorityColor(theme).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 完成状态复选框
              GestureDetector(
                onTap: () => _toggleComplete(ref),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: todo.isCompleted
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: todo.isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              // 内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      todo.title,
                      style: AppTextStyles.todoTitle(
                        color: todo.isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                        completed: todo.isCompleted,
                      ),
                    ),

                    // 描述
                    if (todo.description != null && todo.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description!,
                        style: AppTextStyles.todoSubtitle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // 日期和优先级
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // 图标
                        if (todo.icon != null) ...[
                          Text(todo.icon!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                        ],

                        // 截止日期
                        if (todo.dueDate != null) ...[
                          Icon(
                            Icons.event,
                            size: 14,
                            color: _getDueDateColor(theme),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MM/dd').format(todo.dueDate!),
                            style: AppTextStyles.caption(
                              color: _getDueDateColor(theme),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // 优先级标签
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(theme).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            todo.priorityText,
                            style: AppTextStyles.caption(
                              color: _getPriorityColor(theme),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 编辑按钮
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 切换完成状态
  void _toggleComplete(WidgetRef ref) {
    ref.read(todoNotifierProvider.notifier).toggleComplete(
          todo.id,
          !todo.isCompleted,
        );
  }

  /// 获取优先级颜色
  Color _getPriorityColor(ThemeData theme) {
    switch (todo.priority) {
      case TodoPriority.high:
        return AppColors.priorityHigh;
      case TodoPriority.medium:
        return AppColors.priorityMedium;
      case TodoPriority.low:
        return AppColors.priorityLow;
    }
  }

  /// 获取截止日期颜色
  Color _getDueDateColor(ThemeData theme) {
    if (todo.dueDate == null) return theme.colorScheme.onSurfaceVariant;

    final now = DateTime.now();
    final dueDate = todo.dueDate!;

    if (dueDate.isBefore(now) && !todo.isCompleted) {
      return theme.colorScheme.error;
    } else if (dueDate.difference(now).inDays <= 1) {
      return AppColors.warning;
    }
    return theme.colorScheme.onSurfaceVariant;
  }
}

/// 待办事项添加/编辑弹窗
class TodoFormDialog extends StatefulWidget {
  final TodoModel? todo;
  final Function(TodoModel) onSave;

  const TodoFormDialog({
    super.key,
    this.todo,
    required this.onSave,
  });

  @override
  State<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends State<TodoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  TodoPriority _priority = TodoPriority.medium;
  String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.todo?.description ?? '');
    _dueDate = widget.todo?.dueDate;
    _priority = widget.todo?.priority ?? TodoPriority.medium;
    _selectedIcon = widget.todo?.icon;
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
        widget.todo == null ? '添加待办' : '编辑待办',
        style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题输入
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '输入待办事项标题',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 描述输入
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  hintText: '输入详细描述',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // 截止日期选择
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('截止日期'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                      : '未设置',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: _selectDueDate,
              ),

              const SizedBox(height: 8),

              // 优先级选择
              Row(
                children: [
                  const Text('优先级：'),
                  const SizedBox(width: 8),
                  ...TodoPriority.values.map((priority) {
                    final isSelected = _priority == priority;
                    return ChoiceChip(
                      label: Text(_getPriorityLabel(priority)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _priority = priority);
                        }
                      },
                      selectedColor: _getPriorityColor(priority),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 16),

              // 图标选择
              Text(
                '选择图标：',
                style: AppTextStyles.bodyMedium(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: CuteIcons.todoIcons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
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
        FilledButton(
          onPressed: _saveTodo,
          child: const Text('保存'),
        ),
      ],
    );
  }

  /// 选择截止日期
  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  /// 保存待办
  void _saveTodo() {
    if (!_formKey.currentState!.validate()) return;

    final todo = TodoModel(
      id: widget.todo?.id ?? '',
      userId: widget.todo?.userId ?? '',
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      dueDate: _dueDate,
      priority: _priority,
      icon: _selectedIcon,
      isCompleted: widget.todo?.isCompleted ?? false,
      createdAt: widget.todo?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(todo);
    Navigator.pop(context);
  }

  String _getPriorityLabel(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return '高';
      case TodoPriority.medium:
        return '中';
      case TodoPriority.low:
        return '低';
    }
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return AppColors.priorityHigh;
      case TodoPriority.medium:
        return AppColors.priorityMedium;
      case TodoPriority.low:
        return AppColors.priorityLow;
    }
  }
}
