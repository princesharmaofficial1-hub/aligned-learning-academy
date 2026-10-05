import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import 'video_player_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotesProvider, CourseProvider>(
      builder: (context, notesProv, courseProv, _) {
        final notes = notesProv.notes;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background.withAlpha(240),
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KNOWLEDGE VAULT',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryGlow,
                      ),
                    ),
                    Text(
                      'Engineering Notes',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (notes.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code_rounded, size: 14, color: AppTheme.secondary),
                      const SizedBox(width: 5),
                      Text(
                        '${notes.length} Notes',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: notes.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteCard(context, note, notesProv, courseProv);
                  },
                ),
        );
      },
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    dynamic note,
    NotesProvider notesProv,
    CourseProvider courseProv,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.luxuryCardDecoration(radius: 18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Timestamp pill, Lecture Title, Delete & Copy
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.secondary.withAlpha(120), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded,
                          size: 11, color: AppTheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        note.formattedTimestamp,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.lectureTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.textMuted),
                  tooltip: 'Copy Note',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: note.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Note copied to clipboard!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted),
                  tooltip: 'Delete Note',
                  onPressed: () => notesProv.deleteNote(note.id),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withAlpha(140),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder.withAlpha(80)),
              ),
              child: Text(
                note.content,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Jump Action Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceElevated,
                  foregroundColor: AppTheme.primaryGlow,
                  side: BorderSide(color: AppTheme.primaryGlow.withAlpha(90), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                label: const Text(
                  'Jump to Lecture',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  try {
                    final course = courseProv.allCourses
                        .firstWhere((c) => c.id == note.courseId);
                    final lecture = course.lectures
                        .firstWhere((l) => l.id == note.lectureId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          course: course,
                          initialLecture: lecture,
                        ),
                      ),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Lecture not found in current catalog')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(30),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 36,
                color: AppTheme.primaryGlow,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Engineering Notes Yet',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'While watching any lecture, open the Notes tab beneath the video player to capture timestamped architectural formulas, code snippets, and key takeaways.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
