import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/product_track_model.dart';
import '../providers/analytics_provider.dart';
import '../config/themes/themes.dart';

/// 长期主义产品追踪视图
/// 展示产品列表、进度条、寿命周期、打卡等功能
class ProductTrackView extends ConsumerStatefulWidget {
  const ProductTrackView({super.key});

  @override
  ConsumerState<ProductTrackView> createState() => _ProductTrackViewState();
}

class _ProductTrackViewState extends ConsumerState<ProductTrackView> {
  // 筛选：全部 / 进行中 / 已完成
  ProductTrackStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Column(
      children: [
        // 顶部栏
        _buildTopBar(theme),

        // 筛选标签
        _buildFilterTabs(theme),

        // 产品列表
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('加载失败: $error')),
            data: (products) {
              var filtered = products;
              if (_filterStatus != null) {
                filtered = products.where((p) => p.status == _filterStatus).toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🌱', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        _filterStatus != null ? '暂无${_filterStatus == ProductTrackStatus.active ? '进行中' : '已完成'}的产品' : '还没有追踪任何产品',
                        style: AppTextStyles.bodyMedium(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('添加产品'),
                        onPressed: () => _showAddProductDialog(),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(theme, filtered[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== 顶部栏 ====================

  Widget _buildTopBar(ThemeData theme) {
    final productsAsync = ref.watch(productsProvider);
    final products = productsAsync.valueOrNull ?? [];
    final activeCount = products.where((p) => p.status == ProductTrackStatus.active).length;
    final completedCount = products.where((p) => p.status == ProductTrackStatus.completed).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '长期主义',
                  style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  '$activeCount个进行中 · $completedCount个已完成',
                  style: AppTextStyles.caption(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _showAddProductDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加'),
          ),
        ],
      ),
    );
  }

  // ==================== 筛选标签 ====================

  Widget _buildFilterTabs(ThemeData theme) {
    final tabs = [
      (null, '全部'),
      (ProductTrackStatus.active, '进行中'),
      (ProductTrackStatus.completed, '已完成'),
      (ProductTrackStatus.paused, '已暂停'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final status = tab.$1;
            final label = tab.$2;
            final isSelected = _filterStatus == status;
            return GestureDetector(
              onTap: () => setState(() => _filterStatus = status),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ).copyWith(fontWeight: isSelected ? FontWeight.w600 : null),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== 产品卡片 ====================

  Widget _buildProductCard(ThemeData theme, ProductTrackModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // 主信息
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 第一行：图标、名称、状态
                Row(
                  children: [
                    Text(product.icon ?? product.typeIcon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTextStyles.bodyMedium(
                              color: theme.colorScheme.onSurface,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _parseColor(product.statusColor).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.statusName,
                                  style: AppTextStyles.overline(
                                    color: _parseColor(product.statusColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                product.typeName,
                                style: AppTextStyles.overline(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 更多操作
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) => _handleMenuAction(value, product),
                      itemBuilder: (context) => [
                        if (product.status == ProductTrackStatus.active)
                          const PopupMenuItem(value: 'checkin', child: Text('打卡/记录')),
                        if (product.status == ProductTrackStatus.active)
                          const PopupMenuItem(value: 'pause', child: Text('暂停')),
                        if (product.status == ProductTrackStatus.paused)
                          const PopupMenuItem(value: 'resume', child: Text('继续')),
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 进度条
                _buildProgressBar(theme, product),

                const SizedBox(height: 12),

                // 统计数据行
                _buildStatsRow(theme, product),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 进度条
  Widget _buildProgressBar(ThemeData theme, ProductTrackModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.formattedProgress,
              style: AppTextStyles.bodySmall(
                color: theme.colorScheme.onSurface,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              product.formattedPercent,
              style: AppTextStyles.bodySmall(
                color: theme.colorScheme.primary,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: product.progressPercent,
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        if (product.remainingProgress > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '还剩 ${product.remainingProgress.toInt()}${product.unit ?? ''}',
              style: AppTextStyles.overline(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// 统计数据行
  Widget _buildStatsRow(ThemeData theme, ProductTrackModel product) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildStatItem(
            theme,
            icon: '📅',
            label: '已坚持',
            value: product.lifespanText,
          ),
          _buildStatItem(
            theme,
            icon: '✅',
            label: '打卡',
            value: '${product.totalCheckIns}次',
          ),
          _buildStatItem(
            theme,
            icon: '🔥',
            label: '连续',
            value: '${product.currentStreak}天',
          ),
          _buildStatItem(
            theme,
            icon: '🏆',
            label: '最长',
            value: '${product.longestStreak}天',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.caption(
              color: theme.colorScheme.onSurface,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          Text(
            label,
            style: AppTextStyles.overline(
              color: theme.colorScheme.onSurfaceVariant,
            ).copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ==================== 操作 ====================

  void _handleMenuAction(String action, ProductTrackModel product) {
    switch (action) {
      case 'checkin':
        _showCheckInDialog(product);
        break;
      case 'pause':
        ref.read(productsNotifierProvider.notifier).updateProduct(
              product.copyWith(status: ProductTrackStatus.paused, updatedAt: DateTime.now()),
            );
        break;
      case 'resume':
        ref.read(productsNotifierProvider.notifier).updateProduct(
              product.copyWith(status: ProductTrackStatus.active, updatedAt: DateTime.now()),
            );
        break;
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'delete':
        _confirmDelete(product);
        break;
    }
  }

  /// 打卡弹窗
  void _showCheckInDialog(ProductTrackModel product) {
    final controller = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('记录 ${product.name}', style: AppTextStyles.h4(color: Theme.of(context).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前进度：${product.formattedProgress}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '本次增量（${product.unit ?? "次"}）',
                hintText: '输入数量',
                suffixText: product.unit,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final increment = double.tryParse(controller.text) ?? 1;
              ref.read(productsNotifierProvider.notifier).checkIn(
                    productId: product.id,
                    increment: increment,
                  );
              Navigator.pop(context);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  /// 添加产品弹窗
  void _showAddProductDialog() {
    _showProductFormDialog(null);
  }

  /// 编辑产品弹窗
  void _showEditProductDialog(ProductTrackModel product) {
    _showProductFormDialog(product);
  }

  /// 产品表单弹窗
  void _showProductFormDialog(ProductTrackModel? product) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        product: product,
        onSave: (updated) {
          if (product == null) {
            ref.read(productsNotifierProvider.notifier).createProduct(
                  name: updated.name,
                  type: updated.type,
                  targetProgress: updated.targetProgress,
                  unit: updated.unit,
                  description: updated.description,
                  icon: updated.icon,
                  startDate: updated.startDate,
                  expectedDays: updated.expectedDays,
                );
          } else {
            ref.read(productsNotifierProvider.notifier).updateProduct(updated);
          }
        },
      ),
    );
  }

  /// 确认删除
  void _confirmDelete(ProductTrackModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${product.name}」吗？所有打卡记录也将被删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(productsNotifierProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// 产品表单弹窗
class _ProductFormDialog extends StatefulWidget {
  final ProductTrackModel? product;
  final Function(ProductTrackModel) onSave;

  const _ProductFormDialog({super.key, this.product, required this.onSave});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _descController = TextEditingController();
  final _unitController = TextEditingController();

  late ProductTrackType _type;
  late DateTime _startDate;
  int? _expectedDays;
  String? _selectedIcon;

  final _typeIcons = {
    ProductTrackType.consumable: ['🧴', '💊', '🧹', '🪥', '🧻', '☕', '🫖', '🧃'],
    ProductTrackType.goal: ['📚', '🎓', '🏃', '💪', '🎨', '🎵', '✍️', '💻'],
    ProductTrackType.subscription: ['💳', '📱', '📺', '🎵', '🎮', '🏋️', '🚗', '✈️'],
    ProductTrackType.habit: ['🔥', '💧', '🧘', '🌅', '🛏️', '🥗', '📖', '🏃‍♂️'],
  };

  @override
  void initState() {
    super.initState();
    _type = widget.product?.type ?? ProductTrackType.consumable;
    _startDate = widget.product?.startDate ?? DateTime.now();
    _expectedDays = widget.product?.expectedDays;
    _selectedIcon = widget.product?.icon;
    _nameController.text = widget.product?.name ?? '';
    _targetController.text = (widget.product?.targetProgress ?? 100).toInt().toString();
    _descController.text = widget.product?.description ?? '';
    _unitController.text = widget.product?.unit ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _descController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.product == null ? '添加产品' : '编辑产品',
        style: AppTextStyles.h4(color: theme.colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 类型选择
            Text('类型', style: AppTextStyles.bodySmall(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Row(
              children: ProductTrackType.values.map((type) {
                final sel = _type == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _type = type; _selectedIcon = null; }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: sel ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                      ),
                      child: Column(
                        children: [
                          Text(_getTypeIcon(type), style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 3),
                          Text(
                            _getTypeName(type),
                            style: AppTextStyles.overline(
                              color: sel ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ).copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '产品名称', hintText: '如：兰蔻小黑瓶'),
            ),

            const SizedBox(height: 12),

            // 目标 + 单位
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '目标总量'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: '单位', hintText: '次/ml/页'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 描述
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: '描述（可选）'),
              maxLines: 2,
            ),

            const SizedBox(height: 12),

            // 开始日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 20),
              title: const Text('开始日期', style: TextStyle(fontSize: 13)),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_startDate), style: const TextStyle(fontSize: 13)),
              dense: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),

            // 预计天数
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, size: 20),
              title: const Text('预计天数（可选）', style: TextStyle(fontSize: 13)),
              subtitle: Text(_expectedDays != null ? '$_expectedDays天' : '未设置', style: const TextStyle(fontSize: 13)),
              dense: true,
              onTap: () async {
                // 简单输入
                final controller = TextEditingController(text: _expectedDays?.toString() ?? '');
                final days = await showDialog<int>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('预计天数'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '天数'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                );
                if (days != null) setState(() => _expectedDays = days);
              },
            ),

            const SizedBox(height: 16),

            // 图标选择
            Text('图标', style: AppTextStyles.bodySmall(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeIcons[_type]!.map((icon) {
                final sel = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: sel ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: sel ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;

    final product = ProductTrackModel(
      id: widget.product?.id ?? '',
      userId: widget.product?.userId ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      type: _type,
      icon: _selectedIcon,
      targetProgress: double.tryParse(_targetController.text) ?? 100,
      unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
      startDate: _startDate,
      expectedDays: _expectedDays,
      totalCheckIns: widget.product?.totalCheckIns ?? 0,
      currentStreak: widget.product?.currentStreak ?? 0,
      longestStreak: widget.product?.longestStreak ?? 0,
      lastCheckInAt: widget.product?.lastCheckInAt,
      status: widget.product?.status ?? ProductTrackStatus.active,
      currentProgress: widget.product?.currentProgress ?? 0,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(product);
    Navigator.pop(context);
  }

  String _getTypeIcon(ProductTrackType type) {
    switch (type) {
      case ProductTrackType.consumable: return '🧴';
      case ProductTrackType.goal: return '🎯';
      case ProductTrackType.subscription: return '💳';
      case ProductTrackType.habit: return '🔥';
    }
  }

  String _getTypeName(ProductTrackType type) {
    switch (type) {
      case ProductTrackType.consumable: return '消耗品';
      case ProductTrackType.goal: return '目标进度';
      case ProductTrackType.subscription: return '订阅服务';
      case ProductTrackType.habit: return '习惯养成';
    }
  }
}
