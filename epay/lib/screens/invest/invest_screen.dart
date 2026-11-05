import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/backdrop.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';
import '../account/help_center_screen.dart';
import 'invest_sheet.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key});

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  int _tab = 0;
  bool _grid = false;
  bool _loading = true;
  List<Product> _products = const [];

  static const _cats = ProductCategory.values;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await Api.i.products(_cats[_tab]);
      if (!mounted) return;
      setState(() => _products = p);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSheet(Product p) async {
    final bought = await showInvestSheet(context, p);
    if (bought == true && mounted) {
      await Session.i.refresh();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Investment'),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD5ECFF), Color(0xFFE6F3FF)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
            ),
          ),
        ],
      ),
      body: ConstellationBackdrop(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: Column(
            children: [
              SegmentTabs(
                items: _cats.map((e) => e.label).toList(),
                index: _tab,
                badges: const [null, null, HotBadge()],
                onChanged: (i) {
                  setState(() => _tab = i);
                  _load();
                },
              ),
              SectionTitle(
                'All Products',
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                trailing: _viewToggle(),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _products.isEmpty
                        ? const EmptyState(
                            message: 'No products yet',
                            subtitle: 'New plans are added regularly.',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: AppColors.primary,
                            child: _grid ? _gridView() : _listView(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewToggle() {
    Widget btn(IconData icon, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 32,
            decoration: BoxDecoration(
              gradient: active ? AppColors.ctaGradient : null,
              color: active ? null : Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: active ? null : AppShadows.soft,
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.white : AppColors.muted,
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          btn(Icons.view_agenda_outlined, !_grid, () => setState(() => _grid = false)),
          const SizedBox(width: 4),
          btn(Icons.grid_view_rounded, _grid, () => setState(() => _grid = true)),
        ],
      ),
    );
  }

  Widget _listView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, EpayBottomNav.reserved + 12),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: _products[i],
        onInvest: () => _openSheet(_products[i]),
      ),
    );
  }

  Widget _gridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, EpayBottomNav.reserved + 12),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.58,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => _ProductGridCard(
        product: _products[i],
        onInvest: () => _openSheet(_products[i]),
      ),
    );
  }
}

// --------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onInvest;

  const _ProductCard({required this.product, required this.onInvest});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: RemoteImage(p.image, height: 170, width: double.infinity),
              ),
              Positioned(left: 12, top: 12, child: VipChip(level: p.vipRequired)),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    p.durationLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (p.hot)
                const Positioned(right: 12, bottom: 12, child: HotBadge()),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: StatPair(
                        label: 'Price',
                        value: money(p.price),
                        valueColor: AppColors.orange,
                      ),
                    ),
                    Expanded(
                      child: StatPair(
                        label: p.earningLabel,
                        value: moneyTrim(p.periodEarning),
                        valueColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatPair(
                        label: p.hourly ? 'Hours' : 'Days',
                        value: p.durationLabel,
                      ),
                    ),
                    Expanded(
                      child: StatPair(
                        label: 'Total',
                        value: moneyTrim(p.total),
                        valueColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GradientButton(label: 'Invest now', onPressed: onInvest),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onInvest;

  const _ProductGridCard({required this.product, required this.onInvest});

  @override
  Widget build(BuildContext context) {
    final p = product;
    Widget row(String k, String v, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
              Text(
                v,
                style: TextStyle(
                  color: c,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: RemoteImage(p.image, height: 108, width: double.infinity),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: VipChip(level: p.vipRequired, compact: true),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p.durationLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  row('Price', money(p.price), AppColors.orange),
                  row(p.earningLabel, moneyTrim(p.periodEarning), AppColors.primary),
                  row(p.hourly ? 'Hours' : 'Days', p.durationLabel, AppColors.text),
                  row('Total', moneyTrim(p.total), AppColors.primary),
                  const Spacer(),
                  GradientButton(label: 'Invest now', height: 40, onPressed: onInvest),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VipChip extends StatelessWidget {
  final int level;
  final bool compact;
  const VipChip({super.key, required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 13,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        'VIP$level',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10.5 : 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
