import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../models/lecture.dart';
import '../providers/course_provider.dart';
import '../providers/notes_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_components.dart';
import 'course_detail_screen.dart';
import 'video_player_screen.dart';

/// "Knowledge Vault": every timestamped note across the catalogue, newest first,
/// each one able to jump straight back into the lecture it belongs to.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotesProvider, CourseProvider>(
      builder: (context, notes, courses, _) {
        final all = notes.notes;

        return Scaffold(
          backgroundColor: context.tokens.canvas,
          appBar: _NotesAppBar(count: all.length),
          body: all.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: const <Widget>[
                    AppEmptyState(
                      icon: Icons.edit_note_rounded,
                      title: 'No notes yet',
                      message:
                          'While watching a lecture, open the Notes tab under '
                          'the player to capture timestamped formulas, code '
                          'snippets and takeaways.',
                    ),
                    SizedBox(height: AppSpace.dockClearance),
                  ],
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.sm,
                    AppSpace.gutter,
                    AppSpace.dockClearance,
                  ),
                  itemCount: all.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpace.md),
                  itemBuilder: (context, index) => _NoteCard(
                    note: all[index],
                    courses: courses,
                    notes: notes,
                  ),
                ),
        );
      },
    );
  }
}

// =============================================================================
// App bar
// =============================================================================

class _NotesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _NotesAppBar({required this.count});

  final int count;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return AppBar(
      backgroundColor: t.canvas,
      toolbarHeight: 60,
      titleSpacing: AppSpace.gutter,
      title: Row(
        children: <Widget>[
          AppIconTile(
            icon: Icons.edit_note_rounded,
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
                  'KNOWLEDGE VAULT',
                  style: context.text.labelSmall!.copyWith(
                    color: c.primary,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Engineering Notes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        if (count > 0)
          Center(
            child: AppPill(
              label: '$count ${count == 1 ? 'NOTE' : 'NOTES'}',
              icon: Icons.sticky_note_2_outlined,
              color: t.green,
              dense: true,
            ),
          ),
        const SizedBox(width: AppSpace.gutter),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: t.hairline),
      ),
    );
  }
}

// =============================================================================
// Note card
// =============================================================================

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.courses,
    required this.notes,
  });

  final LectureNote note;
  final CourseProvider courses;
  final NotesProvider notes;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: note.content));
    if (!context.mounted) return;
    showAppSnack(context, 'Note copied to clipboard', icon: Icons.copy_rounded);
  }

  void _openLecture(BuildContext context) {
    Course? course;
    for (final c in courses.allCourses) {
      if (c.id == note.courseId) {
        course = c;
        break;
      }
    }

    if (course == null) {
      showAppSnack(
        context,
        'This course is no longer in the catalogue',
        icon: Icons.link_off_rounded,
        isError: true,
      );
      return;
    }

    Lecture? lecture;
    for (final l in course.lectures) {
      if (l.id == note.lectureId) {
        lecture = l;
        break;
      }
    }

    if (lecture != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              VideoPlayerScreen(course: course!, initialLecture: lecture!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CourseDetailScreen(course: course),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return AppSurface(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ---- Meta row -------------------------------------------------
          Row(
            children: <Widget>[
              AppPill(
                label: note.formattedTimestamp,
                icon: Icons.access_time_filled_rounded,
                color: t.green,
                dense: true,
                selected: true,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  note.lectureTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium,
                ),
              ),
              AppIconButton(
                icon: Icons.copy_rounded,
                tooltip: 'Copy note',
                size: 36,
                iconSize: AppIcon.sm,
                color: t.textMuted,
                background: t.surfaceRaised,
                onTap: () => _copy(context),
              ),
              const SizedBox(width: AppSpace.xs),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete note',
                size: 36,
                iconSize: AppIcon.sm,
                color: t.danger,
                background: t.surfaceRaised,
                onTap: () {
                  notes.deleteNote(note.id);
                  showAppSnack(
                    context,
                    'Note deleted',
                    icon: Icons.delete_outline_rounded,
                    isError: true,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpace.md),

          // ---- Body ------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: t.surfaceRaised.withValues(alpha: AppAlpha.soft),
              borderRadius: AppRadius.allSm,
              border: Border.all(color: t.hairline),
            ),
            child: Text(note.content, style: context.text.bodyLarge),
          ),

          const SizedBox(height: AppSpace.md),

          // ---- Action ----------------------------------------------------
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Jump to lecture',
              icon: Icons.play_circle_fill_rounded,
              expand: false,
              variant: AppButtonVariant.outlined,
              color: c.primary,
              onPressed: () {
                try {
                  _openLecture(context);
                } catch (_) {
                  showAppSnack(
                    context,
                    'This lecture is no longer in the catalogue',
                    icon: Icons.link_off_rounded,
                    isError: true,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
