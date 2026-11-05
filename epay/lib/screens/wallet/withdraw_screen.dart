import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';
import '../account/balance_record_screen.dart';
import 'bank_card_screen.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const double minWithdraw = 100;
  static const double taxRate = 0.05;

  final _amount = TextEditingController();
  BankCard? _card;
  bool _busy = false;
  bool _loadingCard = true;

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;
  double get _tax => (_value * taxRate);
  double get _receive => (_value - _tax).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadCard() async {
    final c = await Api.i.bankCard();
    if (!mounted) return;
    setState(() {
      _card = c;
      _loadingCard = false;
    });
  }

  Future<void> _submit() async {
    final available = Session.i.user?.withdrawBalance ?? 0;
    if (_card == null) {
      showToast(context, 'Add a bank account first', error: true);
      return;
    }
    if (_value < minWithdraw) {
      showToast(context, 'Minimum withdrawal is ${moneyTrim(minWithdraw)}',
          error: true);
      return;
    }
    if (_value > available) {
      showToast(context, 'Amount exceeds your withdrawable balance', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final msg = await Api.i.withdraw(_value);
      await Session.i.refresh();
      if (!mounted) return;
      _amount.clear();
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
    final available = Session.i.user?.withdrawBalance ?? 0;

    return SubPage(
      title: 'Withdraw',
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BalanceRecordScreen()),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.raised,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawable balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  money(available),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Receiving account'),
          AppCard(
            padding: const EdgeInsets.all(16),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BankCardScreen()),
              );
              _loadCard();
            },
            child: _loadingCard
                ? const SizedBox(
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      IconTile(
                        icon: _card == null
                            ? Icons.add_card_outlined
                            : Icons.account_balance_outlined,
                        colors: const [Color(0xFF4FC3F7), Color(0xFF1570D6)],
                        size: 46,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _card == null
                                  ? 'Add a bank account'
                                  : _card!.bankName,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _card == null
                                  ? 'Required before your first withdrawal'
                                  : '${_card!.holder} · ****${_card!.accountNumber.length > 4 ? _card!.accountNumber.substring(_card!.accountNumber.length - 4) : _card!.accountNumber}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
          ),
          const SectionTitle('Amount'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amount,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,7}\.?\d{0,2}')),
                        ],
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.line,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(
                          () => _amount.text = available.toStringAsFixed(2)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.ice,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _row('Processing tax (5%)', moneyTrim(_tax), AppColors.orange),
                const SizedBox(height: 10),
                _row('You receive', moneyTrim(_receive), AppColors.green,
                    bold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: 'Submit withdrawal',
              loading: _busy,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Withdrawals are processed 08:00 — 20:00 IST, usually within '
                      '10 minutes. Minimum ₹100 per request.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: AppColors.subText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v, Color c, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: TextStyle(
              color: bold ? AppColors.text : AppColors.muted,
              fontSize: bold ? 15 : 13.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            v,
            style: TextStyle(
              color: c,
              fontSize: bold ? 18 : 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
