import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// 认证服务（本地存储版本）
/// 处理用户注册、登录、登出等操作
/// 使用SharedPreferences替代Firebase Auth
class AuthService {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyUsers = 'users';

  late SharedPreferences _prefs;
  UserModel? _currentUser;

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCurrentUser();
  }

  /// 获取当前用户
  UserModel? get currentUser => _currentUser;

  /// 获取当前用户 ID
  String? get currentUserId => _currentUser?.uid;

  /// 用户登录状态流
  Stream<UserModel?> get authStateChanges async* {
    yield _currentUser;
  }

  /// 检查是否已登录
  bool get isLoggedIn => _currentUser != null;

  /// 加载当前用户
  void _loadCurrentUser() {
    final userJson = _prefs.getString(_keyCurrentUser);
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        _currentUser = null;
      }
    }
  }

  /// 使用邮箱密码注册
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    // 检查邮箱是否已被注册
    final users = await _getAllUsers();
    if (users.any((u) => u.email == email)) {
      throw Exception('该邮箱已被注册');
    }

    // 创建用户
    final uid = DateTime.now().millisecondsSinceEpoch.toString();
    final userModel = UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    // 保存用户
    users.add(userModel);
    await _saveUsers(users);

    // 设置当前用户
    _currentUser = userModel;
    await _prefs.setString(_keyCurrentUser, jsonEncode(userModel.toJson()));

    return userModel;
  }

  /// 使用邮箱密码登录
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // 在实际应用中应该验证密码，这里简化处理
    final users = await _getAllUsers();
    final user = users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('用户不存在或密码错误'),
    );

    // 更新最后登录时间
    final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
    final index = users.indexWhere((u) => u.uid == user.uid);
    if (index != -1) {
      users[index] = updatedUser;
      await _saveUsers(users);
    }

    // 设置当前用户
    _currentUser = updatedUser;
    await _prefs.setString(_keyCurrentUser, jsonEncode(updatedUser.toJson()));

    return updatedUser;
  }

  /// 发送密码重置邮件（模拟）
  Future<void> sendPasswordResetEmail(String email) async {
    final users = await _getAllUsers();
    if (!users.any((u) => u.email == email)) {
      throw Exception('用户不存在');
    }
    // 本地存储版本不实际发送邮件
  }

  /// 登出
  Future<void> signOut() async {
    _currentUser = null;
    await _prefs.remove(_keyCurrentUser);
  }

  /// 更新用户信息
  Future<UserModel> updateUserProfile({
    String? displayName,
    String? avatarUrl,
    String? themePreference,
    String? accentColor,
  }) async {
    if (_currentUser == null) {
      throw Exception('用户未登录');
    }

    final updated = _currentUser!.copyWith(
      displayName: displayName,
    );

    // 更新本地存储中的用户信息
    final users = await _getAllUsers();
    final index = users.indexWhere((u) => u.uid == _currentUser!.uid);
    if (index != -1) {
      users[index] = updated;
      await _saveUsers(users);
    }

    _currentUser = updated;
    await _prefs.setString(_keyCurrentUser, jsonEncode(updated.toJson()));

    return updated;
  }

  /// 获取用户信息
  Future<UserModel?> getUserModel() async {
    return _currentUser;
  }

  /// 获取所有用户
  Future<List<UserModel>> _getAllUsers() async {
    final usersJson = _prefs.getString(_keyUsers);
    if (usersJson == null) return [];

    try {
      final List<dynamic> list = jsonDecode(usersJson);
      return list.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存所有用户
  Future<void> _saveUsers(List<UserModel> users) async {
    final list = users.map((u) => u.toJson()).toList();
    await _prefs.setString(_keyUsers, jsonEncode(list));
  }
}
