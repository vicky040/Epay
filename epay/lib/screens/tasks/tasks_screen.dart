import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../models/models.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskItem> _items = const [];
  bool _loading = true;
  String? _claiming;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await Api.i.tasks();
      if (!mounted) return;
      setState(() => _items = t);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _claim(TaskItem t) async {
    setState(() => _claiming = t.id);
    try {
      final reward = await Api.i.claimTask(t.id);
      await Session.i.refresh();
      if (!mounted) return;
      showToast(context, 'Claimed ${moneyTrim(reward)}');
      await _load();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } catch (e) {
      if (mounted) {
        showToast(context, '$e'.replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _claiming = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAvailable = _items
        .where((t) => t.completed && !t.claimed)
        .fold<double>(0, (s, t) => s + t.reward);

    return SubPage(
      title: 'Tasks',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 30),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ready to claim',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                moneyTrim(totalAvailable),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle('Available tasks'),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(message: 'No tasks right now'),
                    )
                  else
                    ..._items.map(_card),
                ],
              ),
            ),
    );
  }

  Widget _card(TaskItem t) {
    final progress = (t.progress / t.target).clamp(0.0, 1.0);
    final canClaim = t.completed && !t.claimed;

    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: t.claimed
                    ? Icons.check_rounded
                    : Icons.flag_outlined,
                colors: t.claimed
                    ? const [Color(0xFF94A3B8), Color(0xFF64748B)]
                    : const [Color(0xFF4FC3F7), Color(0xFF1570D6)],
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '+${moneyTrim(t.reward)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.line,
                    valueColor: AlwaysStoppedAnimation(
                      t.claimed ? AppColors.muted : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${t.progress}/${t.target}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                child: GradientButton(
                  label: t.claimed
                      ? 'Claimed'
                      : canClaim
                          ? 'Claim'
                          : 'Go',
                  height: 36,
                  radius: 18,
                  loading: _claiming == t.id,
                  gradient: canClaim
                      ? AppColors.goldGradient
                      : AppColors.ctaGradient,
                  onPressed: t.claimed
                      ? null
                      : canClaim
                          ? () => _claim(t)
                          : () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
