import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务
/// 用于存储用户偏好设置和离线数据
class LocalStorageService {
  static const String _keyTheme = 'theme_preference';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyFontSize = 'font_size';
  static const String _keyShowCompletedTodos = 'show_completed_todos';
  static const String _keyCalendarView = 'calendar_view';
  static const String _keyLastSyncTime = 'last_sync_time';

  late SharedPreferences _prefs;

  /// 初始化本地存储
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 主题相关 ====================

  /// 获取主题偏好
  String getThemePreference() {
    return _prefs.getString(_keyTheme) ?? 'light';
  }

  /// 设置主题偏好
  Future<void> setThemePreference(String theme) async {
    await _prefs.setString(_keyTheme, theme);
  }

  /// 获取强调色
  String getAccentColor() {
    return _prefs.getString(_keyAccentColor) ?? '#4CAF50';
  }

  /// 设置强调色
  Future<void> setAccentColor(String color) async {
    await _prefs.setString(_keyAccentColor, color);
  }

  /// 获取字体大小
  double getFontSize() {
    return _prefs.getDouble(_keyFontSize) ?? 14.0;
  }

  /// 设置字体大小
  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_keyFontSize, size);
  }

  // ==================== 待办相关 ====================

  /// 获取是否显示已完成待办
  bool getShowCompletedTodos() {
    return _prefs.getBool(_keyShowCompletedTodos) ?? true;
  }

  /// 设置是否显示已完成待办
  Future<void> setShowCompletedTodos(bool show) async {
    await _prefs.setBool(_keyShowCompletedTodos, show);
  }

  // ==================== 日历相关 ====================

  /// 获取日历视图类型
  String getCalendarView() {
    return _prefs.getString(_keyCalendarView) ?? 'month';
  }

  /// 设置日历视图类型
  Future<void> setCalendarView(String view) async {
    await _prefs.setString(_keyCalendarView, view);
  }

  // ==================== 同步相关 ====================

  /// 获取最后同步时间
  DateTime? getLastSyncTime() {
    final timeString = _prefs.getString(_keyLastSyncTime);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  /// 设置最后同步时间
  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setString(_keyLastSyncTime, time.toIso8601String());
  }

  // ==================== 通用方法 ====================

  /// 清除所有本地数据
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  /// 移除指定键的数据
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
