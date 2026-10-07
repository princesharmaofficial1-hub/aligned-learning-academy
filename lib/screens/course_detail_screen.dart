import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/course_document.dart';
import '../models/lecture.dart';
import '../providers/course_provider.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../theme/tech_palette.dart';
import '../widgets/app_components.dart';
import 'video_player_screen.dart';

/// Single curriculum view: cinematic hero, one primary action, and three peer
/// views over the same course record — lectures, resources and overview.
class CourseDetailScreen extends StatefulWidget {
  final Course? course;
  final String? courseId;

  const CourseDetailScreen({
    super.key,
    this.course,
    this.courseId,
  }) : assert(course != null || courseId != null,
            'Provide either course or courseId');

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  /// 0 = lectures, 1 = resources, 2 = overview.
  int _viewIndex = 0;
  bool _isLoadingCurriculum = false;
  String? _curriculumError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurriculum());
  }

  Future<void> _loadCurriculum() async {
    final provider = Provider.of<CourseProvider>(context, listen: false);
    final targetId = widget.course?.id ?? widget.courseId!;
    final course = provider.getCourseById(targetId) ?? widget.course;
    if (course == null) return;

    if (course.isCurriculumLoaded) return;

    if (mounted) {
      setState(() {
        _isLoadingCurriculum = true;
        _curriculumError = null;
      });
    }

    try {
      await provider.loadFullCourseCurriculum(course);
    } catch (e) {
      if (mounted) setState(() => _curriculumError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingCurriculum = false);
    }
  }

  void _openLecture(Course course, Lecture lecture) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          course: course,
          initialLecture: lecture,
        ),
      ),
    );
  }

  Future<void> _shareCourse(Course course) async {
    await Clipboard.setData(ClipboardData(text: course.magnetUri));
    if (!mounted) return;
    showAppSnack(
      context,
      'Curriculum link copied to clipboard',
      icon: Icons.link_rounded,
    );
  }

  void _toggleDownload(Lecture lecture) {
    final provider = context.read<CourseProvider>();
    provider.toggleLectureDownloaded(lecture.id);
    showAppSnack(
      context,
      lecture.isDownloaded
          ? 'Removed from offline downloads'
          : 'Lecture saved for offline viewing',
      icon: lecture.isDownloaded
          ? Icons.delete_outline_rounded
          : Icons.download_done_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final targetId = widget.course?.id ?? widget.courseId!;
        final course = provider.getCourseById(targetId) ?? widget.course;

        if (course == null) {
          return Scaffold(
            backgroundColor: t.canvas,
            body: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          );
        }

        final nextLecture = course.lectures.isEmpty
            ? null
            : course.lectures.firstWhere(
                (l) => l.watchProgress < 0.9,
                orElse: () => course.lectures.first,
              );

        return Scaffold(
          backgroundColor: t.canvas,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              _CourseHero(
                course: course,
                onToggleBookmark: () => provider.toggleBookmark(course.id),
                onShare: () => _shareCourse(course),
              ),

              // ---- Primary action + progress --------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.xl,
                    AppSpace.gutter,
                    AppSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _ResumeAction(
                        course: course,
                        lecture: nextLecture,
                        isLoading: _isLoadingCurriculum,
                        hasError: _curriculumError != null,
                        onPlay: nextLecture == null
                            ? _loadCurriculum
                            : () => _openLecture(course, nextLecture),
                      ),
                      if (course.overallProgress > 0) ...<Widget>[
                        const SizedBox(height: AppSpace.lg),
                        _ProgressPanel(course: course),
                      ],
                    ],
                  ),
                ),
              ),

              // ---- Curriculum sync state -----------------------------------
              if (_isLoadingCurriculum)
                SliverToBoxAdapter(child: _SyncBanner(course: course))
              else if (_curriculumError != null && !course.isCurriculumLoaded)
                SliverToBoxAdapter(
                  child: _PreviewBanner(
                    message: _curriculumError!,
                    onRetry: _loadCurriculum,
                  ),
                ),

              // ---- View switcher -------------------------------------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.xs,
                    AppSpace.gutter,
                    AppSpace.lg,
                  ),
                  child: AppSegmentControl(
                    labels: <String>[
                      'Lectures${course.lectures.isEmpty ? '' : ' ${course.lectures.length}'}',
                      'Resources${course.documents.isEmpty ? '' : ' ${course.documents.length}'}',
                      'Overview',
                    ],
                    icons: const <IconData>[
                      Icons.play_circle_outline_rounded,
                      Icons.description_outlined,
                      Icons.insights_rounded,
                    ],
                    selectedIndex: _viewIndex,
                    onChanged: (value) => setState(() => _viewIndex = value),
                  ),
                ),
              ),

              // ---- Lectures -------------------------------------------------
              if (_viewIndex == 0)
                ..._buildLectures(course)
              // ---- Resources ------------------------------------------------
              else if (_viewIndex == 1)
                ..._buildResources(course)
              // ---- Overview -------------------------------------------------
              else
                ..._buildOverview(course),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Lectures
  // ---------------------------------------------------------------------------

  List<Widget> _buildLectures(Course course) {
    if (course.lectures.isEmpty) {
      return <Widget>[
        SliverToBoxAdapter(
          child: AppEmptyState(
            compact: true,
            icon: _curriculumError != null
                ? Icons.wifi_off_rounded
                : Icons.video_library_outlined,
            title: _curriculumError != null
                ? 'Curriculum sync interrupted'
                : 'Curriculum not loaded yet',
            message: _curriculumError != null
                ? 'Preview lectures are shown until the full archive is reachable.'
                : 'Load the complete lecture syllabus from the open repository.',
            actionLabel: 'Load full curriculum',
            onAction: _loadCurriculum,
          ),
        ),
      ];
    }

    return <Widget>[
      SliverList.builder(
        itemCount: course.lectures.length,
        itemBuilder: (context, i) {
          final lecture = course.lectures[i];
          final startsSection =
              i == 0 || course.lectures[i - 1].section != lecture.section;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (startsSection)
                _SectionHeading(
                  title: lecture.section.isEmpty
                      ? 'Module ${(i ~/ 10) + 1}'
                      : lecture.section,
                ),
              _LectureRow(
                lecture: lecture,
                onTap: () => _openLecture(course, lecture),
                onDownload: () => _toggleDownload(lecture),
              ),
            ],
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpace.x4l)),
    ];
  }

  // ---------------------------------------------------------------------------
  // Resources
  // ---------------------------------------------------------------------------

  List<Widget> _buildResources(Course course) {
    if (course.documents.isEmpty) {
      return const <Widget>[
        SliverToBoxAdapter(
          child: AppEmptyState(
            compact: true,
            icon: Icons.folder_open_rounded,
            title: 'No companion documents',
            message:
                'This curriculum ships video lectures only. Slides and labs '
                'appear here when the repository publishes them.',
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          0,
          AppSpace.gutter,
          AppSpace.x4l,
        ),
        sliver: SliverList.separated(
          itemCount: course.documents.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
          itemBuilder: (context, index) {
            final doc = course.documents[index];
            return _ResourceRow(
              doc: doc,
              onSave: () {
                showAppSnack(
                  context,
                  '“${doc.title}” cached for offline study',
                  icon: Icons.download_done_rounded,
                );
              },
            );
          },
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Overview
  // ---------------------------------------------------------------------------

  List<Widget> _buildOverview(Course course) {
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            0,
            AppSpace.gutter,
            AppSpace.x4l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(
                title: 'Technologies & Stacks',
                subtitle: 'What this curriculum covers',
                padding: EdgeInsets.fromLTRB(0, 0, 0, AppSpace.md),
              ),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: <Widget>[
                  for (final tech in course.techStacks)
                    AppPill(
                      label: tech,
                      icon: TechPalette.iconFor(tech),
                      color: context.techColor(tech),
                    ),
                ],
              ),
              const SectionHeader(
                title: 'Curriculum Overview',
                padding:
                    EdgeInsets.fromLTRB(0, AppSpace.section, 0, AppSpace.md),
              ),
              Text(course.description, style: context.text.bodyMedium),
              const SectionHeader(
                title: 'Curriculum Facts',
                padding:
                    EdgeInsets.fromLTRB(0, AppSpace.section, 0, AppSpace.md),
              ),
              AppSurface.inset(
                radius: AppRadius.lg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.xs,
                ),
                child: Column(
                  children: <Widget>[
                    _FactRow(
                      icon: Icons.storage_rounded,
                      label: 'Curriculum size',
                      value: course.sizeFormatted,
                    ),
                    _FactRow(
                      icon: Icons.ondemand_video_rounded,
                      label: 'Video lectures',
                      value: course.lectures.isEmpty
                          ? 'Full syllabus'
                          : '${course.lectures.length} lessons',
                    ),
                    _FactRow(
                      icon: Icons.folder_copy_rounded,
                      label: 'Learning resources',
                      value: '${course.documents.length} materials',
                    ),
                    _FactRow(
                      icon: Icons.star_rounded,
                      label: 'Student rating',
                      value:
                          '${course.rating} · ${course.enrolledCount} learners',
                      iconColor: context.tokens.accent,
                    ),
                    _FactRow(
                      icon: Icons.schedule_rounded,
                      label: 'Estimated effort',
                      value: course.estimatedHours,
                    ),
                    _FactRow(
                      icon: Icons.speed_rounded,
                      label: 'Streaming',
                      value: 'Verified CDN',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

// =============================================================================
// Hero
// =============================================================================

class _CourseHero extends StatelessWidget {
  const _CourseHero({
    required this.course,
    required this.onToggleBookmark,
    required this.onShare,
  });

  final Course course;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return SliverAppBar(
      expandedHeight: 296,
      pinned: true,
      backgroundColor: t.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpace.xs),
        child: _ScrimIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: _ScrimIconButton(
            icon: course.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            tooltip:
                course.isBookmarked ? 'Remove bookmark' : 'Bookmark course',
            color: course.isBookmarked ? t.accent : null,
            onTap: onToggleBookmark,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              0, AppSpace.xs, AppSpace.sm, AppSpace.xs),
          child: _ScrimIconButton(
            icon: Icons.ios_share_rounded,
            tooltip: 'Copy curriculum link',
            onTap: onShare,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _HeroBackdrop(course: course),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: t.hairline),
      ),
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;
    final levelColor = context.levelColor(course.level);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (course.thumbnailUrl.isNotEmpty)
          Image.network(
            course.thumbnailUrl,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => _HeroFallback(course: course),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _HeroFallback(course: course),
          )
        else
          _HeroFallback(course: course),

        // Top scrim keeps the toolbar controls legible over any artwork.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
              stops: const <double>[0, 0.32],
            ),
          ),
        ),

        // Bottom plate dissolves the artwork into the canvas with high contrast.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.transparent,
                t.canvas.withValues(alpha: 0.45),
                t.canvas.withValues(alpha: 0.92),
                t.canvas,
              ],
              stops: const <double>[0, 0.42, 0.72, 1],
            ),
          ),
        ),

        Positioned(
          left: AppSpace.gutter,
          right: AppSpace.gutter,
          bottom: AppSpace.lg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: <Widget>[
                  AppPill(
                    label: course.category.toUpperCase(),
                    icon: TechPalette.iconFor(course.category),
                    color: c.primary,
                    dense: true,
                  ),
                  AppPill(
                    label: course.level.toUpperCase(),
                    icon: Icons.signal_cellular_alt_rounded,
                    color: levelColor,
                    dense: true,
                  ),
                  AppPill(
                    label: course.code,
                    icon: Icons.verified_rounded,
                    color: t.green,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineSmall!.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Row(
                children: <Widget>[
                  Icon(Icons.school_rounded,
                      size: AppIcon.xs, color: t.textMuted),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${course.university} · ${course.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color.alphaBlend(
              c.primary.withValues(alpha: AppAlpha.strong),
              t.brandDeep,
            ),
            t.canvasSunken,
            t.canvas,
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
              height: 56,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => Icon(
                Icons.school_rounded,
                size: 52,
                color: t.textOnBrand.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              course.code.isEmpty ? course.category : course.code,
              style: context.text.labelSmall!.copyWith(
                color: t.textOnBrand.withValues(alpha: 0.85),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrimIconButton extends StatelessWidget {
  const _ScrimIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: AppSpace.touchTarget,
            height: AppSpace.touchTarget,
            child: Icon(
              icon,
              size: AppIcon.sm,
              color: color ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Primary action + progress
// =============================================================================

class _ResumeAction extends StatelessWidget {
  const _ResumeAction({
    required this.course,
    required this.lecture,
    required this.isLoading,
    required this.hasError,
    required this.onPlay,
  });

  final Course course;
  final Lecture? lecture;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    if (lecture == null) {
      return AppButton(
        label: isLoading
            ? 'Synchronising curriculum'
            : hasError
                ? 'Retry curriculum sync'
                : 'Load curriculum',
        icon: isLoading ? Icons.sync_rounded : Icons.cloud_download_outlined,
        loading: isLoading,
        onPressed: onPlay,
      );
    }

    final started = course.overallProgress > 0;

    return AppButton(
      label: started
          ? 'Resume lecture ${lecture!.number}'
          : 'Start course · lecture 1',
      icon: Icons.play_arrow_rounded,
      color: context.tokens.green,
      onPressed: onPlay,
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final percent = (course.overallProgress * 100).round();

    return AppSurface(
      radius: AppRadius.lg,
      elevated: true,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('$percent%',
                  style: context.text.metric.copyWith(color: t.green)),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('of this curriculum complete',
                      style: context.text.bodySmall),
                ),
              ),
              Text(
                '${course.completedLecturesCount}/${course.lectures.length}',
                style: context.text.labelMedium!.copyWith(color: t.green),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AppProgressBar(value: course.overallProgress, color: t.green),
        ],
      ),
    );
  }
}

// =============================================================================
// Banners
// =============================================================================

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: c.primary.withValues(alpha: AppAlpha.wash),
          borderRadius: AppRadius.allMd,
          border: Border.all(color: c.primary.withValues(alpha: AppAlpha.soft)),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Syncing full curriculum',
                      style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Scanning verified open repository manifests for every '
                    'lecture and resource in this track.',
                    style: context.text.bodySmall,
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

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
      child: AppSurface.inset(
        color: t.warning.withValues(alpha: AppAlpha.wash),
        border: BorderSide(color: t.warning.withValues(alpha: AppAlpha.soft)),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.xs,
          AppSpace.sm,
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: AppIcon.sm, color: t.warning),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                'Preview lectures only — connect to the repository for the '
                'complete archive.',
                style: context.text.bodySmall,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: t.warning),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Lecture list
// =============================================================================

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(
                color: c.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LectureRow extends StatelessWidget {
  const _LectureRow({
    required this.lecture,
    required this.onTap,
    required this.onDownload,
  });

  final Lecture lecture;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final done = lecture.isCompleted || lecture.watchProgress >= 0.9;
    final started = lecture.watchProgress > 0 && !done;
    final progress = lecture.watchProgress;

    final statusColor = done
        ? t.success
        : started
            ? t.green
            : t.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: AppSurface(
        radius: AppRadius.md,
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        onTap: onTap,
        glow: started ? t.green : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.md, AppSpace.md, AppSpace.xs, AppSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LectureBadge(
                number: lecture.number,
                done: done,
                started: started,
                color: statusColor,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      lecture.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      lecture.summary,
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
                          label: lecture.duration,
                          icon: Icons.schedule_rounded,
                          color: t.textMuted,
                          dense: true,
                        ),
                        if (lecture.isDownloaded)
                          AppPill(
                            label: 'Offline',
                            icon: Icons.download_done_rounded,
                            color: t.info,
                            dense: true,
                          ),
                        if (started)
                          AppPill(
                            label: '${(progress * 100).round()}% watched',
                            icon: Icons.timelapse_rounded,
                            color: t.green,
                            dense: true,
                            selected: true,
                          )
                        else if (done)
                          AppPill(
                            label: 'Completed',
                            icon: Icons.check_circle_rounded,
                            color: t.success,
                            dense: true,
                            selected: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: <Widget>[
                  IconButton(
                    onPressed: onDownload,
                    tooltip: lecture.isDownloaded
                        ? 'Remove from offline'
                        : 'Save offline',
                    visualDensity: VisualDensity.compact,
                    iconSize: AppIcon.md,
                    icon: Icon(
                      lecture.isDownloaded
                          ? Icons.download_done_rounded
                          : Icons.download_outlined,
                      color: lecture.isDownloaded ? t.info : t.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Icon(Icons.play_circle_fill_rounded,
                      size: 22, color: statusColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LectureBadge extends StatelessWidget {
  const _LectureBadge({
    required this.number,
    required this.done,
    required this.started,
    required this.color,
  });

  final int number;
  final bool done;
  final bool started;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: done || started
            ? color.withValues(alpha: AppAlpha.soft)
            : t.surfaceRaised,
        borderRadius: AppRadius.allSm,
        border: Border.all(
          color: done || started
              ? color.withValues(alpha: AppAlpha.medium)
              : t.hairline,
        ),
      ),
      child: Center(
        child: done
            ? Icon(Icons.check_rounded, size: AppIcon.sm, color: color)
            : Text(
                '$number',
                style: context.text.labelMedium!.copyWith(
                  color: started ? color : t.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// =============================================================================
// Resource list
// =============================================================================

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.doc, required this.onSave});

  final CourseDocument doc;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = context.docColor(doc.type);

    return AppSurface(
      radius: AppRadius.md,
      padding: const EdgeInsets.fromLTRB(
          AppSpace.md, AppSpace.md, AppSpace.xs, AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconTile(
              icon: DocPalette.iconFor(doc.type), color: color, size: 44),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  doc.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                if (doc.description.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    doc.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: <Widget>[
                    AppPill(
                      label: DocPalette.labelFor(doc.type),
                      color: color,
                      dense: true,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        doc.sizeFormatted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.monoSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSave,
            tooltip: 'Save resource offline',
            visualDensity: VisualDensity.compact,
            iconSize: AppIcon.md,
            icon: Icon(Icons.download_for_offline_outlined, color: t.green),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Overview facts
// =============================================================================

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = iconColor ?? context.colors.primary;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
          child: Row(
            children: <Widget>[
              Icon(icon, size: AppIcon.sm, color: accent),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(label, style: context.text.bodyMedium)),
              const SizedBox(width: AppSpace.md),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      context.text.labelMedium!.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: t.hairline),
      ],
    );
  }
}
