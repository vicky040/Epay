import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import '../models/models.dart';

/// Holds the signed-in user and keeps it fresh across screens.
class Session extends ChangeNotifier {
  Session._();
  static final Session i = Session._();

  static const _kToken = 'epay.token';

  AppUser? user;
  bool booted = false;

  bool get isLoggedIn => user != null;

  /// Wires the API's 401 handler once, so a rejected token signs the user out
  /// rather than leaving screens waiting on requests that cannot succeed.
  void _attachUnauthorizedHandler() {
    Api.i.onUnauthorized ??= () {
      if (user != null) logout();
    };
  }

  Future<void> boot() async {
    _attachUnauthorizedHandler();
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kToken);
    if (t != null && t.isNotEmpty) {
      Api.i.token = t;
      try {
        user = await Api.i.me();
      } catch (_) {
        Api.i.token = null;
        await prefs.remove(_kToken);
      }
    }
    booted = true;
    notifyListeners();
  }

  Future<void> _persist(String token, AppUser u) async {
    Api.i.token = token;
    user = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    final r = await Api.i.login(phone, password);
    await _persist(r.token, r.user);
  }

  Future<void> register({
    required String phone,
    required String password,
    required String nickname,
    String? inviteCode,
    String? otp,
  }) async {
    final r = await Api.i.register(
      phone: phone,
      password: password,
      nickname: nickname,
      inviteCode: inviteCode,
      otp: otp,
    );
    await _persist(r.token, r.user);
  }

  /// Pulls the latest balances. Safe to call from anywhere.
  Future<void> refresh() async {
    if (Api.i.token == null) return;
    try {
      user = await Api.i.me();
      notifyListeners();
    } catch (_) {
      // keep the last known state
    }
  }

  void setUser(AppUser u) {
    user = u;
    notifyListeners();
  }

  Future<void> logout() async {
    Api.i.token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    notifyListeners();
  }
}
