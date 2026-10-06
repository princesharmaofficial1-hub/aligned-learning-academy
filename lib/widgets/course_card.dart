import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/design_tokens.dart';
import '../theme/tech_palette.dart';
import 'app_components.dart';

/// The canonical course card.
///
/// One component, three density variants so Explore, My Learning and the
/// detail hero all read as the same family instead of three hand-built cards.
enum CourseCardVariant {
  /// Full-bleed 16:9 banner + body. Used in the Explore catalogue.
  catalog,

  /// Compact horizontal row for lists of many courses.
  compact,

  /// Single-line row for narrow sidebars/overlays.
  ultraCompact,
}

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.onBookmark,
    this.variant = CourseCardVariant.catalog,
    this.showProgress = false,
  });

  final Course course;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final CourseCardVariant variant;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      CourseCardVariant.catalog => _CatalogCourseCard(
          course: course,
          onTap: onTap,
          onBookmark: onBookmark,
          showProgress: showProgress,
        ),
      CourseCardVariant.compact => _CompactCourseCard(
          course: course,
          onTap: onTap,
          onBookmark: onBookmark,
          showProgress: showProgress,
        ),
      CourseCardVariant.ultraCompact => _CompactCourseCard(
          course: course,
          onTap: onTap,
          onBookmark: null,
          showProgress: showProgress,
          dense: true,
        ),
    };
  }
}

// =============================================================================
// Catalog — 16:9 banner
// =============================================================================

class _CatalogCourseCard extends StatelessWidget {
  const _CatalogCourseCard({
    required this.course,
    required this.onTap,
    required this.onBookmark,
    required this.showProgress,
  });

  final Course course;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return Semantics(
      button: true,
      label: '${course.title}. ${course.university}. '
          'Rating ${course.rating}. ${course.estimatedHours}.',
      child: AppSurface(
        radius: AppRadius.lg,
        margin: const EdgeInsets.only(bottom: AppSpace.lg),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Banner(course: course, onBookmark: onBookmark),
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: <Widget>[
                      Icon(Icons.school_rounded,
                          size: AppIcon.xs, color: t.textMuted),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          '${course.university} · ${course.author}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: <Widget>[
                      AppPill(
                        label: course.level,
                        icon: Icons.signal_cellular_alt_rounded,
                        color: TechPalette.levelColor(course.level),
                        dense: true,
                      ),
                      for (final tech in course.techStacks.take(3))
                        AppPill(
                          label: tech,
                          icon: TechPalette.iconFor(tech),
                          color: TechPalette.colorFor(tech),
                          dense: true,
                        ),
                    ],
                  ),
                  if (showProgress && course.overallProgress > 0) ...<Widget>[
                    const SizedBox(height: AppSpace.md),
                    AppProgressBar(
                        value: course.overallProgress, color: t.green),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      '${(course.overallProgress * 100).round()}% complete',
                      style: context.text.bodySmall!.copyWith(color: t.green),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Divider(height: 1, color: t.hairline),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Wrap(
                          spacing: AppSpace.md,
                          runSpacing: AppSpace.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            _Metric(
                              icon: Icons.star_rounded,
                              value: course.rating.toStringAsFixed(1),
                              color: t.accent,
                            ),
                            _Metric(
                              icon: Icons.people_alt_rounded,
                              value: _compactCount(course.enrolledCount),
                              color: t.textMuted,
                            ),
                            _Metric(
                              icon: Icons.schedule_rounded,
                              value: course.estimatedHours,
                              color: t.textMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: AppRadius.allSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Explore',
                              style: context.text.labelMedium!.copyWith(
                                color: t.textOnBrand,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Icon(Icons.arrow_forward_rounded,
                                size: AppIcon.sm, color: t.textOnBrand),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.course, this.onBookmark});

  final Course course;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      child: SizedBox(
        height: 156,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (course.thumbnailUrl.isNotEmpty)
              Image.network(
                course.thumbnailUrl,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => _FallbackBanner(course: course),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        color: t.surfaceRaised,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
              )
            else
              _FallbackBanner(course: course),

            // Legibility scrim: top for meta chips, bottom for the title plate.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const <double>[0, 0.45, 1],
                ),
              ),
            ),

            Positioned(
              top: AppSpace.md,
              left: AppSpace.md,
              right: AppSpace.md,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      children: <Widget>[
                        _ScrimChip(
                          label: course.category.toUpperCase(),
                          color: c.primary,
                          filled: true,
                        ),
                        _ScrimChip(label: course.badge, color: t.accent),
                      ],
                    ),
                  ),
                  if (onBookmark != null) ...<Widget>[
                    const SizedBox(width: AppSpace.sm),
                    _BookmarkButton(
                      bookmarked: course.isBookmarked,
                      onTap: onBookmark!,
                    ),
                  ],
                ],
              ),
            ),

            Positioned(
              left: AppSpace.md,
              right: AppSpace.md,
              bottom: AppSpace.md,
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: _ScrimChip(
                            icon: Icons.play_circle_fill_rounded,
                            label: course.lectures.isNotEmpty
                                ? '${course.lectures.length} lectures'
                                : 'Full syllabus',
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: _ScrimChip(
                            icon: Icons.description_rounded,
                            label: course.documents.isNotEmpty
                                ? '${course.documents.length} docs'
                                : 'Tech labs',
                            color: t.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: AppRadius.allXs,
                      border: Border.all(
                        color: t.green.withValues(alpha: AppAlpha.medium),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: t.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          'VERIFIED',
                          style: context.text.labelSmall!.copyWith(
                            fontSize: 9.5,
                            color: t.green,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackBanner extends StatelessWidget {
  const _FallbackBanner({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            c2(t.brandDeep, 0.55),
            t.surfaceRaised,
            c2(t.green, 0.32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              'assets/images/aligned_icon.png',
              height: 38,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => Icon(
                Icons.play_circle_fill_rounded,
                size: 38,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              course.code,
              style: context.text.labelMedium!.copyWith(
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrimChip extends StatelessWidget {
  const _ScrimChip({
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: filled ? color : Colors.black.withValues(alpha: 0.55),
        borderRadius: AppRadius.allXs,
        border: Border.all(
          color: filled
              ? Colors.transparent
              : color.withValues(alpha: AppAlpha.strong),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: AppIcon.xs, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: filled ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.bookmarked, required this.onTap});

  final bool bookmarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Semantics(
      button: true,
      selected: bookmarked,
      label: bookmarked ? 'Remove bookmark' : 'Bookmark course',
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppSpace.touchTarget,
            height: AppSpace.touchTarget,
            child: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: AppIcon.md,
              color: bookmarked ? t.accent : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Compact — horizontal row
// =============================================================================

class _CompactCourseCard extends StatelessWidget {
  const _CompactCourseCard({
    required this.course,
    required this.onTap,
    required this.onBookmark,
    required this.showProgress,
    this.dense = false,
  });

  final Course course;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool showProgress;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = TechPalette.levelColor(course.level);
    final progress = showProgress ? course.overallProgress : 0.0;

    return Semantics(
      button: true,
      label: '${course.title}. ${course.university}.'
          '${progress > 0 ? ' ${(progress * 100).round()} percent complete.' : ''}',
      child: AppSurface(
        radius: AppRadius.md,
        margin: EdgeInsets.only(bottom: dense ? AppSpace.md : AppSpace.lg),
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: AppRadius.allSm,
              child: SizedBox(
                width: dense ? 72 : 92,
                height: dense ? 52 : 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (course.thumbnailUrl.isNotEmpty)
                      Image.network(
                        course.thumbnailUrl,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, __, ___) =>
                            _SolidThumb(color: accent),
                      )
                    else
                      _SolidThumb(color: accent),
                    if (progress > 0)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(t.green),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: dense
                        ? context.text.titleMedium
                        : context.text.titleLarge,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    course.university,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      AppPill(
                        label: course.level,
                        color: accent,
                        dense: true,
                      ),
                      AppPill(
                        label: course.lectures.isNotEmpty
                            ? '${course.lectures.length} lectures'
                            : 'Full syllabus',
                        icon: Icons.play_circle_outline_rounded,
                        color: t.textMuted,
                        dense: true,
                      ),
                    ],
                  ),
                  if (showProgress && progress > 0) ...<Widget>[
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: AppProgressBar(
                                value: progress, color: t.green, height: 5)),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          '${(progress * 100).round()}%',
                          style:
                              context.text.labelSmall!.copyWith(color: t.green),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onBookmark != null)
              IconButton(
                onPressed: onBookmark,
                tooltip:
                    course.isBookmarked ? 'Remove bookmark' : 'Bookmark course',
                iconSize: AppIcon.md,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  course.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: course.isBookmarked ? t.accent : t.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SolidThumb extends StatelessWidget {
  const _SolidThumb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[c2(color, 0.45), context.tokens.surfaceRaised],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: color,
        size: AppIcon.lg,
      ),
    );
  }
}

// =============================================================================
// Small helpers
// =============================================================================

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: AppIcon.sm, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: context.text.labelMedium!.copyWith(
            color: context.colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 12500 → "12.5k"
String _compactCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

/// `Color.withValues` shorthand that keeps gradients readable.
Color c2(Color color, double alpha) => color.withValues(alpha: alpha);
