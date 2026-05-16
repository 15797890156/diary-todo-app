import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/themes/themes.dart';

/// 待办页面
class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingTodos = ref.watch(pendingTodosProvider);
    final completedTodos = ref.watch(completedTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '待办事项',
          style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() => _showCompleted = !_showCompleted);
            },
            tooltip: _showCompleted ? '隐藏已完成' : '显示已完成',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('待完成'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingTodos.length}',
                      style: AppTextStyles.caption(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('已完成'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${completedTodos.length}',
                      style: AppTextStyles.caption(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 待完成列表
          _buildTodoList(pendingTodos, theme, isEmpty: pendingTodos.isEmpty),

          // 已完成列表
          if (_showCompleted)
            _buildTodoList(completedTodos, theme, isEmpty: completedTodos.isEmpty)
          else
            EmptyState(
              icon: '🙈',
              title: '已隐藏已完成项',
              subtitle: '点击右上角图标显示',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建待办列表
  Widget _buildTodoList(List<TodoModel> todos, ThemeData theme, {bool isEmpty = false}) {
    if (isEmpty) {
      return EmptyState(
        icon: '✅',
        title: '暂无待办事项',
        subtitle: '点击右下角按钮添加新待办',
        buttonText: '添加待办',
        onButtonPressed: _showAddTodoDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoItem(
          todo: todo,
          onTap: () => _showTodoDetail(todo),
          onEdit: () => _showEditTodoDialog(todo),
          onDelete: () => _deleteTodo(todo),
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
                dueDate: todo.dueDate,
                priority: todo.priority,
                icon: todo.icon,
              );
        },
      ),
    );
  }

  /// 显示编辑待办对话框
  void _showEditTodoDialog(TodoModel todo) {
    showDialog(
      context: context,
      builder: (context) => TodoFormDialog(
        todo: todo,
        onSave: (updatedTodo) {
          ref.read(todoNotifierProvider.notifier).updateTodo(updatedTodo);
        },
      ),
    );
  }

  /// 显示待办详情
  void _showTodoDetail(TodoModel todo) {
    // 可以导航到详情页面或显示详情弹窗
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }
}
