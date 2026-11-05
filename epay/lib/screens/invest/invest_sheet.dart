import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';
import 'invest_screen.dart';

/// Purchase sheet — share stepper, cost and expected return.
Future<bool?> showInvestSheet(BuildContext context, Product product) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InvestSheet(product: product),
  );
}

class _InvestSheet extends StatefulWidget {
  final Product product;
  const _InvestSheet({required this.product});

  @override
  State<_InvestSheet> createState() => _InvestSheetState();
}

class _InvestSheetState extends State<_InvestSheet> {
  int _shares = 1;
  bool _busy = false;

  Product get p => widget.product;

  double get _pay => p.price * _shares;
  double get _expect => p.total * _shares;

  Future<void> _buy() async {
    final user = Session.i.user;
    if (user != null && user.vipLevel < p.vipRequired) {
      showToast(
        context,
        'This product requires VIP${p.vipRequired}. Upgrade to unlock it.',
        error: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final msg = await Api.i.buy(p.id, _shares);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showToast(context, msg);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RemoteImage(
                  p.image,
                  width: 58,
                  height: 58,
                  radius: BorderRadius.circular(14),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 7),
                      VipChip(level: p.vipRequired, compact: true),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: StatPair(
                    label: 'Each Price',
                    value: moneyTrim(p.price),
                    valueColor: AppColors.orange,
                  ),
                ),
                Expanded(
                  child: StatPair(label: 'Revenue', value: p.durationLabel),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatPair(
                    label: p.earningLabel,
                    value: moneyTrim(p.periodEarning),
                    valueColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: StatPair(
                    label: 'Total Revenue',
                    value: moneyTrim(p.total),
                    valueColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: StatPair(label: 'Max', value: '${p.maxPerUser}'),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _row(
                    'Share',
                    trailing: Row(
                      children: [
                        _stepBtn(Icons.remove_rounded, _shares > 1,
                            () => setState(() => _shares--)),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '$_shares',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        _stepBtn(Icons.add_rounded, _shares < p.maxPerUser,
                            () => setState(() => _shares++)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _row(
                    'Pay',
                    trailing: Text(
                      moneyTrim(_pay),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _row(
                    'Expect',
                    trailing: Text(
                      moneyTrim(_expect),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              label: 'Invest now',
              loading: _busy,
              onPressed: _buy,
            ),
            const SizedBox(height: 8),
            Text(
              'Returns are credited to your withdrawal balance each cycle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted.withValues(alpha: 0.9),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, {required Widget trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            trailing,
          ],
        ),
      );

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.ice : AppColors.line.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.primary : AppColors.muted,
        ),
      ),
    );
  }
}
