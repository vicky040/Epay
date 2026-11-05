import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../account/balance_record_screen.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  static const _presets = [500.0, 1000.0, 2800.0, 4800.0, 9800.0, 28000.0];
  static const _methods = [
    ('upi', 'UPI', Icons.qr_code_scanner_rounded),
    ('bank', 'Bank transfer', Icons.account_balance_outlined),
    ('usdt', 'USDT (TRC20)', Icons.currency_bitcoin_rounded),
  ];

  final _amount = TextEditingController();
  int _method = 0;
  bool _busy = false;

  double get _value => double.tryParse(_amount.text.trim()) ?? 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_value < 100) {
      showToast(context, 'Minimum recharge is ₹100', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final msg = await Api.i.recharge(_value, _methods[_method].$1);
      await Session.i.refresh();
      if (!mounted) return;
      _amount.clear();
      showToast(context, msg);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.i.user;
    return SubPage(
      title: 'Recharge',
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
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recharge balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      money(u?.rechargeBalance ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SectionTitle('Amount'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}\.?\d{0,2}')),
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
                      color: AppColors.orange,
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
                const Divider(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _presets.map((p) {
                    final sel = _value == p;
                    return GestureDetector(
                      onTap: () => setState(
                          () => _amount.text = p.toStringAsFixed(0)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: sel ? AppColors.ctaGradient : null,
                          color: sel ? null : AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? Colors.transparent : AppColors.line,
                          ),
                        ),
                        child: Text(
                          moneyTrim(p),
                          style: TextStyle(
                            color: sel ? Colors.white : AppColors.subText,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SectionTitle('Payment method'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < _methods.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  InkWell(
                    onTap: () => setState(() => _method = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          IconTile(
                            icon: _methods[i].$3,
                            colors: const [Color(0xFF4FC3F7), Color(0xFF1570D6)],
                            size: 40,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _methods[i].$2,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Icon(
                            _method == i
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color:
                                _method == i ? AppColors.primary : AppColors.muted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: _value > 0 ? 'Recharge ${moneyTrim(_value)}' : 'Recharge',
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
                color: AppColors.gold.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.gold),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Minimum recharge ₹100. Funds are credited once the bank '
                      'confirms the payment, usually within a few minutes.',
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
}
