import 'dart:async';

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
import '../account/help_center_screen.dart';
import '../account/vip_screen.dart';
import '../lucky/lucky_screen.dart';
import '../shell.dart';
import '../tasks/checkin_screen.dart';
import '../tasks/tasks_screen.dart';
import '../team/team_screen.dart';
import '../wallet/recharge_screen.dart';
import '../wallet/withdraw_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppBannerItem> _banners = const [];
  List<BlogPost> _feed = const [];
  final _pageCtrl = PageController();
  Timer? _autoScroll;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final b = await Api.i.banners();
    final f = await Api.i.blogs();
    if (!mounted) return;
    setState(() {
      _banners = b;
      _feed = f.take(6).toList();
    });
    _autoScroll?.cancel();
    if (b.length > 1) {
      _autoScroll = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_pageCtrl.hasClients) return;
        _page = (_page + 1) % b.length;
        _pageCtrl.animateToPage(
          _page,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  Future<void> _refresh() async {
    await Session.i.refresh();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.i.user;
    return Scaffold(
      body: ConstellationBackdrop(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _hero(user)),
              SliverToBoxAdapter(child: _quickActions()),
              SliverToBoxAdapter(child: _inviteBanner()),
              SliverToBoxAdapter(child: _liveFeed()),
              SliverToBoxAdapter(child: _trustStrip()),
              const SliverToBoxAdapter(
                child: SizedBox(height: EpayBottomNav.reserved + 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ hero --

  Widget _hero(AppUser? user) {
    return GradientHeader(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const EpayWordmark(height: 28, onDark: true),
              ),
              const Spacer(),
              _circleAction(
                Icons.notifications_none_rounded,
                badge: true,
                onTap: () => TabSwitcher.jump(context, 2),
              ),
              const SizedBox(width: 10),
              _circleAction(
                Icons.headset_mic_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _bannerCarousel(),
          const SizedBox(height: 18),
          _balanceStrip(user),
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon, {bool badge = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          if (badge)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bannerCarousel() {
    if (_banners.isEmpty) {
      return Container(
        height: 168,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RemoteImage(_banners[i].image),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.navyDeep.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      bottom: 14,
                      child: Text(
                        'Invest smarter. Earn daily.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i == _page ? 0.95 : 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _balanceStrip(AppUser? u) {
    Widget cell(String label, double v) => Expanded(
          child: Column(
            children: [
              Text(
                money(v),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

    final divider = Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.22),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          cell('Charged Balance', u?.rechargeBalance ?? 0),
          divider,
          cell('Withdrawal Balance', u?.withdrawBalance ?? 0),
          divider,
          cell('Product Revenue', u?.productIncome ?? 0),
        ],
      ),
    );
  }

  // --------------------------------------------------------- quick actions --

  Widget _quickActions() {
    final items = <_Action>[
      _Action(Icons.currency_rupee_rounded, 'Recharge',
          [const Color(0xFFFFC14D), const Color(0xFFF59E0B)],
          () => _push(const RechargeScreen())),
      _Action(Icons.layers_outlined, 'Withdraw',
          [const Color(0xFF3FB6F5), const Color(0xFF1570D6)],
          () => _push(const WithdrawScreen())),
      _Action(Icons.groups_rounded, 'Team',
          [const Color(0xFFFF9A5A), const Color(0xFFF2680C)],
          () => _push(const TeamScreen())),
      _Action(Icons.diamond_outlined, 'VIP',
          [const Color(0xFF9B7CFF), const Color(0xFF6C3FE0)],
          () => _push(const VipScreen())),
      _Action(Icons.assignment_turned_in_outlined, 'Tasks',
          [const Color(0xFF4ADE80), const Color(0xFF12A05F)],
          () => _push(const TasksScreen())),
      _Action(Icons.thumb_up_alt_outlined, 'Check-in',
          [const Color(0xFFFF8FC4), const Color(0xFFE0479B)],
          () => _push(const CheckInScreen())),
      _Action(Icons.card_giftcard_rounded, 'Lucky',
          [const Color(0xFFFFD166), const Color(0xFFF0A202)],
          () => _push(const LuckyScreen())),
      _Action(Icons.menu_book_rounded, 'Blog',
          [const Color(0xFFFF7A8A), const Color(0xFFE23B50)],
          () => TabSwitcher.jump(context, 3)),
    ];

    return Transform.translate(
      offset: const Offset(0, -14),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        radius: 22,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            childAspectRatio: 0.86,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final a = items[i];
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                a.onTap();
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTile(icon: a.icon, colors: a.colors, size: 54),
                  const SizedBox(height: 9),
                  Text(
                    a.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subText,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) => Session.i.refresh());
  }

  // ---------------------------------------------------------------- invite --

  Widget _inviteBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GestureDetector(
        onTap: () => _push(const TeamScreen()),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1B6BEA), Color(0xFF0B2E7A)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -8,
                child: Opacity(
                  opacity: 0.22,
                  child: Icon(Icons.share_rounded,
                      size: 92, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Exclusive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Invite friends and earn rewards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Text(
                        'Reward for each activation: ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        '₹100',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Invite Now',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            color: AppColors.primary, size: 19),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- live feed --

  Widget _liveFeed() {
    if (_feed.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Latest withdrawals',
          trailing: GestureDetector(
            onTap: () => TabSwitcher.jump(context, 3),
            child: const Row(
              children: [
                Text(
                  'View all',
                  style: TextStyle(color: AppColors.primary, fontSize: 13),
                ),
                Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          child: Column(
            children: [
              for (var i = 0; i < _feed.length; i++) ...[
                _feedRow(_feed[i]),
                if (i != _feed.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _feedRow(BlogPost p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          const EpayAvatar(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  maskPhone(p.authorPhone),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (p.reward > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                moneyTrim(p.reward),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ trust strip --

  Widget _trustStrip() {
    Widget item(IconData icon, String title, String sub) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Row(
          children: [
            item(Icons.verified_user_outlined, 'Secure', 'Bank-grade\nencryption'),
            item(Icons.bolt_rounded, 'Fast', 'Payouts in\nminutes'),
            item(Icons.support_agent_rounded, 'Support', '7 days\na week'),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  _Action(this.icon, this.label, this.colors, this.onTap);
}
