import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';

class BankCardScreen extends StatefulWidget {
  const BankCardScreen({super.key});

  @override
  State<BankCardScreen> createState() => _BankCardScreenState();
}

class _BankCardScreenState extends State<BankCardScreen> {
  final _holder = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  final _bank = TextEditingController();
  final _upi = TextEditingController();

  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_holder, _account, _ifsc, _bank, _upi]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await Api.i.bankCard();
      if (!mounted) return;
      if (c != null) {
        _holder.text = c.holder;
        _account.text = c.accountNumber;
        _ifsc.text = c.ifsc;
        _bank.text = c.bankName;
        _upi.text = c.upi ?? '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_holder.text.trim().isEmpty ||
        _account.text.trim().length < 6 ||
        _ifsc.text.trim().length < 6 ||
        _bank.text.trim().isEmpty) {
      showToast(context, 'Please fill in all bank details', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await Api.i.saveBankCard(
        BankCard(
          holder: _holder.text.trim(),
          accountNumber: _account.text.trim(),
          ifsc: _ifsc.text.trim().toUpperCase(),
          bankName: _bank.text.trim(),
          upi: _upi.text.trim().isEmpty ? null : _upi.text.trim(),
        ),
      );
      if (!mounted) return;
      showToast(context, 'Bank details saved');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Bank Card',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 32),
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  height: 165,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.raised,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        bottom: -14,
                        child: Icon(
                          Icons.account_balance_outlined,
                          size: 110,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bank.text.isEmpty ? 'Your bank' : _bank.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _account.text.isEmpty
                                ? '•••• •••• ••••'
                                : _mask(_account.text),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _holder.text.isEmpty
                                    ? 'ACCOUNT HOLDER'
                                    : _holder.text.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12.5,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                _ifsc.text.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12.5,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Bank details'),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _field('Account holder name', _holder,
                          hint: 'As printed on your passbook'),
                      _field('Account number', _account,
                          hint: 'Enter account number',
                          keyboard: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(18),
                          ]),
                      _field('IFSC code', _ifsc,
                          hint: 'e.g. HDFC0001234',
                          caps: true,
                          formatters: [LengthLimitingTextInputFormatter(11)]),
                      _field('Bank name', _bank, hint: 'e.g. HDFC Bank'),
                      _field('UPI ID (optional)', _upi,
                          hint: 'name@bank', last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GradientButton(
                    label: 'Save bank details',
                    loading: _busy,
                    onPressed: _save,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Make sure the details are correct. Withdrawals sent to an '
                    'incorrect account cannot be recovered.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _mask(String acc) {
    if (acc.length <= 4) return acc;
    final tail = acc.substring(acc.length - 4);
    return '•••• •••• $tail';
  }

  Widget _field(
    String label,
    TextEditingController c, {
    String? hint,
    bool last = false,
    bool caps = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.subText,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: c,
            keyboardType: keyboard,
            inputFormatters: formatters,
            textCapitalization:
                caps ? TextCapitalization.characters : TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
