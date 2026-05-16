import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'auth_provider.dart';

/// 日记列表状态
final diariesProvider = StreamProvider<List<DiaryModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final db = ref.watch(databaseServiceProvider);
  return db.getDiaries(user.uid);
});

/// 指定日期的日记
final diariesByDateProvider = Provider.family<List<DiaryModel>, DateTime>((ref, date) {
  final diaries = ref.watch(diariesProvider).value ?? [];
  return diaries.where((diary) {
    return diary.createdAt.year == date.year &&
        diary.createdAt.month == date.month &&
        diary.createdAt.day == date.day;
  }).toList();
});

/// 指定月份的日记
final diariesByMonthProvider = Provider.family<List<DiaryModel>, ({int year, int month})>((ref, params) {
  final diaries = ref.watch(diariesProvider).value ?? [];
  return diaries.where((diary) {
    return diary.createdAt.year == params.year &&
        diary.createdAt.month == params.month;
  }).toList();
});

/// 日记操作类
class DiaryNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _db;
  final StorageService _storage;
  final String _userId;

  DiaryNotifier(this._db, this._storage, this._userId) : super(const AsyncValue.data(null));

  /// 创建日记
  Future<DiaryModel?> createDiary({
    required String content,
    List<String> images = const [],
    MoodType? mood,
    String? location,
    String? weather,
    List<String> tags = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final diary = DiaryModel(
        id: '',
        userId: _userId,
        content: content,
        images: images,
        mood: mood,
        location: location,
        weather: weather,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _db.createDiary(diary);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// 更新日记
  Future<void> updateDiary(DiaryModel diary) async {
    state = const AsyncValue.loading();
    try {
      await _db.updateDiary(diary.copyWith(updatedAt: DateTime.now()));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 删除日记
  Future<void> deleteDiary(String diaryId, {List<String> imageUrls = const []}) async {
    state = const AsyncValue.loading();
    try {
      // 删除图片
      if (imageUrls.isNotEmpty) {
        await _storage.deleteImages(imageUrls);
      }
      // 删除日记记录
      await _db.deleteDiary(diaryId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 日记操作提供者
final diaryNotifierProvider = StateNotifierProvider<DiaryNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final db = ref.watch(databaseServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  return DiaryNotifier(db, storage, user?.uid ?? '');
});
