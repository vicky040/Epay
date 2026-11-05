import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/config.dart';
import 'core/session.dart';
import 'core/theme.dart';
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
    return AnimatedBuilder(
      animation: Session.i,
      builder: (context, _) {
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
      },
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  void initState() {
    super.initState();
    Session.i.boot();
  }

  @override
  Widget build(BuildContext context) {
    if (!Session.i.booted) return const SplashScreen();
    return const AppShell();
  }
}
