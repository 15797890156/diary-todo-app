import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用文本样式
class AppTextStyles {
  AppTextStyles._();

  // ==================== 标题样式 ====================
  static TextStyle h1({
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: 28,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.5,
    );
  }

  static TextStyle h2({
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontSize: 24,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.3,
    );
  }

  static TextStyle h3({
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: 20,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.2,
    );
  }

  static TextStyle h4({
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: 18,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // ==================== 正文样式 ====================
  static TextStyle bodyLarge({
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle bodyMedium({
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle bodySmall({
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: 12,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // ==================== 特殊样式 ====================
  static TextStyle caption({
    Color? color,
  }) {
    return TextStyle(
      fontSize: 11,
      color: color ?? AppColors.grey600,
    );
  }

  static TextStyle overline({
    Color? color,
  }) {
    return TextStyle(
      fontSize: 10,
      color: color ?? AppColors.grey500,
      letterSpacing: 1.5,
    );
  }

  static TextStyle button({
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 1.0,
    );
  }

  // ==================== 日历样式 ====================
  static TextStyle calendarDay({
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle calendarToday({
    Color? color,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }

  static TextStyle calendarHeader({
    Color? color,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  // ==================== 待办样式 ====================
  static TextStyle todoTitle({
    Color? color,
    bool completed = false,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: color,
      decoration: completed ? TextDecoration.lineThrough : null,
    );
  }

  static TextStyle todoSubtitle({
    Color? color,
  }) {
    return TextStyle(
      fontSize: 12,
      color: color ?? AppColors.grey600,
    );
  }

  // ==================== 日记样式 ====================
  static TextStyle diaryContent({
    Color? color,
  }) {
    return TextStyle(
      fontSize: 15,
      height: 1.6,
      color: color,
    );
  }

  static TextStyle diaryDate({
    Color? color,
  }) {
    return TextStyle(
      fontSize: 12,
      color: color ?? AppColors.grey500,
    );
  }
}
