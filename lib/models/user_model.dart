/// 用户模型
/// 存储用户的基本信息和偏好设置
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String themePreference; // 主题偏好：'light', 'dark', 'cute', 'nature'
  final String accentColor; // 强调色
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.themePreference = 'light',
    this.accentColor = '#4CAF50',
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// 从 JSON Map 创建用户模型
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      themePreference: json['themePreference'] ?? 'light',
      accentColor: json['accentColor'] ?? '#4CAF50',
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
    );
  }

  /// 转换为 JSON Map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'themePreference': themePreference,
      'accentColor': accentColor,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? themePreference,
    String? accentColor,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      themePreference: themePreference ?? this.themePreference,
      accentColor: accentColor ?? this.accentColor,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
