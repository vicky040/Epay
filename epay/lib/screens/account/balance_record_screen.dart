import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';

class BalanceRecordScreen extends StatefulWidget {
  const BalanceRecordScreen({super.key});

  @override
  State<BalanceRecordScreen> createState() => _BalanceRecordScreenState();
}

class _BalanceRecordScreenState extends State<BalanceRecordScreen> {
  static const _filters = [
    ('all', 'All'),
    ('recharge', 'Recharge'),
    ('withdraw', 'Withdraw'),
    ('income', 'Income'),
    ('bonus', 'Bonus'),
    ('purchase', 'Purchase'),
  ];

  int _filter = 0;
  bool _loading = true;
  List<Txn> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await Api.i.transactions(type: _filters[_filter].$1);
      if (!mounted) return;
      setState(() => _items = t);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.i.user;
    return SubPage(
      title: 'Balance Record',
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 22),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.raised,
            ),
            child: Column(
              children: [
                Text(
                  'Account Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  money(u?.totalBalance ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 33,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = i == _filter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _filter = i);
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.ctaGradient : null,
                      color: sel ? null : Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: sel ? null : AppShadows.soft,
                    ),
                    child: Text(
                      _filters[i].$2,
                      style: TextStyle(
                        color: sel ? Colors.white : AppColors.subText,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _items.isEmpty
                    ? const EmptyState(
                        message: 'No records',
                        subtitle: 'Your transactions will appear here.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _items.length,
                          itemBuilder: (_, i) => _row(_items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _row(Txn t) {
    final meta = _meta(t.type);
    final statusColor = switch (t.status) {
      'pending' => AppColors.gold,
      'rejected' => AppColors.red,
      _ => AppColors.green,
    };

    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(icon: meta.$1, colors: meta.$2, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.$3,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  t.note?.isNotEmpty == true
                      ? '${t.note} · ${dateTimeLabel(t.createdAt)}'
                      : dateTimeLabel(t.createdAt),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${t.credit ? '+' : '-'}${moneyTrim(t.amount)}',
                style: TextStyle(
                  color: t.credit ? AppColors.green : AppColors.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.status[0].toUpperCase() + t.status.substring(1),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, List<Color>, String) _meta(String type) => switch (type) {
        'recharge' => (
            Icons.add_card_outlined,
            [const Color(0xFFFFC14D), const Color(0xFFF59E0B)],
            'Recharge'
          ),
        'withdraw' => (
            Icons.outbound_outlined,
            [const Color(0xFF4ADE80), const Color(0xFF12A05F)],
            'Withdrawal'
          ),
        'income' => (
            Icons.trending_up_rounded,
            [const Color(0xFF4FC3F7), const Color(0xFF1570D6)],
            'Product income'
          ),
        'bonus' => (
            Icons.card_giftcard_rounded,
            [const Color(0xFF9B7CFF), const Color(0xFF6C3FE0)],
            'Bonus'
          ),
        'rebate' => (
            Icons.groups_rounded,
            [const Color(0xFFFF9A5A), const Color(0xFFF2680C)],
            'Team rebate'
          ),
        'purchase' => (
            Icons.shopping_bag_outlined,
            [const Color(0xFF64748B), const Color(0xFF334155)],
            'Product purchase'
          ),
        _ => (
            Icons.swap_horiz_rounded,
            [const Color(0xFF94A3B8), const Color(0xFF475569)],
            'Transaction'
          ),
      };
}
