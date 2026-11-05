import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _tabs = [
    ('all', 'All'),
    ('active', 'In Gains'),
    ('finished', 'Finished'),
  ];

  int _tab = 0;
  bool _loading = true;
  List<Order> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final o = await Api.i.orders(status: _tabs[_tab].$1);
      if (!mounted) return;
      setState(() => _items = o);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'My Orders',
      body: Column(
        children: [
          SegmentTabs(
            items: _tabs.map((e) => e.$2).toList(),
            index: _tab,
            onChanged: (i) {
              setState(() => _tab = i);
              _load();
            },
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _items.isEmpty
                    ? const EmptyState(
                        message: 'No orders',
                        subtitle: 'Products you invest in will show up here.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 14, 0, 24),
                          itemCount: _items.length,
                          itemBuilder: (_, i) => _card(_items[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(Order o) {
    final active = o.status == 'active';
    final progress = o.expectedTotal == 0
        ? 0.0
        : (o.earnedSoFar / o.expectedTotal).clamp(0.0, 1.0);

    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RemoteImage(
                o.productImage,
                width: 64,
                height: 64,
                radius: BorderRadius.circular(13),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.productTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${o.shares} share${o.shares == 1 ? '' : 's'} · ${dateLabel(o.createdAt)}',
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: (active ? AppColors.green : AppColors.muted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  active ? 'In Gains' : 'Finished',
                  style: TextStyle(
                    color: active ? AppColors.green : AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatPair(
                  label: 'Invested',
                  value: moneyTrim(o.amount),
                  valueColor: AppColors.orange,
                ),
              ),
              Expanded(
                child: StatPair(
                  label: 'Earned',
                  value: moneyTrim(o.earnedSoFar),
                  valueColor: AppColors.green,
                ),
              ),
              Expanded(
                child: StatPair(
                  label: 'Expected',
                  value: moneyTrim(o.expectedTotal),
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.line,
              valueColor: AlwaysStoppedAnimation(
                active ? AppColors.primary : AppColors.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}% complete',
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
              Text(
                o.endsAt == null ? '' : 'Ends ${dateLabel(o.endsAt)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
