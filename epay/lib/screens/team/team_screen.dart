import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  TeamInfo? _info;
  bool _loading = true;

  static const _levelColors = [
    [Color(0xFFFFC14D), Color(0xFFF59E0B)],
    [Color(0xFF94A3B8), Color(0xFF64748B)],
    [Color(0xFFD08A4B), Color(0xFF9A5B1E)],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await Api.i.team();
    if (!mounted) return;
    setState(() {
      _info = t;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Team Details',
      body: _loading || _info == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 30),
                children: [
                  _inviteCard(_info!),
                  SectionTitle(
                    'Team Level',
                    trailing: Text(
                      '1 activation: ${moneyTrim(_info!.activationReward)}',
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ..._info!.levels.map(_levelCard),
                  const SizedBox(height: 10),
                  _summary(_info!),
                ],
              ),
            ),
    );
  }

  Widget _inviteCard(TeamInfo info) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(
            icon: Icons.link_rounded,
            colors: [Color(0xFF4FC3F7), Color(0xFF1570D6)],
            size: 50,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite link',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 5),
                Text(
                  info.inviteLink,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '1 activation reward: ${moneyTrim(info.activationReward)}',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: info.inviteLink));
              HapticFeedback.mediumImpact();
              showToast(context, 'Invite link copied');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                gradient: AppColors.ctaGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.raised,
              ),
              child: const Text(
                'Copy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCard(TeamLevel l) {
    final colors = _levelColors[(l.level - 1) % _levelColors.length];
    Widget cell(String v, String label) => Expanded(
          child: Column(
            children: [
              Text(
                v,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        );

    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${l.level}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${l.rebatePercent.toStringAsFixed(l.rebatePercent % 1 == 0 ? 0 : 1)}%',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Rebate',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          cell('${l.invited}', 'Invite'),
          cell('${l.active}', 'Active'),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }

  Widget _summary(TeamInfo info) {
    final totalInvited = info.levels.fold<int>(0, (s, l) => s + l.invited);
    final totalActive = info.levels.fold<int>(0, (s, l) => s + l.active);
    final totalEarned = info.levels.fold<double>(0, (s, l) => s + l.earned);

    Widget cell(String label, String v, Color c) => Expanded(
          child: Column(
            children: [
              Text(
                v,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: c,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          cell('Total invited', '$totalInvited', AppColors.text),
          cell('Active', '$totalActive', AppColors.green),
          cell('Rebate earned', moneyTrim(totalEarned), AppColors.primary),
        ],
      ),
    );
  }
}
