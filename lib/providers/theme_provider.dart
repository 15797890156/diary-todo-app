import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';
import 'auth_provider.dart';

/// 主题类型
enum AppTheme {
  light,   // 浅色主题
  dark,    // 深色主题
  cute,    // 可爱主题
  nature,  // 自然主题
  ocean,   // 海洋主题
  sunset,  // 日落主题
}

/// 主题状态
class ThemeState {
  final AppTheme theme;
  final Color accentColor;
  final double fontSize;

  ThemeState({
    required this.theme,
    required this.accentColor,
    required this.fontSize,
  });

  ThemeState copyWith({
    AppTheme? theme,
    Color? accentColor,
    double? fontSize,
  }) {
    return ThemeState(
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

/// 主题状态管理器
class ThemeNotifier extends StateNotifier<ThemeState> {
  final LocalStorageService _localStorage;

  ThemeNotifier(this._localStorage) : super(ThemeState(
    theme: AppTheme.light,
    accentColor: Colors.green,
    fontSize: 14.0,
  )) {
    _loadTheme();
  }

  /// 从本地存储加载主题设置
  Future<void> _loadTheme() async {
    final themeName = _localStorage.getThemePreference();
    final accentColorHex = _localStorage.getAccentColor();
    final fontSize = _localStorage.getFontSize();

    final theme = AppTheme.values.firstWhere(
      (t) => t.name == themeName,
      orElse: () => AppTheme.light,
    );

    final accentColor = _hexToColor(accentColorHex);

    state = ThemeState(
      theme: theme,
      accentColor: accentColor,
      fontSize: fontSize,
    );
  }

  /// 设置主题
  Future<void> setTheme(AppTheme theme) async {
    await _localStorage.setThemePreference(theme.name);
    state = state.copyWith(theme: theme);
  }

  /// 设置强调色
  Future<void> setAccentColor(Color color) async {
    final hex = _colorToHex(color);
    await _localStorage.setAccentColor(hex);
    state = state.copyWith(accentColor: color);
  }

  /// 设置字体大小
  Future<void> setFontSize(double size) async {
    await _localStorage.setFontSize(size);
    state = state.copyWith(fontSize: size);
  }

  /// 颜色转十六进制字符串
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// 十六进制字符串转颜色
  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.green;
    }
  }
}

/// 主题提供者
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return ThemeNotifier(localStorage);
});

/// 当前主题数据
final themeDataProvider = Provider<ThemeData>((ref) {
  final themeState = ref.watch(themeProvider);
  return _getThemeData(themeState.theme, themeState.accentColor, themeState.fontSize);
});

/// 获取主题数据
ThemeData _getThemeData(AppTheme theme, Color accentColor, double fontSize) {
  switch (theme) {
    case AppTheme.light:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: accentColor,
        fontFamily: 'PingFang SC',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize - 2),
        ),
      );
    case AppTheme.dark:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: accentColor,
        fontFamily: 'PingFang SC',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize - 2),
        ),
      );
    case AppTheme.cute:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.pink,
        fontFamily: 'PingFang SC',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize - 2),
        ),
      );
    case AppTheme.nature:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
        fontFamily: 'PingFang SC',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize - 2),
        ),
      );
    case AppTheme.ocean:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        fontFamily: 'PingFang SC',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize - 2),
        ),
      );
    case AppTheme.sunset:
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.orange,
        fontFamily: 'PingFang SC',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize),
          bodyMedium: TextStyle(fontSize: fontSize - 2),
        ),
      );
  }
}
