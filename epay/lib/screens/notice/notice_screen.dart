import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/backdrop.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<Notice> _items = const [];
  bool _loading = true;

  static const _icons = [
    Icons.payments_outlined,
    Icons.groups_rounded,
    Icons.card_membership_outlined,
    Icons.casino_outlined,
    Icons.send_rounded,
  ];
  static const _palettes = [
    [Color(0xFF4FC3F7), Color(0xFF1570D6)],
    [Color(0xFFFFB74D), Color(0xFFF2680C)],
    [Color(0xFF9B7CFF), Color(0xFF6C3FE0)],
    [Color(0xFF4ADE80), Color(0xFF12A05F)],
    [Color(0xFFFF8FC4), Color(0xFFE0479B)],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final n = await Api.i.notices();
      if (!mounted) return;
      setState(() => _items = n);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Notice'),
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
      ),
      body: ConstellationBackdrop(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _items.isEmpty
                  ? const EmptyState(message: 'No announcements')
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            0, 10, 0, EpayBottomNav.reserved + 12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          return AppCard(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: const EdgeInsets.all(12),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NoticeDetailScreen(notice: n),
                              ),
                            ),
                            child: Row(
                              children: [
                                n.image.isNotEmpty
                                    ? RemoteImage(
                                        n.image,
                                        width: 62,
                                        height: 62,
                                        radius: BorderRadius.circular(12),
                                      )
                                    : IconTile(
                                        icon: _icons[i % _icons.length],
                                        colors: _palettes[i % _palettes.length],
                                        size: 62,
                                      ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 13,
                                            color: AppColors.muted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateTimeLabel(n.createdAt),
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.muted),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}

class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Notice Details',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.card,
            border: const Border(
              top: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'EPay',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    dateTimeLabel(notice.createdAt),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 18),
              if (notice.image.isNotEmpty) ...[
                RemoteImage(
                  notice.image,
                  width: double.infinity,
                  height: 180,
                  radius: BorderRadius.circular(14),
                ),
                const SizedBox(height: 18),
              ],
              Text(
                notice.body,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.85,
                  color: AppColors.subText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
