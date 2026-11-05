import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class NavSpec {
  final IconData icon;
  final String label;
  const NavSpec(this.icon, this.label);
}

/// Floating bottom bar with a raised centre action, matching the reference UI.
class EpayBottomNav extends StatelessWidget {
  static const double barHeight = 68;
  static const double reserved = 86;

  final int index;
  final ValueChanged<int> onTap;
  final int centerIndex;

  static const specs = <NavSpec>[
    NavSpec(Icons.home_outlined, 'Home'),
    NavSpec(Icons.ssid_chart_rounded, 'Invest'),
    NavSpec(Icons.notifications_none_rounded, 'Notice'),
    NavSpec(Icons.menu_book_outlined, 'Blog'),
    NavSpec(Icons.person_outline_rounded, 'Account'),
  ];

  const EpayBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    this.centerIndex = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: reserved,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 10,
            right: 10,
            bottom: 8,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(specs.length, (i) {
                  if (i == centerIndex) return const Expanded(child: SizedBox());
                  return Expanded(child: _item(i));
                }),
              ),
            ),
          ),
          Positioned(
            bottom: barHeight - 16,
            child: _centerButton(context),
          ),
        ],
      ),
    );
  }

  Widget _item(int i) {
    final sel = index == i;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(i);
      },
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: sel ? AppColors.ice : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              specs[i].icon,
              size: 23,
              color: sel ? AppColors.primary : AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            specs[i].label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? AppColors.primary : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerButton(BuildContext context) {
    final sel = index == centerIndex;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap(centerIndex);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.ctaGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.42),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Notice',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? AppColors.primary : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
