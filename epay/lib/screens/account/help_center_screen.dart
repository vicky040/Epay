import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Help Center',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 48),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "We're here for you whenever you need help",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  ServiceRow(
                    icon: Icons.currency_rupee_rounded,
                    colors: const [Color(0xFF4FC3F7), Color(0xFF1570D6)],
                    title: 'Recharge not received?',
                    subtitle:
                        'If your deposit has not arrived within 24 hours, submit a ticket and our team will help.',
                    onTap: () => _ticketSheet(context),
                  ),
                  const Divider(height: 1),
                  ServiceRow(
                    icon: Icons.headset_mic_outlined,
                    colors: const [Color(0xFFFF9A5A), Color(0xFFF2680C)],
                    title: 'Online customer service',
                    subtitle:
                        'Available ${AppConfig.supportHours}. Tap here to chat with us.',
                    onTap: () => _chatSheet(context),
                  ),
                  const Divider(height: 1),
                  ServiceRow(
                    icon: Icons.send_rounded,
                    colors: const [Color(0xFF5CC8F5), Color(0xFF0E7FBF)],
                    title: 'Telegram channel',
                    subtitle: 'Follow for latest news, events and benefits.',
                    onTap: () {
                      Clipboard.setData(
                          const ClipboardData(text: AppConfig.telegramUrl));
                      showToast(context, 'Channel link copied');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('Frequently asked'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: const [
                _Faq(
                  q: 'How long do withdrawals take?',
                  a: 'Most withdrawals are processed within 10 minutes. '
                      'During peak hours it can take up to 24 hours.',
                ),
                Divider(height: 1),
                _Faq(
                  q: 'What is the minimum withdrawal?',
                  a: 'The minimum is ₹100. A small processing tax applies and is '
                      'shown before you confirm.',
                ),
                Divider(height: 1),
                _Faq(
                  q: 'Why is my recharge still pending?',
                  a: 'Payments are confirmed by the bank before they are credited. '
                      'If it has been over 24 hours, open a ticket with your UTR.',
                ),
                Divider(height: 1),
                _Faq(
                  q: 'How do team rebates work?',
                  a: 'You earn a rebate on every purchase made by members in your '
                      'three downline levels. Rebates are credited instantly.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _ticketSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit a ticket',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Include the UTR / reference number of your payment.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the issue...',
                ),
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Submit ticket',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showToast(context, 'Ticket submitted. We will reply shortly.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _chatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconTile(
              icon: Icons.headset_mic_rounded,
              colors: [Color(0xFF4FC3F7), Color(0xFF1570D6)],
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Online customer service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our agents are available ${AppConfig.supportHours}.\n'
              'Average reply time: under 5 minutes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Start chat',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () {
                Navigator.of(ctx).pop();
                showToast(context, 'Connecting you to an agent...');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq extends StatefulWidget {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        onExpansionChanged: (v) => setState(() => _open = v),
        title: Text(
          widget.q,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: _open ? AppColors.primary : AppColors.text,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.muted,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.a,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: AppColors.subText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
