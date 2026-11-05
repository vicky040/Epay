import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/shell.dart';
import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EpayApp());
}

class EpayApp extends StatelessWidget {
  const EpayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.2,
        child: child!,
      ),
      home: const _Root(),
    );
  }
}

/// Decides what the app shows: the splash while the stored session loads, then
/// either sign-in or the tab shell.
///
/// This listens to [Session] itself rather than relying on an ancestor to
/// rebuild it. A parent that returns a `const` child hands back the identical
/// widget instance every time, and Flutter skips rebuilding an identical
/// subtree — which previously left the app stuck on the splash screen forever.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  void initState() {
    super.initState();
    Session.i.addListener(_onSessionChanged);
    Session.i.boot();
  }

  @override
  void dispose() {
    Session.i.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.i.booted) return const SplashScreen();
    // Switching widget *type* here is what makes the subtree swap: returning
    // the same type with different internal state would be skipped as above.
    if (!Session.i.isLoggedIn) return const AuthScreen();
    return const AppShell();
  }
}
