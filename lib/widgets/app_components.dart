import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';

/// The single card primitive for the whole app.
///
/// Replaces the previous `AppTheme.luxuryCardDecoration()` pattern: one
/// elevation ramp, one border treatment, one radius.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AppRadius.lg,
    this.color,
    this.elevated = false,
    this.selected = false,
    this.glow,
    this.onTap,
    this.border,
    this.gradient,
  });

  /// A recessed well for grouped content inside a card.
  const AppSurface.inset({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AppRadius.md,
    this.color,
    this.elevated = false,
    this.selected = false,
    this.glow,
    this.onTap,
    this.border,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  /// Overrides the resolved surface colour.
  final Color? color;

  /// One elevation step up (`surfaceRaised`).
  final bool elevated;

  /// Draws the brand-coloured active state.
  final bool selected;

  /// Optional brand glow behind the card.
  final Color? glow;

  final BorderSide? border;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    final base = color ??
        (selected
            ? c.primary.withValues(alpha: 0.10)
            : elevated
                ? t.surfaceRaised
                : t.surface);

    final borderSide = border ??
        BorderSide(
          color: selected ? c.primary.withValues(alpha: 0.55) : t.hairline,
          width: selected ? 1.4 : 1,
        );

    final radiusAll = BorderRadius.circular(radius);

    final decoration = BoxDecoration(
      color: gradient == null ? base : null,
      gradient: gradient,
      borderRadius: radiusAll,
      border: Border.fromBorderSide(borderSide),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: t.shadowSoft,
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        if (glow != null)
          BoxShadow(
            color: glow!.withValues(alpha: AppAlpha.soft),
            blurRadius: 22,
            spreadRadius: -2,
          ),
      ],
    );

    Widget content = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radiusAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radiusAll,
          splashColor: c.primary.withValues(alpha: AppAlpha.wash),
          highlightColor: c.primary.withValues(alpha: AppAlpha.wash),
          child: content,
        ),
      );
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Frosted-glass surface for floating chrome (nav dock, sticky app bars).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AppRadius.xl,
    this.blur = 20,
    this.padding,
    this.margin,
    this.borderColor,
    this.tint,
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? t.hairline, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: t.shadowStrong,
              blurRadius: 24,
              offset: const Offset(0, 10)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 2,
              offset: const Offset(0, -1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint ?? t.surfaceGlass,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small status/metadata pill. One implementation, every screen.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.background,
    this.dense = false,
    this.filled = true,
    this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;
  final bool dense;
  final bool filled;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = color ?? t.textSecondary;

    final bg = background ??
        (selected
            ? accent.withValues(alpha: AppAlpha.strong)
            : filled
                ? accent.withValues(alpha: AppAlpha.soft)
                : Colors.transparent);

    final fg = selected ? t.textPrimary : accent;

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpace.sm : AppSpace.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.allPill,
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.55)
              : accent.withValues(alpha: AppAlpha.soft),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? AppIcon.xs : AppIcon.sm, color: fg),
            SizedBox(width: dense ? 4 : 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.pill(fg),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// Tinted square icon container — the app's standard list/row leading element.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = AppIcon.md,
    this.radius = AppRadius.sm,
    this.selected = false,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;
  final double radius;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = color ?? t.brand;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(
            alpha: selected ? AppAlpha.strong : AppAlpha.soft),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: selected ? 0.5 : AppAlpha.medium),
          width: 1,
        ),
      ),
      child: Icon(icon, size: iconSize, color: accent),
    );
  }
}

/// Determinate progress bar with a tokenised track.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.background,
    this.showLabel = false,
  });

  /// 0.0 – 1.0
  final double value;
  final Color? color;
  final double height;
  final Color? background;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;
    final pct = value.clamp(0.0, 1.0);
    final fill = color ?? c.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            children: <Widget>[
              Container(height: height, color: background ?? t.hairline),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(height),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: fill.withValues(alpha: AppAlpha.glow),
                        blurRadius: 8,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...<Widget>[
          const SizedBox(height: AppSpace.sm),
          Text(
            '${(pct * 100).round()}% complete',
            style: context.text.bodySmall!.copyWith(color: fill),
          ),
        ],
      ],
    );
  }
}

/// Uppercase section label + optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.gutter,
      AppSpace.section,
      AppSpace.gutter,
      AppSpace.md,
    ),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title.toUpperCase(),
                  style: AppTypography.sectionLabel(context.tokens.textMuted),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpace.xs),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              ),
              child: Text(actionLabel!,
                  style: context.text.labelMedium!.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w700,
                  )),
            ),
        ],
      ),
    );
  }
}

/// Consistent empty / zero-state block.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    final ringSize = compact ? 64.0 : 88.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.x3l,
          vertical: compact ? AppSpace.xxl : AppSpace.x4l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: AppAlpha.soft),
                border: Border.all(
                    color: c.primary.withValues(alpha: AppAlpha.medium)),
              ),
              child:
                  Icon(icon, size: compact ? AppIcon.xl : 40, color: c.primary),
            ),
            SizedBox(height: compact ? AppSpace.xl : AppSpace.xxl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpace.xl),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: AppIcon.sm),
                label: Text(actionLabel!),
              ),
            ],
            if (t.canvas == t.canvas) const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder block with a gentle pulse.
class AppSkeletonBox extends StatefulWidget {
  const AppSkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = AppRadius.xs,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(
            t.surfaceRaised,
            t.surfaceOverlay,
            _controller.value,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Primary action button with an inline loading state.
///
/// Prevents double submission, per the interaction rules in the design system.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.expand = true,
    this.variant = AppButtonVariant.filled,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final AppButtonVariant variant;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;
    final accent = color ?? c.primary;

    final enabled = onPressed != null && !loading;

    final fg = variant == AppButtonVariant.filled ? t.textOnBrand : accent;

    final child = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppIcon.sm, color: fg),
                const SizedBox(width: AppSpace.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge!.copyWith(color: fg),
                ),
              ),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: fg,
            disabledBackgroundColor: t.surfaceRaised,
            disabledForegroundColor: t.textMuted,
            minimumSize: const Size(0, AppSpace.touchTarget),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          ),
          child: child,
        ),
      AppButtonVariant.outlined => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(color: accent.withValues(alpha: AppAlpha.medium)),
            minimumSize: const Size(0, AppSpace.touchTarget),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            minimumSize: const Size(0, AppSpace.touchTarget),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          ),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: t.danger,
            foregroundColor: Colors.white,
            disabledBackgroundColor: t.surfaceRaised,
            disabledForegroundColor: t.textMuted,
            minimumSize: const Size(0, AppSpace.touchTarget),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          ),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum AppButtonVariant { filled, outlined, ghost, danger }

/// Screen header used by every non-AppBar page: icon chip, title, subtitle,
/// and an optional trailing action. Removes three duplicated ~50-line blocks.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.leading,
    this.bottom,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: context.tokens.canvas,
        border: Border(bottom: BorderSide(color: context.tokens.hairline)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                if (onBack != null) ...<Widget>[
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: onBack,
                  ),
                  const SizedBox(width: AppSpace.md),
                ] else if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: AppSpace.md),
                ],
                AppIconTile(
                    icon: icon,
                    color: c.primary,
                    size: 40,
                    iconSize: AppIcon.md),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleLarge,
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (bottom != null) ...<Widget>[
              const SizedBox(height: AppSpace.lg),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular icon button with a guaranteed ≥48dp hit area.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.tokens.surfaceRaised,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x14FFFFFF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppSpace.touchTarget,
            height: AppSpace.touchTarget,
            child: Icon(
              icon,
              size: AppIcon.md,
              color: context.colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Public circular icon button with a 48dp hit area and a tooltip label.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
    this.background,
    this.size = AppSpace.touchTarget,
    this.iconSize = AppIcon.md,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;
  final Color? background;
  final double size;
  final double iconSize;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? context.tokens.surfaceRaised,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0x1FFFFFFF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(icon,
                    size: iconSize, color: color ?? context.colors.onSurface),
                if (badge != null) Positioned(right: 8, top: 8, child: badge!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pill segmented control driven by an explicit index.
///
/// Material's [TabBar] only works inside a [TabBarView]; screens that swap
/// [CustomScrollView] slivers need this instead. One component so the control
/// looks identical wherever the app switches between peer views.
class AppSegmentControl extends StatelessWidget {
  const AppSegmentControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.icons,
  });

  final List<String> labels;
  final List<IconData>? icons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: t.hairline),
      ),
      child: Row(
        children: <Widget>[
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                icon: (icons != null && i < icons!.length) ? icons![i] : null,
                selected: i == selectedIndex,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.allSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.primary : Colors.transparent,
              borderRadius: AppRadius.allSm,
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: c.primary.withValues(alpha: AppAlpha.glow),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: AppIcon.sm,
                    color: selected ? t.textOnBrand : t.textMuted,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium!.copyWith(
                      color: selected ? t.textOnBrand : t.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
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

/// Horizontally scrollable chip row with consistent edge padding.
class AppChipRow extends StatelessWidget {
  const AppChipRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    this.spacing = AppSpace.sm,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: const BouncingScrollPhysics(),
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, i) => Center(child: children[i]),
      ),
    );
  }
}

/// Friendly toast replacing ad-hoc SnackBar calls.
void showAppSnack(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  bool isError = false,
}) {
  final t = context.tokens;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(milliseconds: 2600),
      content: Row(
        children: <Widget>[
          Icon(
            icon,
            size: AppIcon.sm,
            color: isError ? t.danger : t.success,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
