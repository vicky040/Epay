import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/logo.dart';
import '../../models/models.dart';

class LuckyScreen extends StatefulWidget {
  const LuckyScreen({super.key});

  @override
  State<LuckyScreen> createState() => _LuckyScreenState();
}

class _LuckyScreenState extends State<LuckyScreen> {
  List<LuckyPrize> _prizes = const [];
  List<LuckyWin> _wins = const [];
  List<LuckyWin> _myWins = const [];
  int _chances = 0;
  bool _loading = true;

  // the 8 perimeter cells of a 3x3 grid, clockwise from top-left
  static const _ring = [0, 1, 2, 5, 8, 7, 6, 3];
  int _highlight = -1;
  bool _spinning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Api.i.lucky();
      if (!mounted) return;
      setState(() {
        _prizes = r.prizes;
        _wins = r.wins;
        _chances = r.chances;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _spin() async {
    if (_spinning) return;
    if (_chances <= 0) {
      showToast(context, 'No draws remaining', error: true);
      return;
    }

    setState(() => _spinning = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await Api.i.spin();
      final targetIdx =
          _prizes.indexWhere((p) => p.slot == result.slot).clamp(0, 7);

      // animate: accelerate, then settle on the winning cell
      const totalSteps = 34;
      var step = 0;
      final landing = (targetIdx - totalSteps % 8 + 8 * 8) % 8;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 1), (_) {});
      _timer?.cancel();

      void tick() {
        if (!mounted) return;
        setState(() => _highlight = (landing + step) % 8);
        step++;
        if (step <= totalSteps) {
          final t = step / totalSteps;
          final delay = (55 + 190 * math.pow(t, 3)).toInt();
          _timer = Timer(Duration(milliseconds: delay), tick);
        } else {
          setState(() {
            _highlight = targetIdx;
            _spinning = false;
            _chances = (_chances - 1).clamp(0, 9999);
          });
          HapticFeedback.heavyImpact();
          Session.i.refresh();
          _showWin(result.amount);
          _load();
        }
      }

      tick();
    } on ApiException catch (e) {
      setState(() => _spinning = false);
      if (mounted) showToast(context, e.message, error: true);
    } catch (e) {
      setState(() => _spinning = false);
      if (mounted) {
        showToast(context, '$e'.replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  void _showWin(double amount) {
    setState(() {
      _myWins = [
        LuckyWin(
          phone: Session.i.user?.phone ?? '',
          amount: amount,
          createdAt: DateTime.now(),
        ),
        ..._myWins,
      ];
    });

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
                  const RewardBurst(size: 124),
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_rounded,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You won ${moneyTrim(amount)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Credited to your withdrawal balance',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: 'Awesome',
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
    return SubPage(
      title: 'Lucky Wheel',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                _banner(),
                _marquee(),
                const SizedBox(height: 14),
                _grid(),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GradientButton(
                    label: _spinning ? 'Spinning...' : 'Spin Now',
                    onPressed: _spinning ? null : _spin,
                    gradient: AppColors.goldGradient,
                  ),
                ),
                const SizedBox(height: 14),
                _chancesCard(),
                const SectionTitle('Game Rules'),
                _rules(),
                const SectionTitle('My Winning History'),
                _history(),
              ],
            ),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const Text(
            'Happy Lucky Wheel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 17),
                SizedBox(width: 8),
                Text(
                  'Diverse gifts · 100% winning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _marquee() {
    final text = _wins.isEmpty
        ? 'Be the first winner today!'
        : _wins
            .take(5)
            .map((w) => '${maskPhone(w.phone)} won ${moneyTrim(w.amount)}')
            .join('   ·   ');

    return Transform.translate(
      offset: const Offset(0, -22),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        radius: 22,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded,
                  size: 15, color: AppColors.gold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppColors.subText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 24,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (_, cell) {
          if (cell == 4) return _centerCell();
          final ringIdx = _ring.indexOf(cell);
          final prize = ringIdx < _prizes.length ? _prizes[ringIdx] : null;
          final active = _highlight == ringIdx;
          return _prizeCell(prize, active);
        },
      ),
    );
  }

  Widget _centerCell() {
    return GestureDetector(
      onTap: _spinning ? null : _spin,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.ctaGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.raised,
        ),
        alignment: Alignment.center,
        child: Text(
          _spinning ? '...' : 'Start',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _prizeCell(LuckyPrize? prize, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      decoration: BoxDecoration(
        gradient: active
            ? AppColors.goldGradient
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE9F2FE), Color(0xFFD6E7FB)],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.gold : Colors.transparent,
          width: 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  blurRadius: 14,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.redeem_rounded,
            size: 26,
            color: active ? Colors.white : AppColors.primary,
          ),
          const SizedBox(height: 7),
          Text(
            prize == null ? '-' : moneyTrim(prize.amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chancesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$_chances',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your chances',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$_chances draw${_chances == 1 ? '' : 's'} remaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rules() {
    const rules = [
      'Every purchase of a product is eligible for a sweepstakes entry.',
      'Every invitation to a valid member is eligible for a sweepstakes entry.',
      'Prizes are credited to your withdrawal balance instantly.',
      'Entries have no upper limit — the more you take part, the more chances.',
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sweepstakes Rules',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rules.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == rules.length - 1 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rule ${i + 1}:',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rules[i],
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.55,
                        color: AppColors.subText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _history() {
    if (_myWins.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.symmetric(vertical: 34),
        child: EmptyState(
          message: 'No records yet',
          icon: Icons.card_giftcard_outlined,
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < _myWins.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      size: 19, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateTimeLabel(_myWins[i].createdAt),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ),
                  Text(
                    '+${moneyTrim(_myWins[i].amount)}',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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
