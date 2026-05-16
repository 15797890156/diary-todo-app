import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/themes/themes.dart';

/// 主页面
/// 包含底部导航栏，管理日历、待办、日记三个主要页面
class HomeScreen extends StatefulWidget {
  final Widget child;
  final String location;

  const HomeScreen({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(),
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '日记',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: '完成',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  /// 获取当前选中的索引
  int _getSelectedIndex() {
    if (widget.location.startsWith('/calendar')) return 0;
    if (widget.location.startsWith('/todo')) return 1;
    if (widget.location.startsWith('/diary')) return 2;
    if (widget.location.startsWith('/completed')) return 3;
    if (widget.location.startsWith('/settings')) return 4;
    return 0;
  }

  /// 导航到指定页面
  void _onDestinationSelected(int index) {
    final routes = ['/calendar', '/todo', '/diary', '/completed', '/settings'];
    context.go(routes[index]);
  }
}
