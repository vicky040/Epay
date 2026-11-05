import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'backdrop.dart';

/// Primary CTA — gradient pill with a press animation.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Gradient gradient;
  final double height;
  final IconData? icon;
  final double radius;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.gradient = AppColors.ctaGradient,
    this.height = 54,
    this.icon,
    this.radius = 27,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: enabled ? AppShadows.raised : null,
            ),
            alignment: Alignment.center,
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// "▌ Section title" — the accent-bar heading used throughout the app.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionTitle(
    this.text, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 17,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// White rounded surface with the standard elevation.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;
  final Color color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.radius = 18,
    this.onTap,
    this.color = AppColors.card,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: body,
    );
  }
}

/// Soft-tinted rounded icon tile (Recharge / Withdraw / Team / VIP …).
class IconTile extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final double size;

  const IconTile({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.33),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.33),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}

/// Segmented pill selector (Steady / Benefits / Event, All / In Gains / …).
class SegmentTabs extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final List<Widget?> badges;
  final bool onDark;

  const SegmentTabs({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.badges = const [],
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: onDark
            ? const LinearGradient(colors: [AppColors.navyDeep, AppColors.navy])
            : null,
        color: onDark ? null : Colors.white,
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final sel = i == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.ctaGradient : null,
                        color: sel
                            ? null
                            : (onDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.ice),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        items[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: sel
                              ? Colors.white
                              : (onDark
                                  ? Colors.white.withValues(alpha: 0.62)
                                  : AppColors.muted),
                        ),
                      ),
                    ),
                  ),
                  if (i < badges.length && badges[i] != null)
                    Positioned(top: -7, right: -2, child: badges[i]!),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class HotBadge extends StatelessWidget {
  const HotBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          'Hot',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

/// Empty-state placeholder with the surprised face from the reference app.
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.message = 'No records',
    this.icon = Icons.sentiment_satisfied_alt_outlined,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.line, width: 1.6),
            ),
            child: Icon(icon, size: 30, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Network image with a branded shimmer placeholder and graceful failure.
class RemoteImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;

  const RemoteImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCE9FB), Color(0xFFC7DCF7)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.primary.withValues(alpha: 0.35),
        size: 28,
      ),
    );

    final img = url.isEmpty
        ? placeholder
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => placeholder,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : placeholder,
          );

    return radius == null ? img : ClipRRect(borderRadius: radius!, child: img);
  }
}

/// Standard sub-page chrome: ice-blue app bar + constellation body.
class SubPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const SubPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD5ECFF), Color(0xFFE6F3FF)],
            ),
          ),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.chevron_left, size: 30),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        actions: actions,
      ),
      body: ConstellationBackdrop(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// A labelled key/value row used on detail cards.
class StatPair extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;

  const StatPair({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Full-width list row with leading icon tile, title and chevron.
class ServiceRow extends StatelessWidget {
  final IconData icon;
  final List<Color> colors;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ServiceRow({
    super.key,
    required this.icon,
    required this.colors,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            IconTile(icon: icon, colors: colors, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 22),
          ],
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: error ? AppColors.red : AppColors.cyan,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
}
