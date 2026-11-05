import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/backdrop.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/logo.dart';
import '../../models/models.dart';
import '../lucky/lucky_screen.dart';
import '../tasks/checkin_screen.dart';
import '../tasks/tasks_screen.dart';
import '../team/team_screen.dart';
import '../wallet/bank_card_screen.dart';
import '../wallet/recharge_screen.dart';
import '../wallet/withdraw_screen.dart';
import 'balance_record_screen.dart';
import 'help_center_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';
import 'vip_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<VipTier> _tiers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await Api.i.vipTiers();
    if (mounted) setState(() => _tiers = t);
  }

  VipTier? get _next {
    final lvl = Session.i.user?.vipLevel ?? 0;
    for (final t in _tiers) {
      if (t.level > lvl) return t;
    }
    return null;
  }

  void _push(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) => Session.i.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.i.user;
    return Scaffold(
      body: ConstellationBackdrop(
        child: RefreshIndicator(
          onRefresh: () async {
            await Session.i.refresh();
            await _load();
          },
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _header(u),
              const SizedBox(height: 14),
              _vipCard(u),
              const SizedBox(height: 12),
              _luckyCard(),
              const SectionTitle('Application Service'),
              _serviceCard(),
              const SectionTitle('Support'),
              _supportCard(),
              const SizedBox(height: EpayBottomNav.reserved + 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppUser? u) {
    return GradientHeader(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 42),
              const Expanded(
                child: Text(
                  'My Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _push(const SettingsScreen()),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              EpayAvatar(url: u?.avatar, size: 68),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u?.nickname ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: u?.id ?? ''));
                        showToast(context, 'ID copied');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID ${u?.id ?? '-'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded,
                                size: 13, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _push(const SettingsScreen()),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _balances(u),
        ],
      ),
    );
  }

  Widget _balances(AppUser? u) {
    Widget cell(String label, double v) => Expanded(
          child: Column(
            children: [
              Text(
                money(v),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          cell('Recharge Balance', u?.rechargeBalance ?? 0),
          Container(
              width: 1, height: 30, color: Colors.white.withValues(alpha: 0.22)),
          cell('Withdrawal Balance', u?.withdrawBalance ?? 0),
          Container(
              width: 1, height: 30, color: Colors.white.withValues(alpha: 0.22)),
          cell('Product Income', u?.productIncome ?? 0),
        ],
      ),
    );
  }

  Widget _vipCard(AppUser? u) {
    final lvl = u?.vipLevel ?? 0;
    final invested = u?.totalInvested ?? 0;
    final next = _next;
    final progress = next == null || next.requiredAmount == 0
        ? 1.0
        : (invested / next.requiredAmount).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _push(const VipScreen()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  'VIP Level $lvl',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Upgrade',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                next == null
                    ? 'You have reached the highest tier'
                    : 'Upgrade to VIP${next.level} needs '
                        '${moneyTrim((next.requiredAmount - invested).clamp(0, double.infinity))} more',
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _luckyCard() {
    return GestureDetector(
      onTap: () => _push(const LuckyScreen()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C5CFC), Color(0xFFEC4899)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Lucky',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Spin the Wheel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Win amazing prizes every day',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          ServiceRow(
            icon: Icons.account_balance_wallet_outlined,
            colors: const [Color(0xFF4FC3F7), Color(0xFF1570D6)],
            title: 'My Balance',
            trailing: _viewPill(),
            onTap: () => _push(const BalanceRecordScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.receipt_long_outlined,
            colors: const [Color(0xFF9B7CFF), Color(0xFF6C3FE0)],
            title: 'My Orders',
            onTap: () => _push(const OrdersScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.currency_rupee_rounded,
            colors: const [Color(0xFFFFC14D), Color(0xFFF59E0B)],
            title: 'Recharge',
            onTap: () => _push(const RechargeScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.outbound_outlined,
            colors: const [Color(0xFF4ADE80), Color(0xFF12A05F)],
            title: 'Withdraw',
            onTap: () => _push(const WithdrawScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.credit_card_outlined,
            colors: const [Color(0xFF64748B), Color(0xFF334155)],
            title: 'Bank Card',
            onTap: () => _push(const BankCardScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.groups_rounded,
            colors: const [Color(0xFFFF9A5A), Color(0xFFF2680C)],
            title: 'My Team',
            onTap: () => _push(const TeamScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.assignment_turned_in_outlined,
            colors: const [Color(0xFF34D399), Color(0xFF059669)],
            title: 'Tasks',
            onTap: () => _push(const TasksScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.event_available_outlined,
            colors: const [Color(0xFFFF8FC4), Color(0xFFE0479B)],
            title: 'Daily Check-in',
            onTap: () => _push(const CheckInScreen()),
          ),
        ],
      ),
    );
  }

  Widget _supportCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          ServiceRow(
            icon: Icons.support_agent_rounded,
            colors: const [Color(0xFF4FC3F7), Color(0xFF1570D6)],
            title: 'Help Center',
            onTap: () => _push(const HelpCenterScreen()),
          ),
          const Divider(height: 1),
          ServiceRow(
            icon: Icons.settings_outlined,
            colors: const [Color(0xFF94A3B8), Color(0xFF475569)],
            title: 'Settings',
            onTap: () => _push(const SettingsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _viewPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.ice,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'View',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
