import 'package:flutter/material.dart';

/// 应用颜色配置 - 可爱简约风格
class AppColors {
  AppColors._();

  // ==================== 主色调 - 奶油系 ====================
  /// 主色 - 柔和粉
  static const Color primary = Color(0xFFFFB7C5);
  /// 主色浅色
  static const Color primaryLight = Color(0xFFFFE4E9);
  /// 主色深色
  static const Color primaryDark = Color(0xFFFF91A4);

  // ==================== 辅助色 - 马卡龙 ====================
  /// 薄荷绿
  static const Color mint = Color(0xFFB8E0D2);
  /// 天空蓝
  static const Color sky = Color(0xFFA8D8EA);
  /// 奶油黄
  static const Color cream = Color(0xFFFDF6E3);
  /// 薰衣草紫
  static const Color lavender = Color(0xFFE6E6FA);
  /// 蜜桃橙
  static const Color peach = Color(0xFFFFDAB9);

  // ==================== 背景色 ====================
  /// 页面背景 - 奶油白
  static const Color background = Color(0xFFFDF8F3);
  /// 卡片背景 - 纯白
  static const Color card = Color(0xFFFFFFFF);
  /// 卡片背景2 - 淡粉
  static const Color cardPink = Color(0xFFFFF5F7);
  /// 卡片背景3 - 淡蓝
  static const Color cardBlue = Color(0xFFF0F9FF);
  /// 卡片背景4 - 淡绿
  static const Color cardGreen = Color(0xFFF0FDF4);

  // ==================== 文字色 ====================
  /// 主文字 - 深灰
  static const Color textPrimary = Color(0xFF4A4A4A);
  /// 次要文字 - 中灰
  static const Color textSecondary = Color(0xFF8B8B8B);
  /// 辅助文字 - 浅灰
  static const Color textHint = Color(0xFFBDBDBD);
  /// 反色文字 - 白
  static const Color textWhite = Color(0xFFFFFFFF);

  // ==================== 边框/分割线 ====================
  /// 边框 - 极浅灰
  static const Color border = Color(0xFFEEEEEE);
  /// 分割线
  static const Color divider = Color(0xFFF0F0F0);

  // ==================== 功能色 ====================
  /// 成功 - 薄荷绿
  static const Color success = Color(0xFF95D5B2);
  /// 警告 - 奶油黄
  static const Color warning = Color(0xFFFFE066);
  /// 错误 - 柔和红
  static const Color error = Color(0xFFFFB4B4);
  /// 信息 - 天空蓝
  static const Color info = Color(0xFFA8D8EA);

  // ==================== 优先级颜色 ====================
  static const Color priorityHigh = Color(0xFFFFB4B4);
  static const Color priorityMedium = Color(0xFFFFE4B5);
  static const Color priorityLow = Color(0xFFB8E0D2);

  // ==================== 心情颜色 - 柔和系 ====================
  static const Color moodHappy = Color(0xFFFFF4B8);
  static const Color moodExcited = Color(0xFFFFD6E0);
  static const Color moodCalm = Color(0xFFD4E5ED);
  static const Color moodSad = Color(0xFFDDE2E5);
  static const Color moodAngry = Color(0xFFFFD6D6);
  static const Color moodTired = Color(0xFFE8E8E8);
  static const Color moodLove = Color(0xFFFFD6E0);
  static const Color moodThinking = Color(0xFFE2DDE5);

  // ==================== 渐变色 ====================
  static const List<Color> gradientPink = [Color(0xFFFFE4E9), Color(0xFFFFB7C5)];
  static const List<Color> gradientBlue = [Color(0xFFE0F2FE), Color(0xFFA8D8EA)];
  static const List<Color> gradientGreen = [Color(0xFFE0F7EF), Color(0xFFB8E0D2)];
  static const List<Color> gradientPurple = [Color(0xFFF3E8FF), Color(0xFFE6E6FA)];

  // ==================== 兼容旧代码的别名 ====================
  static const Color primaryPink = primary;
  static const Color primaryGreen = mint;
  static const Color primaryBlue = sky;
  static const Color primaryOrange = peach;
  static const Color primaryTeal = mint;
  static const Color primaryYellow = cream;
  static const Color primaryPurple = lavender;

  static const Color cutePink = primary;
  static const Color cutePurple = lavender;
  static const Color cuteBlue = sky;
  static const Color cuteYellow = cream;
  static const Color cuteGreen = mint;

  static const Color grey100 = Color(0xFFFDF8F3);
  static const Color grey200 = Color(0xFFF5F5F5);
  static const Color grey300 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFE0E0E0);
  static const Color grey500 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF8B8B8B);
  static const Color grey700 = Color(0xFF6B6B6B);
  static const Color grey800 = Color(0xFF4A4A4A);
  static const Color grey900 = Color(0xFF2D2D2D);
}
