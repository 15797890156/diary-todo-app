import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../config/themes/themes.dart';

/// 日记页面
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diariesAsync = ref.watch(diariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '我的日记',
          style: AppTextStyles.h3(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 显示搜索
            },
          ),
        ],
      ),
      body: diariesAsync.when(
        loading: () => const LoadingIndicator(message: '加载中...'),
        error: (error, _) => EmptyState(
          icon: '😕',
          title: '加载失败',
          subtitle: error.toString(),
          buttonText: '重试',
          onButtonPressed: () => ref.refresh(diariesProvider),
        ),
        data: (diaries) {
          if (diaries.isEmpty) {
            return EmptyState(
              icon: '📝',
              title: '还没有日记',
              subtitle: '点击右下角按钮记录今天的心情',
              buttonText: '写日记',
              onButtonPressed: _showAddDiaryScreen,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(diariesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final diary = diaries[index];
                return DiaryCard(
                  diary: diary,
                  onTap: () => _showDiaryDetail(diary),
                  onEdit: () => _showEditDiaryScreen(diary),
                  onDelete: () => _deleteDiary(diary),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDiaryScreen,
        child: const Icon(Icons.edit),
      ),
    );
  }

  /// 显示添加日记页面
  void _showAddDiaryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiaryEditScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  /// 显示编辑日记页面
  void _showEditDiaryScreen(DiaryModel diary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditScreen(diary: diary),
        fullscreenDialog: true,
      ),
    );
  }

  /// 显示日记详情
  void _showDiaryDetail(DiaryModel diary) {
    // 可以导航到详情页面
  }

  /// 删除日记
  Future<void> _deleteDiary(DiaryModel diary) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '删除日记',
      content: '确定要删除这篇日记吗？此操作不可撤销。',
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true) {
      ref.read(diaryNotifierProvider.notifier).deleteDiary(
            diary.id,
            imageUrls: diary.images,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日记已删除')),
        );
      }
    }
  }
}

/// 日记编辑页面
class DiaryEditScreen extends ConsumerStatefulWidget {
  final DiaryModel? diary;

  const DiaryEditScreen({super.key, this.diary});

  @override
  ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();
  MoodType? _selectedMood;
  List<String> _tags = [];
  List<File> _selectedImages = [];
  List<String> _existingImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.diary != null) {
      _contentController.text = widget.diary!.content;
      _locationController.text = widget.diary!.location ?? '';
      _selectedMood = widget.diary!.mood;
      _tags = List.from(widget.diary!.tags);
      _existingImages = List.from(widget.diary!.images);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.diary == null ? '写日记' : '编辑日记',
          style: AppTextStyles.h4(color: theme.colorScheme.onSurface),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDiary,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 心情选择
            MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) {
                setState(() => _selectedMood = mood);
              },
            ),

            const SizedBox(height: 24),

            // 内容输入
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '记录今天的心情...',
                hintStyle: AppTextStyles.bodyMedium(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
              ),
              style: AppTextStyles.diaryContent(
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // 图片选择
            _buildImageSection(theme),

            const SizedBox(height: 16),

            // 位置输入
            AppTextField(
              controller: _locationController,
              labelText: '位置（可选）',
              prefixIcon: Icons.location_on_outlined,
            ),

            const SizedBox(height: 16),

            // 标签输入
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _tagController,
                    labelText: '添加标签',
                    prefixIcon: Icons.tag,
                    onSubmitted: _addTag,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),

            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    onDeleted: () {
                      setState(() => _tags.remove(tag));
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建图片选择区域
  Widget _buildImageSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '图片',
              style: AppTextStyles.bodyMedium(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('选择图片'),
              onPressed: _pickImages,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_existingImages.isNotEmpty || _selectedImages.isNotEmpty)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              // 已有图片
              ..._existingImages.map((url) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _existingImages.remove(url));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              // 新选择的图片
              ..._selectedImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        entry.value,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedImages.removeAt(entry.key));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  /// 选择图片
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  /// 保存日记
  Future<void> _saveDiary() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日记内容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 上传新图片
      List<String> allImages = List.from(_existingImages);
      if (_selectedImages.isNotEmpty) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final storage = ref.read(storageServiceProvider);
          final urls = await storage.uploadDiaryImages(user.uid, _selectedImages);
          allImages.addAll(urls);
        }
      }

      if (widget.diary == null) {
        // 创建新日记
        await ref.read(diaryNotifierProvider.notifier).createDiary(
              content: _contentController.text.trim(),
              images: allImages,
              mood: _selectedMood,
              location: _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              tags: _tags,
            );
      } else {
        // 更新日记
        await ref.read(diaryNotifierProvider.notifier).updateDiary(
              widget.diary!.copyWith(
                content: _contentController.text.trim(),
                images: allImages,
                mood: _selectedMood,
                location: _locationController.text.trim().isEmpty
                    ? null
                    : _locationController.text.trim(),
                tags: _tags,
              ),
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.diary == null ? '日记已保存' : '日记已更新'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
