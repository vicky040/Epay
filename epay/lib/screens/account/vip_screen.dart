import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';
import 'help_center_screen.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  List<VipTier> _tiers = const [];
  bool _loading = true;

  static const _badgeColors = [
    [Color(0xFF94A3B8), Color(0xFF64748B)],
    [Color(0xFF5CC8F5), Color(0xFF1570D6)],
    [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
    [Color(0xFFFFC14D), Color(0xFFF59E0B)],
    [Color(0xFF34D399), Color(0xFF059669)],
    [Color(0xFF9B7CFF), Color(0xFF6C3FE0)],
    [Color(0xFFFF8FC4), Color(0xFFE0479B)],
    [Color(0xFFFF9A5A), Color(0xFFD9480F)],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await Api.i.vipTiers();
    if (!mounted) return;
    setState(() {
      _tiers = t;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final invested = Session.i.user?.totalInvested ?? 0;

    return SubPage(
      title: 'VIP Levels',
      actions: [
        IconButton(
          icon: const Icon(Icons.headset_mic_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
          ),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const SectionTitle('Membership tiers'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(29, 0, 16, 14),
                  child: Text(
                    'Invest more to unlock higher returns and benefits',
                    style: TextStyle(color: AppColors.muted, fontSize: 13.5),
                  ),
                ),
                ..._tiers.map((t) => _tierCard(t, invested)),
              ],
            ),
    );
  }

  Widget _tierCard(VipTier t, double invested) {
    final colors = _badgeColors[t.level % _badgeColors.length];
    final progress = t.requiredAmount == 0
        ? 1.0
        : (invested / t.requiredAmount).clamp(0.0, 1.0);
    final unlocked = invested >= t.requiredAmount;

    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'LV${t.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'VIP ${t.level}',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        if (unlocked) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle,
                              size: 17, color: AppColors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text(
                          'Total investment required: ',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                        ),
                        Text(
                          moneyTrim(t.requiredAmount),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  moneyTrim(t.requiredAmount),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your progress',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13),
                  children: [
                    TextSpan(
                      text: invested.toStringAsFixed(0),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${t.requiredAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation(colors.last),
            ),
          ),
          if (t.dailyBonus > 0 || t.perks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.dailyBonus > 0)
                          Text(
                            'Daily check-in bonus ${moneyTrim(t.dailyBonus)}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.subText,
                            ),
                          ),
                        if (t.perks.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: t.dailyBonus > 0 ? 4 : 0),
                            child: Text(
                              t.perks,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
