import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/themes/themes.dart';

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '我的',
          style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          _buildUserCard(theme, user),

          const SizedBox(height: 16),

          // 主题设置
          _buildSectionHeader(theme, '外观设置'),
          _buildThemeSection(theme, themeState),

          const SizedBox(height: 16),

          // 数据管理
          _buildSectionHeader(theme, '数据管理'),
          _buildDataSection(theme),

          const SizedBox(height: 16),

          // 关于
          _buildSectionHeader(theme, '关于'),
          _buildAboutSection(theme),

          const SizedBox(height: 32),

          // 退出登录按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppButton(
              text: '退出登录',
              isOutlined: true,
              color: theme.colorScheme.error,
              onPressed: _logout,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard(ThemeData theme, user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.surface,
            backgroundImage: user?.avatarUrl != null
                ? NetworkImage(user!.avatarUrl!)
                : null,
            child: user?.avatarUrl == null
                ? Text(
                    user?.displayName?.substring(0, 1) ?? 'U',
                    style: AppTextStyles.h2(color: theme.colorScheme.primary),
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? '用户',
                  style: AppTextStyles.h3(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: AppTextStyles.bodySmall(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // 编辑按钮
          IconButton(
            icon: Icon(
              Icons.edit,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            onPressed: () {
              // 编辑个人信息
            },
          ),
        ],
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.bodySmall(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// 构建主题设置区域
  Widget _buildThemeSection(ThemeData theme, ThemeState themeState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        children: [
          // 主题选择
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题风格'),
            subtitle: Text(_getThemeName(themeState.theme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeSelector(themeState),
          ),

          const Divider(height: 1, indent: 56),

          // 强调色选择
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('强调色'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeState.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline),
              ),
            ),
            onTap: () => _showColorPicker(themeState),
          ),

          const Divider(height: 1, indent: 56),

          // 字体大小
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('字体大小'),
            subtitle: Text('${themeState.fontSize.toInt()}'),
            trailing: SizedBox(
              width: 120,
              child: Slider(
                value: themeState.fontSize,
                min: 12,
                max: 20,
                divisions: 8,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).setFontSize(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建数据管理区域
  Widget _buildDataSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('云端同步'),
            subtitle: const Text('自动同步数据到云端'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // 切换同步设置
              },
            ),
          ),

          const Divider(height: 1, indent: 56),

          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导出数据'),
            subtitle: const Text('导出所有日记和待办'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 导出数据
            },
          ),

          const Divider(height: 1, indent: 56),

          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: theme.colorScheme.error,
            ),
            title: Text(
              '清除数据',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('清除所有本地数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _clearData,
          ),
        ],
      ),
    );
  }

  /// 构建关于区域
  Widget _buildAboutSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于应用'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 显示关于页面
            },
          ),

          const Divider(height: 1, indent: 56),

          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('给个好评'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 跳转到应用商店
            },
          ),

          const Divider(height: 1, indent: 56),

          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('意见反馈'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 打开反馈页面
            },
          ),
        ],
      ),
    );
  }

  /// 获取主题名称
  String _getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return '浅色模式';
      case AppTheme.dark:
        return '深色模式';
      case AppTheme.cute:
        return '可爱风格';
      case AppTheme.nature:
        return '自然风格';
      case AppTheme.ocean:
        return '海洋风格';
      case AppTheme.sunset:
        return '日落风格';
    }
  }

  /// 显示主题选择器
  void _showThemeSelector(ThemeState themeState) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppTheme.values.map((theme) {
              final isSelected = themeState.theme == theme;
              return ListTile(
                leading: Icon(_getThemeIcon(theme)),
                title: Text(_getThemeName(theme)),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(theme);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// 获取主题图标
  IconData _getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.cute:
        return Icons.favorite;
      case AppTheme.nature:
        return Icons.nature;
      case AppTheme.ocean:
        return Icons.water;
      case AppTheme.sunset:
        return Icons.wb_twilight;
    }
  }

  /// 显示颜色选择器
  void _showColorPicker(ThemeState themeState) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.red,
      Colors.indigo,
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('选择强调色'),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: colors.map((color) {
                  final isSelected = themeState.accentColor == color;
                  return GestureDetector(
                    onTap: () {
                      ref.read(themeProvider.notifier).setAccentColor(color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// 清除数据
  Future<void> _clearData() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '清除数据',
      content: '确定要清除所有本地数据吗？此操作不可撤销。',
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true) {
      await ref.read(localStorageServiceProvider).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('本地数据已清除')),
        );
      }
    }
  }

  /// 退出登录
  Future<void> _logout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '退出登录',
      content: '确定要退出当前账号吗？',
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}
