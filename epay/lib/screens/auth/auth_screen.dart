import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/backdrop.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/logo.dart';

class AuthScreen extends StatefulWidget {
  final bool startOnSignUp;
  const AuthScreen({super.key, this.startOnSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _signUp = widget.startOnSignUp;

  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  final _invite = TextEditingController();
  final _otp = TextEditingController();

  bool _obscure = true;
  bool _busy = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_phone, _password, _nickname, _invite, _otp]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    final phone = _phone.text.trim();
    if (phone.length < 10) return 'Enter a valid 10-digit phone number';
    if (_password.text.length < 6) return 'Password must be at least 6 characters';
    if (_signUp) {
      if (_nickname.text.trim().isEmpty) return 'Please choose a nickname';
      if (_otp.text.trim().length < 4) return 'Enter the verification code';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (phone.length < 10) {
      showToast(context, 'Enter your phone number first', error: true);
      return;
    }
    try {
      final code = await Api.i.requestOtp(phone);
      if (!mounted) return;
      setState(() => _cooldown = 60);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _cooldown--);
        if (_cooldown <= 0) t.cancel();
      });
      showToast(
        context,
        code.isEmpty ? 'Verification code sent' : 'Verification code: $code',
      );
      if (code.isNotEmpty) _otp.text = code;
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    }
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      showToast(context, err, error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      if (_signUp) {
        await Session.i.register(
          phone: _phone.text.trim(),
          password: _password.text,
          nickname: _nickname.text.trim(),
          inviteCode: _invite.text.trim().isEmpty ? null : _invite.text.trim(),
          otp: _otp.text.trim(),
        );
      } else {
        await Session.i.login(_phone.text.trim(), _password.text);
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } catch (e) {
      if (mounted) showToast(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ConstellationBackdrop(
        nodes: 30,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                const SizedBox(height: 18),
                const EpayLogo(size: 86),
                const SizedBox(height: 20),
                Text(
                  _signUp ? 'Create account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _signUp
                      ? 'Join EPay and start investing'
                      : 'Sign in to EPay to continue',
                  style: const TextStyle(color: AppColors.subText, fontSize: 14),
                ),
                const SizedBox(height: 26),
                _formCard(),
                const SizedBox(height: 18),
                _switchPrompt(),
                const SizedBox(height: 24),
                const Text(
                  'By continuing you agree to the EPay Terms of Service\nand Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.09),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _toggle(),
          const SizedBox(height: 22),
          _field(
            label: 'Phone number',
            controller: _phone,
            hint: 'Enter phone number',
            keyboardType: TextInputType.phone,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            prefix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.smartphone_rounded,
                    size: 19, color: AppColors.muted),
                const SizedBox(width: 8),
                const Text(
                  '+91',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 9),
                Container(width: 1, height: 22, color: AppColors.line),
                const SizedBox(width: 10),
              ],
            ),
          ),
          _field(
            label: 'Password',
            controller: _password,
            hint: 'At least 6 characters',
            obscure: _obscure,
            prefix: const Padding(
              padding: EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.lock_outline_rounded,
                  size: 19, color: AppColors.muted),
            ),
            suffix: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.muted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          if (_signUp) ...[
            _field(
              label: 'Nickname',
              controller: _nickname,
              hint: 'Your nickname',
              formatters: [LengthLimitingTextInputFormatter(20)],
              prefix: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.person_outline_rounded,
                    size: 19, color: AppColors.muted),
              ),
            ),
            _field(
              label: 'Invitation code',
              controller: _invite,
              hint: 'Optional',
              formatters: [LengthLimitingTextInputFormatter(12)],
              prefix: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.group_add_outlined,
                    size: 19, color: AppColors.muted),
              ),
            ),
            _field(
              label: 'Verification code (OTP)',
              controller: _otp,
              hint: 'Enter OTP',
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              prefix: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.verified_user_outlined,
                    size: 19, color: AppColors.muted),
              ),
              suffix: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TextButton(
                  onPressed: _cooldown > 0 ? null : _sendOtp,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.ice,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _cooldown > 0 ? '${_cooldown}s' : 'Send',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          GradientButton(
            label: _signUp ? 'Create account' : 'Log in',
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _toggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ice,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _toggleItem('Log in', !_signUp, () => setState(() => _signUp = false)),
          _toggleItem('Sign up', _signUp, () => setState(() => _signUp = true)),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active ? AppColors.ctaGradient : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: active ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    Widget? prefix,
    Widget? suffix,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subText,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                if (prefix != null) prefix,
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscure,
                    keyboardType: keyboardType,
                    inputFormatters: formatters,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                        left: prefix == null ? 16 : 0,
                        top: 17,
                        bottom: 17,
                        right: 8,
                      ),
                    ),
                  ),
                ),
                if (suffix != null) suffix else const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _signUp ? 'Already have an account? ' : "Don't have an account? ",
          style: const TextStyle(color: AppColors.subText, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => setState(() => _signUp = !_signUp),
          child: Text(
            _signUp ? 'Log in' : 'Sign up',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
