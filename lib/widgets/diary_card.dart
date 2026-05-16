import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../config/themes/themes.dart';

/// 日记卡片组件
/// 类似朋友圈卡片样式
class DiaryCard extends StatelessWidget {
  final DiaryModel diary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DiaryCard({
    super.key,
    required this.diary,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：日期和心情
            _buildHeader(theme),

            // 图片网格
            if (diary.images.isNotEmpty) _buildImages(theme),

            // 内容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                diary.content,
                style: AppTextStyles.diaryContent(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            // 标签
            if (diary.tags.isNotEmpty) _buildTags(theme),

            // 底部：位置和操作
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 心情图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                diary.moodEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 日期和心情文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MM月dd日 EEEE', 'zh_CN').format(diary.createdAt),
                  style: AppTextStyles.bodyMedium(
                    color: theme.colorScheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  diary.moodText,
                  style: AppTextStyles.caption(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 更多操作
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                onDelete?.call();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('编辑'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建图片网格
  Widget _buildImages(ThemeData theme) {
    final imageCount = diary.images.length;

    if (imageCount == 1) {
      // 单张图片
      return ClipRRect(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(0),
          right: Radius.circular(0),
        ),
        child: Image.network(
          diary.images.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
        ),
      );
    }

    // 多张图片网格
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: imageCount >= 4 ? 3 : 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: imageCount > 9 ? 9 : imageCount,
        itemBuilder: (context, index) {
          final isLast = index == 8 && imageCount > 9;
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  diary.images[index],
                  fit: BoxFit.cover,
                ),
              ),
              if (isLast)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '+${imageCount - 9}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 构建标签
  Widget _buildTags(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: diary.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '#$tag',
              style: AppTextStyles.caption(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建底部
  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 位置
          if (diary.location != null) ...[
            Icon(
              Icons.location_on,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              diary.location!,
              style: AppTextStyles.caption(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // 天气
          if (diary.weather != null) ...[
            Text(
              CuteIcons.weatherIcons[diary.weather!.toLowerCase()] ?? '🌤️',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              diary.weather!,
              style: AppTextStyles.caption(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const Spacer(),

          // 时间
          Text(
            DateFormat('HH:mm').format(diary.createdAt),
            style: AppTextStyles.caption(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 心情选择器组件
class MoodSelector extends StatelessWidget {
  final MoodType? selectedMood;
  final Function(MoodType) onMoodSelected;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天的心情',
          style: AppTextStyles.bodyMedium(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: MoodType.values.map((mood) {
            final isSelected = selectedMood == mood;
            return GestureDetector(
              onTap: () => onMoodSelected(mood),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getMoodEmoji(mood),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getMoodText(mood),
                      style: AppTextStyles.bodySmall(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getMoodEmoji(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return '😊';
      case MoodType.excited:
        return '🎉';
      case MoodType.calm:
        return '😌';
      case MoodType.sad:
        return '😢';
      case MoodType.angry:
        return '😠';
      case MoodType.tired:
        return '😴';
      case MoodType.love:
        return '❤️';
      case MoodType.thinking:
        return '🤔';
    }
  }

  String _getMoodText(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return '开心';
      case MoodType.excited:
        return '兴奋';
      case MoodType.calm:
        return '平静';
      case MoodType.sad:
        return '难过';
      case MoodType.angry:
        return '生气';
      case MoodType.tired:
        return '疲惫';
      case MoodType.love:
        return '爱心';
      case MoodType.thinking:
        return '思考';
    }
  }
}
