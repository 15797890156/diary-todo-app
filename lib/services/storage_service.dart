import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 存储服务（本地存储版本）
/// 处理图片保存和删除操作
/// 使用本地文件系统替代Firebase Storage
class StorageService {
  static const String _avatarDir = 'avatars';
  static const String _diaryDir = 'diaries';

  /// 获取应用文档目录
  Future<Directory> _getAppDir() async {
    return await getApplicationDocumentsDirectory();
  }

  /// 确保目录存在
  Future<Directory> _ensureDir(String subDir) async {
    final appDir = await _getAppDir();
    final dir = Directory(path.join(appDir.path, subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 上传用户头像
  /// 返回本地文件路径
  Future<String> uploadAvatar(String userId, File imageFile) async {
    final dir = await _ensureDir(_avatarDir);
    final extension = path.extension(imageFile.path);
    final fileName = '${userId}_avatar$extension';
    final targetPath = path.join(dir.path, fileName);

    // 复制文件到应用目录
    await imageFile.copy(targetPath);

    return targetPath;
  }

  /// 上传日记图片
  /// 返回本地文件路径
  Future<String> uploadDiaryImage(String userId, File imageFile) async {
    final dir = await _ensureDir('$_diaryDir/$userId');
    final extension = path.extension(imageFile.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = path.join(dir.path, fileName);

    // 复制文件到应用目录
    await imageFile.copy(targetPath);

    return targetPath;
  }

  /// 批量上传日记图片
  Future<List<String>> uploadDiaryImages(String userId, List<File> imageFiles) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      final url = await uploadDiaryImage(userId, file);
      urls.add(url);
    }
    return urls;
  }

  /// 删除图片
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 批量删除图片
  Future<void> deleteImages(List<String> imagePaths) async {
    for (final path in imagePaths) {
      await deleteImage(path);
    }
  }

  /// 获取头像文件
  Future<File?> getAvatarFile(String userId) async {
    final dir = await _ensureDir(_avatarDir);
    final extensions = ['.jpg', '.jpeg', '.png', '.gif'];

    for (final ext in extensions) {
      final file = File(path.join(dir.path, '${userId}_avatar$ext'));
      if (await file.exists()) {
        return file;
      }
    }
    return null;
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }
}
