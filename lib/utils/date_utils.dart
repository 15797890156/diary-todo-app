/// 工具类：日期处理
import 'package:intl/intl.dart';

class DateUtils {
  DateUtils._();

  /// 格式化日期为 yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 格式化时间为 HH:mm
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// 格式化日期时间为 yyyy-MM-dd HH:mm
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// 格式化月份为 yyyy年MM月
  static String formatMonth(DateTime date) {
    return DateFormat('yyyy年MM月').format(date);
  }

  /// 格式化星期几
  static String formatWeekDay(DateTime date) {
    return DateFormat('EEEE', 'zh_CN').format(date);
  }

  /// 获取今天的开始时间
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 获取今天的结束时间
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// 获取本周的第一天（周一）
  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - weekday + 1);
  }

  /// 获取本月的第一天
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取本月的最后一天
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 判断是否是今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 判断是否是昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// 判断是否是明天
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// 获取相对时间描述
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) return '今天';
    if (isYesterday(date)) return '昨天';
    if (isTomorrow(date)) return '明天';

    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff > 0 && diff <= 7) {
      return '${diff}天后';
    } else if (diff < 0 && diff >= -7) {
      return '${-diff}天前';
    }

    return formatDate(date);
  }
}
