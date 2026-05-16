import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/health_data_provider.dart';
import '../services/health_data_service.dart';
import '../config/themes/themes.dart';

/// 健康数据同步设置组件
/// 包含授权管理、手动同步、同步结果展示
class HealthSyncSettingsWidget extends ConsumerWidget {
  const HealthSyncSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authStatus = ref.watch(healthAuthStatusProvider);
    final syncResult = ref.watch(healthSyncNotifierProvider);
    final autoSync = ref.watch(autoSyncEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('⌚', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '手环/手表数据同步',
                style: AppTextStyles.h4(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // 授权状态卡片
        _buildAuthCard(context, theme, ref, authStatus),

        const SizedBox(height: 12),

        // 同步操作区域（已授权时显示）
        if (authStatus == HealthAuthStatus.authorized) ...[
          _buildSyncSection(context, theme, ref, syncResult),
        ],

        // 未授权时的说明
        if (authStatus != HealthAuthStatus.authorized) ...[
          _buildSetupGuide(theme),
        ],
      ],
    );
  }

  /// 构建授权状态卡片
  Widget _buildAuthCard(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    HealthAuthStatus status,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          // 状态图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getStatusIcon(status),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 状态信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(status),
                  style: AppTextStyles.bodyMedium(
                    color: theme.colorScheme.onSurface,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(status),
                  style: AppTextStyles.caption(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮
          if (status != HealthAuthStatus.authorized)
            TextButton(
              onPressed: () => _handleAuth(context, ref),
              child: Text(
                status == HealthAuthStatus.unknown ? '检测' : '授权',
                style: AppTextStyles.bodySmall(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建同步操作区域
  Widget _buildSyncSection(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    AsyncValue<SyncResult?> syncResult,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 手动同步按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: syncResult is AsyncLoading
                  ? null
                  : () => _handleSyncToday(context, ref),
              icon: syncResult is AsyncLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                syncResult is AsyncLoading ? '同步中...' : '同步今日数据',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // 同步最近7天
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: syncResult is AsyncLoading
                  ? null
                  : () => _handleSyncWeek(context, ref),
              icon: const Icon(Icons.date_range, size: 18),
              label: const Text('同步最近7天'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // 同步结果展示
          if (syncResult is AsyncData && syncResult.value != null) ...[
            const SizedBox(height: 12),
            _buildSyncResult(theme, syncResult.value!),
          ],
        ],
      ),
    );
  }

  /// 构建同步结果
  Widget _buildSyncResult(ThemeData theme, SyncResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.success
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(
          color: result.success
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            result.success ? Icons.check_circle : Icons.error,
            size: 18,
            color: result.success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.summary,
              style: AppTextStyles.bodySmall(
                color: result.success ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置引导
  Widget _buildSetupGuide(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '如何连接手环数据？',
            style: AppTextStyles.bodyMedium(
              color: theme.colorScheme.onSurface,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildGuideStep(theme, '1', '确保手环已与手机蓝牙连接'),
          _buildGuideStep(theme, '2', '打开手环品牌官方App（如小米运动健康）'),
          _buildGuideStep(theme, '3', '在品牌App中开启「同步到系统健康」'),
          _buildGuideStep(theme, '4', '返回本App点击「授权」按钮'),
          const SizedBox(height: 8),
          Text(
            '支持所有品牌手环，通过 Apple 健康 / Google Fit 中转数据',
            style: AppTextStyles.caption(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建引导步骤
  Widget _buildGuideStep(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.caption(
                  color: theme.colorScheme.primary,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理授权
  Future<void> _handleAuth(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(healthAuthStatusProvider.notifier);
    if (ref.read(healthAuthStatusProvider) == HealthAuthStatus.unknown) {
      await notifier.checkStatus();
    } else {
      final granted = await notifier.requestAuthorization();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? '授权成功，可以开始同步数据了' : '授权被拒绝，无法读取健康数据'),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 同步今日数据
  Future<void> _handleSyncToday(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(healthSyncNotifierProvider.notifier).syncDate(DateTime.now());
    if (!context.mounted) return;
    ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.summary),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  /// 同步最近7天
  Future<void> _handleSyncWeek(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final result = await ref.read(healthSyncNotifierProvider.notifier).syncDateRange(start, now);
    if (!context.mounted) return;
    ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.summary),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  // ==================== 状态辅助 ====================

  Color _getStatusColor(HealthAuthStatus status) {
    switch (status) {
      case HealthAuthStatus.authorized:
        return Colors.green;
      case HealthAuthStatus.denied:
        return Colors.red;
      case HealthAuthStatus.unsupported:
        return Colors.orange;
      case HealthAuthStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusIcon(HealthAuthStatus status) {
    switch (status) {
      case HealthAuthStatus.authorized:
        return '✅';
      case HealthAuthStatus.denied:
        return '❌';
      case HealthAuthStatus.unsupported:
        return '⚠️';
      case HealthAuthStatus.unknown:
        return '❓';
    }
  }

  String _getStatusTitle(HealthAuthStatus status) {
    switch (status) {
      case HealthAuthStatus.authorized:
        return '已连接';
      case HealthAuthStatus.denied:
        return '未授权';
      case HealthAuthStatus.unsupported:
        return '平台不支持';
      case HealthAuthStatus.unknown:
        return '未检测';
    }
  }

  String _getStatusDescription(HealthAuthStatus status) {
    switch (status) {
      case HealthAuthStatus.authorized:
        return '健康数据权限已开启，可以同步手环数据';
      case HealthAuthStatus.denied:
        return '请在系统设置中允许本App访问健康数据';
      case HealthAuthStatus.unsupported:
        return '当前设备不支持健康数据读取';
      case HealthAuthStatus.unknown:
        return '点击检测按钮检查健康数据权限状态';
    }
  }
}

/// 时间表格中的同步浮动按钮
/// 用于快速触发同步操作
class HealthSyncFloatingButton extends ConsumerWidget {
  final DateTime date;

  const HealthSyncFloatingButton({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authStatus = ref.watch(healthAuthStatusProvider);
    final syncResult = ref.watch(healthSyncNotifierProvider);

    // 未授权时不显示
    if (authStatus != HealthAuthStatus.authorized) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.small(
      onPressed: syncResult is AsyncLoading
          ? null
          : () async {
              final result = await ref
                  .read(healthSyncNotifierProvider.notifier)
                  .syncDate(date);
              if (!context.mounted) return;
              ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.summary),
                  backgroundColor: result.success ? Colors.green : Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
      backgroundColor: theme.colorScheme.primaryContainer,
      child: syncResult is AsyncLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(
              Icons.sync,
              color: theme.colorScheme.onPrimaryContainer,
              size: 18,
            ),
    );
  }
}
