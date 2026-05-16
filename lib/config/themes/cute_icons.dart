import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 可爱图标数据
/// 用于装饰应用，增添趣味性
class CuteIcons {
  CuteIcons._();

  // ==================== 表情图标 ====================
  static const List<String> faces = [
    '😊', '😄', '🥰', '😍', '🤗',
    '😎', '🥳', '😋', '🤩', '😇',
    '🥺', '😴', '🤔', '😏', '🤭',
  ];

  // ==================== 动物图标 ====================
  static const List<String> animals = [
    '🐱', '🐶', '🐰', '🐻', '🦊',
    '🐼', '🐨', '🦁', '🐯', '🐮',
    '🐷', '🐸', '🐵', '🦄', '🐝',
  ];

  // ==================== 自然图标 ====================
  static const List<String> nature = [
    '🌸', '🌺', '🌻', '🌹', '🌷',
    '🍀', '🌵', '🌴', '🌈', '☀️',
    '🌙', '⭐', '💫', '❄️', '🌊',
  ];

  // ==================== 食物图标 ====================
  static const List<String> food = [
    '🍎', '🍊', '🍋', '🍇', '🍓',
    '🍰', '🧁', '🍩', '🍪', '🍦',
    '🍕', '🍔', '🌮', '🍜', '🍣',
  ];

  // ==================== 活动图标 ====================
  static const List<String> activities = [
    '📚', '✏️', '🎨', '🎵', '🎮',
    '⚽', '🏀', '🎾', '🏊', '🚴',
    '✈️', '🚗', '🚲', '⛺', '🏖️',
  ];

  // ==================== 爱心图标 ====================
  static const List<String> hearts = [
    '❤️', '🧡', '💛', '💚', '💙',
    '💜', '🖤', '🤍', '🤎', '💕',
    '💞', '💓', '💗', '💖', '💝',
  ];

  // ==================== 星星图标 ====================
  static const List<String> stars = [
    '⭐', '🌟', '✨', '💫', '🌠',
  ];

  // ==================== 待办相关图标 ====================
  static const List<String> todoIcons = [
    '✅', '☑️', '✔️', '📝', '📋',
    '📌', '📍', '🎯', '🏆', '💪',
    '🔥', '⚡', '💡', '🔔', '⏰',
  ];

  // ==================== 心情图标 ====================
  static const Map<String, String> moodIcons = {
    'happy': '😊',
    'excited': '🎉',
    'calm': '😌',
    'sad': '😢',
    'angry': '😠',
    'tired': '😴',
    'love': '❤️',
    'thinking': '🤔',
  };

  // ==================== 天气图标 ====================
  static const Map<String, String> weatherIcons = {
    'sunny': '☀️',
    'cloudy': '☁️',
    'rainy': '🌧️',
    'snowy': '❄️',
    'stormy': '⛈️',
    'windy': '💨',
    'foggy': '🌫️',
  };

  /// 获取所有图标
  static List<String> get allIcons => [
    ...faces,
    ...animals,
    ...nature,
    ...food,
    ...activities,
    ...hearts,
    ...stars,
    ...todoIcons,
  ];

  /// 随机获取一个图标
  static String getRandomIcon() {
    final icons = allIcons;
    return icons[DateTime.now().millisecondsSinceEpoch % icons.length];
  }
}

/// 图标按钮组件
class IconButtonData {
  final String icon;
  final String label;
  final Color color;

  const IconButtonData({
    required this.icon,
    required this.label,
    this.color = AppColors.grey700,
  });
}

/// 预设图标按钮列表
class PresetIconButtons {
  static const List<IconButtonData> todoButtons = [
    IconButtonData(icon: '✅', label: '完成', color: AppColors.success),
    IconButtonData(icon: '⏰', label: '提醒', color: AppColors.warning),
    IconButtonData(icon: '🔥', label: '紧急', color: AppColors.error),
    IconButtonData(icon: '⭐', label: '重要', color: AppColors.primaryOrange),
    IconButtonData(icon: '💡', label: '想法', color: AppColors.primaryYellow),
    IconButtonData(icon: '📚', label: '学习', color: AppColors.primaryBlue),
    IconButtonData(icon: '💪', label: '运动', color: AppColors.primaryGreen),
    IconButtonData(icon: '🛒', label: '购物', color: AppColors.primaryPurple),
  ];

  static const List<IconButtonData> diaryButtons = [
    IconButtonData(icon: '😊', label: '开心', color: AppColors.moodHappy),
    IconButtonData(icon: '😢', label: '难过', color: AppColors.moodSad),
    IconButtonData(icon: '🥰', label: '幸福', color: AppColors.moodLove),
    IconButtonData(icon: '🤔', label: '思考', color: AppColors.moodThinking),
    IconButtonData(icon: '😴', label: '疲惫', color: AppColors.moodTired),
    IconButtonData(icon: '🎉', label: '庆祝', color: AppColors.moodExcited),
  ];
}
