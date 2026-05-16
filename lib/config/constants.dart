/// 应用常量定义
class AppConstants {
  AppConstants._();

  // ==================== 应用信息 ====================
  static const String appName = '日记待办';
  static const String appVersion = '1.0.0';

  // ==================== 日期格式 ====================
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String monthFormat = 'yyyy年MM月';
  static const String weekDayFormat = 'EEEE';

  // ==================== 动画时长 ====================
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // ==================== UI 尺寸 ====================
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // ==================== 待办优先级 ====================
  static const int priorityLow = 0;
  static const int priorityMedium = 1;
  static const int priorityHigh = 2;

  // ==================== 日历视图类型 ====================
  static const String calendarViewMonth = 'month';
  static const String calendarViewWeek = 'week';
  static const String calendarViewDay = 'day';

  // ==================== 主题名称 ====================
  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const String themeCute = 'cute';
  static const String themeNature = 'nature';
  static const String themeOcean = 'ocean';
  static const String themeSunset = 'sunset';

  // ==================== 错误信息 ====================
  static const String errorNetwork = '网络连接失败，请检查网络设置';
  static const String errorUnknown = '发生未知错误，请重试';
  static const String errorAuth = '认证失败，请重新登录';
  static const String errorPermission = '权限不足，请在设置中开启';
}

/// 路由名称
class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String calendar = '/calendar';
  static const String todo = '/todo';
  static const String diary = '/diary';
  static const String settings = '/settings';
  static const String diaryDetail = '/diary/detail';
  static const String todoDetail = '/todo/detail';
}

/// 共享偏好键名
class PreferenceKeys {
  PreferenceKeys._();

  static const String theme = 'theme_preference';
  static const String accentColor = 'accent_color';
  static const String fontSize = 'font_size';
  static const String showCompleted = 'show_completed_todos';
  static const String calendarView = 'calendar_view';
  static const String lastSync = 'last_sync_time';
}
