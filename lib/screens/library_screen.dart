import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/lecture.dart';
import '../providers/course_provider.dart';
import '../theme/app_typography.dart';
import '../theme/design_tokens.dart';
import '../theme/tech_palette.dart';
import '../widgets/app_components.dart';
import 'course_detail_screen.dart';
import 'video_player_screen.dart';

/// "My Learning": active tracks, saved curricula and the offline cache.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _index = 0;

  static List<_OfflineEntry> _downloadedLectures(CourseProvider provider) {
    final entries = <_OfflineEntry>[];
    for (final course in provider.allCourses) {
      for (final lecture in course.lectures) {
        if (lecture.isDownloaded) entries.add(_OfflineEntry(course, lecture));
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final inProgress = provider.inProgressCourses;
        final bookmarked = provider.bookmarkedCourses;
        final downloaded = _downloadedLectures(provider);

        return Scaffold(
          backgroundColor: context.tokens.canvas,
          appBar: _LibraryAppBar(
            index: _index,
            onChanged: (value) => setState(() => _index = value),
          ),
          body: Column(
            children: <Widget>[
              _MetricsBar(provider: provider),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: <Widget>[
                    _TrackList(
                      courses: inProgress,
                      emptyIcon: Icons.play_circle_outline_rounded,
                      emptyTitle: 'No active tracks',
                      emptyMessage:
                          'Open a verified technology track from the catalogue '
                          'and start watching — your progress will appear here.',
                      builder: (course) => _InProgressCard(course: course),
                    ),
                    _TrackList(
                      courses: bookmarked,
                      emptyIcon: Icons.bookmark_border_rounded,
                      emptyTitle: 'Nothing saved yet',
                      emptyMessage:
                          'Tap the bookmark icon on any course to build your '
                          'own technical curriculum.',
                      builder: (course) => _SavedCard(
                        course: course,
                        onRemove: () => provider.toggleBookmark(course.id),
                      ),
                    ),
                    _OfflineList(entries: downloaded, provider: provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineEntry {
  const _OfflineEntry(this.course, this.lecture);
  final Course course;
  final Lecture lecture;
}

// =============================================================================
// App bar + segmented tabs
// =============================================================================

class _LibraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LibraryAppBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(124);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return AppBar(
      backgroundColor: t.canvas,
      toolbarHeight: 64,
      titleSpacing: AppSpace.gutter,
      title: Row(
        children: <Widget>[
          AppIconTile(
            icon: Icons.workspace_premium_rounded,
            color: c.primary,
            size: 38,
            iconSize: AppIcon.sm,
            selected: true,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'MY LEARNING',
                  style: context.text.labelSmall!.copyWith(
                    color: c.primary,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'My Learning',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.sm,
                AppSpace.gutter,
                AppSpace.md,
              ),
              child: AppSegmentControl(
                labels: const <String>['Active', 'Saved', 'Offline'],
                icons: const <IconData>[
                  Icons.play_circle_outline_rounded,
                  Icons.bookmark_outline_rounded,
                  Icons.download_done_rounded,
                ],
                selectedIndex: index,
                onChanged: onChanged,
              ),
            ),
            Container(height: 1, color: t.hairline),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// KPI bar
// =============================================================================

class _MetricsBar extends StatelessWidget {
  const _MetricsBar({required this.provider});

  final CourseProvider provider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    final completed = provider.allCourses.fold<int>(
      0,
      (sum, course) => sum + course.completedLecturesCount,
    );

    final lectures = provider.allCourses.fold<int>(
      0,
      (sum, course) => sum + course.lectures.length,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.sm,
      ),
      child: AppSurface(
        radius: AppRadius.lg,
        glow: c.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.lg,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _MetricTile(
                label: 'Active tracks',
                value: '${provider.inProgressCourses.length}',
                icon: Icons.bolt_rounded,
                color: c.primary,
              ),
            ),
            _Divider(color: t.hairline),
            Expanded(
              child: _MetricTile(
                label: 'Lessons done',
                value: '$completed',
                icon: Icons.verified_rounded,
                color: t.green,
              ),
            ),
            _Divider(color: t.hairline),
            Expanded(
              child: _MetricTile(
                label: 'Total lectures',
                value: '$lectures',
                icon: Icons.library_books_rounded,
                color: t.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: color);
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppIconTile(
          icon: icon,
          color: color,
          size: 34,
          iconSize: AppIcon.sm,
          radius: AppRadius.xs,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(value, style: context.text.metric),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall!.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

// =============================================================================
// Tab bodies
// =============================================================================

class _TrackList extends StatelessWidget {
  const _TrackList({
    required this.courses,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.builder,
  });

  final List<Course> courses;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final Widget Function(Course course) builder;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: <Widget>[
          AppEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
          ),
          const SizedBox(height: AppSpace.dockClearance),
        ],
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        AppSpace.dockClearance,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) => builder(courses[index]),
    );
  }
}

class _OfflineList extends StatelessWidget {
  const _OfflineList({required this.entries, required this.provider});

  final List<_OfflineEntry> entries;
  final CourseProvider provider;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: <Widget>[
          AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'No offline lectures',
            message:
                'Download lectures to study without a connection — handy for '
                'flights and commutes.',
          ),
          const SizedBox(height: AppSpace.dockClearance),
        ],
      );
    }

    final t = context.tokens;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.md,
        AppSpace.gutter,
        AppSpace.dockClearance,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return AppSurface(
          radius: AppRadius.md,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => VideoPlayerScreen(
                course: entry.course,
                initialLecture: entry.lecture,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              AppIconTile(
                icon: Icons.play_circle_fill_rounded,
                color: t.green,
                size: 44,
                selected: true,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      entry.lecture.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${entry.course.title} · ${entry.lecture.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  provider.toggleLectureDownloaded(entry.lecture.id);
                  showAppSnack(
                    context,
                    'Removed from offline downloads',
                    icon: Icons.delete_outline_rounded,
                  );
                },
                tooltip: 'Remove download',
                iconSize: AppIcon.md,
                icon: Icon(Icons.delete_outline_rounded, color: t.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Cards
// =============================================================================

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    if (course.lectures.isEmpty) {
      return AppSurface(
        radius: AppRadius.md,
        margin: const EdgeInsets.only(bottom: AppSpace.lg),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CourseDetailScreen(course: course),
          ),
        ),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(course.title, style: context.text.titleMedium),
                  const SizedBox(height: AppSpace.xs),
                  Text(course.university, style: context.text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            AppButton(
              label: 'Open',
              expand: false,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CourseDetailScreen(course: course),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final active = course.lectures.firstWhere(
      (l) => l.watchProgress > 0 && l.watchProgress < 0.99,
      orElse: () => course.lectures.first,
    );

    final levelColor = context.levelColor(course.level);

    return AppSurface(
      radius: AppRadius.lg,
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CourseDetailScreen(course: course),
        ),
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppPill(
                label: course.category.toUpperCase(),
                icon: Icons.school_rounded,
                color: c.primary,
                dense: true,
              ),
              AppPill(
                label: '${(course.overallProgress * 100).round()}%',
                icon: Icons.donut_large_rounded,
                color: t.green,
                dense: true,
                selected: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: <Widget>[
              Icon(
                Icons.play_circle_fill_rounded,
                size: AppIcon.sm,
                color: c.primary,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'Lecture ${active.number}: ${active.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          AppProgressBar(value: course.overallProgress, color: t.green),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${course.completedLecturesCount} of ${course.lectures.length} lessons finished',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              AppPill(
                label: course.level,
                color: levelColor,
                dense: true,
              ),
              AppButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                expand: false,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => VideoPlayerScreen(
                      course: course,
                      initialLecture: active,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.course, required this.onRemove});

  final Course course;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = context.techColor(course.category);

    return AppSurface(
      radius: AppRadius.md,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CourseDetailScreen(course: course),
        ),
      ),
      padding: const EdgeInsets.all(AppSpace.md),
      child: Row(
        children: <Widget>[
          AppIconTile(
            icon: TechPalette.iconFor(course.category),
            color: color,
            size: 48,
            iconSize: AppIcon.lg,
            selected: true,
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
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.verified_rounded,
                      size: AppIcon.xs,
                      color: t.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        course.university,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  course.lectures.isNotEmpty
                      ? '${course.lectures.length} lectures'
                      : 'Full syllabus',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove from saved',
            iconSize: AppIcon.md,
            icon: Icon(Icons.bookmark_rounded, color: t.accent),
          ),
        ],
      ),
    );
  }
}
