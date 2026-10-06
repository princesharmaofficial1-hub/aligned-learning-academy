import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'app_components.dart';

/// Attribution sheet: where every curriculum comes from and under which
/// licence. Presented as a bottom sheet because it is reference material the
/// user reads but never edits.
class SourcesCreditsDialog extends StatelessWidget {
  const SourcesCreditsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => const SourcesCreditsDialog(),
    );
  }

  static const List<_Source> _sources = <_Source>[
    _Source(
      title: 'MIT OpenCourseWare',
      license: 'CC BY-NC-SA 4.0',
      description:
          'Foundational engineering, distributed systems, algorithms and '
          'cybersecurity courseware, published free for public education by '
          'the Massachusetts Institute of Technology.',
      icon: Icons.school_outlined,
      colorKey: _SourceColor.brand,
    ),
    _Source(
      title: 'Harvard CS & open initiatives',
      license: 'Open Educational Resources',
      description:
          'Modern computer science, Python, backend frameworks and web '
          'architecture material distributed openly for developer upskilling.',
      icon: Icons.auto_stories_outlined,
      colorKey: _SourceColor.green,
    ),
    _Source(
      title: 'Internet Archive OER library',
      license: 'Public domain / CC',
      description:
          'Preserved technical lectures, documentation, conference keynotes '
          'and enterprise architecture workshops.',
      icon: Icons.account_balance_outlined,
      colorKey: _SourceColor.info,
    ),
    _Source(
      title: 'Open source foundations & labs',
      license: 'MIT / Apache 2.0 / CC-BY',
      description:
          'Technical documentation, code repositories and capstone labs from '
          'the Python Software Foundation, CNCF and the Linux Foundation.',
      icon: Icons.code_rounded,
      colorKey: _SourceColor.violet,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(color: t.hairline),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _SheetGrabber(),
              _SheetHeader(onClose: () => Navigator.pop(context)),
              Divider(height: 1, color: t.hairline),
              Flexible(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.lg,
                    AppSpace.gutter,
                    AppSpace.xl,
                  ),
                  children: <Widget>[
                    const _AssuranceCard(),
                    const SectionHeader(
                      title: 'Primary Open Courseware Sources',
                      padding: EdgeInsets.fromLTRB(
                          0, AppSpace.section, 0, AppSpace.md),
                    ),
                    for (final source in _sources)
                      _SourceCard(
                          source: source, color: _resolve(context, source)),
                    const SizedBox(height: AppSpace.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: AppRadius.allMd,
                        border: Border.all(color: t.hairline),
                      ),
                      child: Text(
                        'Attribution notice: all trademarks, course marks and '
                        'university emblems belong to their respective '
                        'copyright holders. Aligned acts as an educational '
                        'aggregator operating under open-licensing and fair-use '
                        'directives.',
                        style: context.text.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    AppButton(
                      label: 'Close',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _resolve(BuildContext context, _Source source) {
    final t = context.tokens;
    return switch (source.colorKey) {
      _SourceColor.brand => context.colors.primary,
      _SourceColor.green => t.green,
      _SourceColor.info => t.info,
      _SourceColor.violet => t.violet,
    };
  }
}

enum _SourceColor { brand, green, info, violet }

@immutable
class _Source {
  const _Source({
    required this.title,
    required this.license,
    required this.description,
    required this.icon,
    required this.colorKey,
  });

  final String title;
  final String license;
  final String description;
  final IconData icon;
  final _SourceColor colorKey;
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.tokens.hairlineStrong,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.lg,
      ),
      child: Row(
        children: <Widget>[
          AppIconTile(
            icon: Icons.verified_user_rounded,
            color: c.primary,
            size: 44,
            iconSize: AppIcon.md,
            selected: true,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Content Sources & Licensing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Open educational resource attribution',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            color: c.onSurface,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _AssuranceCard extends StatelessWidget {
  const _AssuranceCard();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return AppSurface.inset(
      radius: AppRadius.lg,
      color: t.green.withValues(alpha: AppAlpha.wash),
      border: BorderSide(color: t.green.withValues(alpha: AppAlpha.medium)),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.verified_rounded, size: AppIcon.md, color: t.green),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Verified open content only',
                  style: context.text.titleMedium!.copyWith(color: t.green),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Every curriculum, slide deck, code repository and video '
                  'stream in this app originates from verified open-access '
                  'educational initiatives and permissively licensed public '
                  'repositories — authorised for organisational engineering '
                  'training.',
                  style: context.text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.color});

  final _Source source;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      radius: AppRadius.md,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppIconTile(icon: source.icon, color: color, size: 40),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      source.title,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      source.license,
                      style: context.text.labelSmall!.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(source.description, style: context.text.bodySmall),
        ],
      ),
    );
  }
}
