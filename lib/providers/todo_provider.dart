import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'auth_provider.dart';

/// 待办事项列表状态
final todosProvider = StreamProvider<List<TodoModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final db = ref.watch(databaseServiceProvider);
  return db.getTodos(user.uid);
});

/// 待完成的待办事项
final pendingTodosProvider = Provider<List<TodoModel>>((ref) {
  final todos = ref.watch(todosProvider).value ?? [];
  return todos.where((todo) => !todo.isCompleted).toList();
});

/// 已完成的待办事项
final completedTodosProvider = Provider<List<TodoModel>>((ref) {
  final todos = ref.watch(todosProvider).value ?? [];
  return todos.where((todo) => todo.isCompleted).toList();
});

/// 指定日期的待办事项
final todosByDateProvider = Provider.family<List<TodoModel>, DateTime>((ref, date) {
  final todos = ref.watch(todosProvider).value ?? [];
  return todos.where((todo) {
    if (todo.dueDate == null) return false;
    return todo.dueDate!.year == date.year &&
        todo.dueDate!.month == date.month &&
        todo.dueDate!.day == date.day;
  }).toList();
});

/// 待办事项操作类
class TodoNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _db;
  final String _userId;

  TodoNotifier(this._db, this._userId) : super(const AsyncValue.data(null));

  /// 创建待办事项
  Future<TodoModel?> createTodo({
    required String title,
    String? description,
    DateTime? dueDate,
    TodoPriority priority = TodoPriority.medium,
    String? icon,
    String? color,
  }) async {
    state = const AsyncValue.loading();
    try {
      final todo = TodoModel(
        id: '',
        userId: _userId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _db.createTodo(todo);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 更新待办事项
  Future<void> updateTodo(TodoModel todo) async {
    state = const AsyncValue.loading();
    try {
      await _db.updateTodo(todo.copyWith(updatedAt: DateTime.now()));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 删除待办事项
  Future<void> deleteTodo(String todoId) async {
    state = const AsyncValue.loading();
    try {
      await _db.deleteTodo(todoId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 切换完成状态
  Future<void> toggleComplete(String todoId, bool isCompleted) async {
    state = const AsyncValue.loading();
    try {
      await _db.toggleTodoComplete(todoId, isCompleted);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 待办事项操作提供者
final todoNotifierProvider = StateNotifierProvider<TodoNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final db = ref.watch(databaseServiceProvider);
  return TodoNotifier(db, user?.uid ?? '');
});
