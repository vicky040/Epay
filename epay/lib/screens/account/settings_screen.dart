import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _nickname =
      TextEditingController(text: Session.i.user?.nickname ?? '');
  String? _avatar = Session.i.user?.avatar;
  bool _busy = false;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final ctrl = TextEditingController(text: _avatar ?? '');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profile photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste an image URL. Recommended 1:1, at least 100px.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'https://...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Use'),
          ),
        ],
      ),
    );
    if (url != null) setState(() => _avatar = url.isEmpty ? null : url);
  }

  Future<void> _save() async {
    if (_nickname.text.trim().isEmpty) {
      showToast(context, 'Nickname cannot be empty', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final u = await Api.i.updateProfile(
        nickname: _nickname.text.trim(),
        avatar: _avatar,
      );
      Session.i.setUser(u);
      if (mounted) showToast(context, 'Profile updated');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Session.i.logout();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.i.user;
    return SubPage(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 30),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            onTap: _changePhoto,
            child: Row(
              children: [
                Stack(
                  children: [
                    EpayAvatar(url: _avatar, size: 60),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: AppColors.ctaGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tap to change photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Recommended 1:1 image > 100px',
                        style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Account'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _row(
                  'Phone',
                  Text(
                    u?.phone ?? '-',
                    style: const TextStyle(color: AppColors.muted, fontSize: 15),
                  ),
                ),
                const Divider(height: 1),
                _row(
                  'Nickname',
                  TextField(
                    controller: _nickname,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Your nickname',
                    ),
                  ),
                  expand: true,
                ),
                const Divider(height: 1),
                _row(
                  'Invite code',
                  Text(
                    u?.inviteCode ?? '-',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: 'Save',
              loading: _busy,
              onPressed: _save,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _logout,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Center(
            child: Text(
              'EPay · v1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, Widget value, {bool expand = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            if (expand) Expanded(child: value) else const Spacer(),
            if (!expand) value,
          ],
        ),
      );
}
