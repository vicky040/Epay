import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/widgets/bottom_nav.dart';
import 'auth/auth_screen.dart';
import 'account/account_screen.dart';
import 'blog/blog_screen.dart';
import 'home/home_screen.dart';
import 'invest/invest_screen.dart';
import 'notice/notice_screen.dart';

/// Lets any descendant jump to another root tab.
class TabSwitcher extends InheritedWidget {
  final void Function(int) go;
  const TabSwitcher({super.key, required this.go, required super.child});

  static void jump(BuildContext context, int index) {
    context.dependOnInheritedWidgetOfExactType<TabSwitcher>()?.go(index);
  }

  @override
  bool updateShouldNotify(TabSwitcher oldWidget) => false;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _go(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    Session.i.refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.i.isLoggedIn) return const AuthScreen();

    return TabSwitcher(
      go: _go,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            InvestScreen(),
            NoticeScreen(),
            BlogScreen(),
            AccountScreen(),
          ],
        ),
        bottomNavigationBar: EpayBottomNav(index: _index, onTap: _go),
      ),
    );
  }
}
