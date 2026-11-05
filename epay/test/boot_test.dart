import 'package:epay/core/session.dart';
import 'package:epay/models/models.dart';
import 'package:epay/screens/shell.dart';
import 'package:epay/main.dart';
import 'package:epay/screens/auth/auth_screen.dart';
import 'package:epay/screens/splash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The screens animate forever (the constellation backdrop and the splash
/// spinner both repeat), so `pumpAndSettle` would never return. Pump a bounded
/// number of frames instead.
Future<void> pumpFrames(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Session.i.logout();
    Session.i.booted = false;
  });

  testWidgets('a signed-out launch leaves the splash and shows sign-in',
      (tester) async {
    await tester.pumpWidget(const EpayApp());
    await pumpFrames(tester);

    expect(
      find.byType(SplashScreen),
      findsNothing,
      reason: 'the app must not stay on the splash screen once boot() finishes',
    );
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('Session.boot completes and flips booted', (tester) async {
    await tester.pumpWidget(const EpayApp());
    await pumpFrames(tester);

    expect(Session.i.booted, isTrue);
  });

  testWidgets('signing in swaps the sign-in screen for the tab shell',
      (tester) async {
    await tester.pumpWidget(const EpayApp());
    await pumpFrames(tester);
    expect(find.byType(AuthScreen), findsOneWidget);

    // Session notifies exactly as it does after a real login.
    Session.i.setUser(
      const AppUser(
        id: '1',
        phone: '9999999999',
        nickname: 'Tester',
        inviteCode: 'ABCDE',
        vipLevel: 0,
        rechargeBalance: 0,
        withdrawBalance: 0,
        productIncome: 0,
        totalInvested: 0,
        drawChances: 0,
        checkedInToday: false,
      ),
    );
    await pumpFrames(tester);

    expect(find.byType(AuthScreen), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('logging out returns to the sign-in screen', (tester) async {
    await tester.pumpWidget(const EpayApp());
    await pumpFrames(tester);

    Session.i.setUser(
      const AppUser(
        id: '1',
        phone: '9999999999',
        nickname: 'Tester',
        inviteCode: 'ABCDE',
        vipLevel: 0,
        rechargeBalance: 0,
        withdrawBalance: 0,
        productIncome: 0,
        totalInvested: 0,
        drawChances: 0,
        checkedInToday: false,
      ),
    );
    await pumpFrames(tester);
    expect(find.byType(AppShell), findsOneWidget);

    await Session.i.logout();
    await pumpFrames(tester);

    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
