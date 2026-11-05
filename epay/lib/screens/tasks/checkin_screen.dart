import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/logo.dart';
import '../../models/models.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  List<VipTier> _tiers = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await Api.i.vipTiers();
      if (mounted) setState(() => _tiers = t);
    } catch (_) {
      // The screen renders fine without the tier list.
    }
  }

  double get _todayBonus {
    final lvl = Session.i.user?.vipLevel ?? 0;
    for (final t in _tiers) {
      if (t.level == lvl) return t.dailyBonus;
    }
    return 0;
  }

  Future<void> _checkIn() async {
    setState(() => _busy = true);
    try {
      final reward = await Api.i.checkIn();
      await Session.i.refresh();
      if (!mounted) return;
      _showReward(reward);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } catch (e) {
      if (mounted) {
        showToast(context, '$e'.replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showReward(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const RewardBurst(size: 118),
                  const EpayLogo(size: 60),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Checked in!',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                amount > 0
                    ? 'You earned ${moneyTrim(amount)}'
                    : 'Upgrade to VIP1 to start earning daily bonuses',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: 'Great',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.i.user;
    final done = u?.checkedInToday ?? false;

    return SubPage(
      title: 'Daily Check-in',
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 30),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadows.raised,
            ),
            child: Column(
              children: [
                Text(
                  "Today's bonus",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  moneyTrim(_todayBonus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'VIP ${u?.vipLevel ?? 0} daily reward',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: done ? 'Already checked in today' : 'Check in now',
                  loading: _busy,
                  gradient: done
                      ? const LinearGradient(
                          colors: [Color(0xFF8CA3C4), Color(0xFF6B82A3)])
                      : AppColors.goldGradient,
                  onPressed: done ? null : _checkIn,
                ),
              ],
            ),
          ),
          const SectionTitle('This week'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final today = DateTime.now().weekday - 1 == i;
                final past = i < DateTime.now().weekday - 1;
                final checked = past || (today && done);
                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: checked ? AppColors.ctaGradient : null,
                        color: checked ? null : AppColors.bg,
                        shape: BoxShape.circle,
                        border: today && !done
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        checked ? Icons.check_rounded : Icons.circle_outlined,
                        size: 18,
                        color: checked ? Colors.white : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: today ? FontWeight.w800 : FontWeight.w500,
                        color: today ? AppColors.primary : AppColors.muted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SectionTitle('Daily bonus by tier'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < _tiers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      children: [
                        Text(
                          'VIP ${_tiers[i].level}',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _tiers[i].level == (u?.vipLevel ?? 0)
                                ? AppColors.primary
                                : AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${moneyTrim(_tiers[i].dailyBonus)} / day',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
