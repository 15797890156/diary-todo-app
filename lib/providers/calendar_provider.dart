import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'auth_provider.dart';

/// 日历事件列表状态
final calendarEventsProvider = StreamProvider<List<CalendarEventModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final db = ref.watch(databaseServiceProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  return db.getEventsByDateRange(user.uid, startOfMonth, endOfMonth);
});

/// 指定日期的事件
final eventsByDateProvider = Provider.family<List<CalendarEventModel>, DateTime>((ref, date) {
  final events = ref.watch(calendarEventsProvider).value ?? [];
  return events.where((event) {
    return event.startTime.year == date.year &&
        event.startTime.month == date.month &&
        event.startTime.day == date.day;
  }).toList();
});

/// 指定月份的事件
final eventsByMonthProvider = Provider.family<List<CalendarEventModel>, ({int year, int month})>((ref, params) {
  final events = ref.watch(calendarEventsProvider).value ?? [];
  return events.where((event) {
    return event.startTime.year == params.year &&
        event.startTime.month == params.month;
  }).toList();
});

/// 有事件的日期列表（用于日历标记）
final datesWithEventsProvider = Provider<Set<DateTime>>((ref) {
  final events = ref.watch(calendarEventsProvider).value ?? [];
  return events.map((event) {
    return DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
  }).toSet();
});

/// 日历事件操作类
class CalendarEventNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _db;
  final String _userId;

  CalendarEventNotifier(this._db, this._userId) : super(const AsyncValue.data(null));

  /// 创建事件
  Future<CalendarEventModel?> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    CalendarEventType type = CalendarEventType.event,
    String? relatedId,
    String color = '#4CAF50',
    String? icon,
    bool isAllDay = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final event = CalendarEventModel(
        id: '',
        userId: _userId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        type: type,
        relatedId: relatedId,
        color: color,
        icon: icon,
        isAllDay: isAllDay,
        createdAt: DateTime.now(),
      );
      final result = await _db.createEvent(event);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 更新事件
  Future<void> updateEvent(CalendarEventModel event) async {
    state = const AsyncValue.loading();
    try {
      await _db.updateEvent(event);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 删除事件
  Future<void> deleteEvent(String eventId) async {
    state = const AsyncValue.loading();
    try {
      await _db.deleteEvent(eventId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 日历事件操作提供者
final calendarEventNotifierProvider = StateNotifierProvider<CalendarEventNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final db = ref.watch(databaseServiceProvider);
  return CalendarEventNotifier(db, user?.uid ?? '');
});
