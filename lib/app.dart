import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../config/themes/themes.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/todo/todo_screen.dart';
import '../screens/diary/diary_screen.dart';
import '../screens/completed/completed_screen.dart';
import '../screens/settings/settings_screen.dart';

/// 路由配置
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // 登录页面
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 注册页面
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 主页面（带底部导航）
      ShellRoute(
        builder: (context, state, child) {
          return HomeScreen(
            child: child,
            location: state.matchedLocation,
          );
        },
        routes: [
          // 日历页面
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),

          // 待办页面
          GoRoute(
            path: '/todo',
            builder: (context, state) => const TodoScreen(),
          ),

          // 日记页面
          GoRoute(
            path: '/diary',
            builder: (context, state) => const DiaryScreen(),
          ),

          // 完成板块页面
          GoRoute(
            path: '/completed',
            builder: (context, state) => const CompletedScreen(),
          ),

          // 设置页面
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          // 默认主页
          GoRoute(
            path: '/home',
            builder: (context, state) => const CalendarScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('页面未找到: ${state.error}'),
      ),
    ),
  );
});

/// 应用主组件
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: '日记待办',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
