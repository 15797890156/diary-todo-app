import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'services/services.dart';

void main() async {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化所有本地存储服务
  await _initServices();

  // 初始化日期格式化（中文）
  await initializeDateFormatting('zh_CN', null);

  // 运行应用
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 初始化所有服务
Future<void> _initServices() async {
  // 初始化本地存储服务
  final localStorage = LocalStorageService();
  await localStorage.init();

  // 初始化认证服务
  final authService = AuthService();
  await authService.init();

  // 初始化数据库服务
  final databaseService = DatabaseService();
  await databaseService.init();

  // 初始化时间管理服务
  final timeManagementService = TimeManagementService();
  await timeManagementService.init();

  // 初始化交易服务
  final transactionService = TransactionService();
  await transactionService.init();

  // 初始化分析服务
  final analyticsService = AnalyticsService();
  await analyticsService.init();

  // 初始化完成事项服务
  final completedItemsService = CompletedItemsService();
  await completedItemsService.init();
}
