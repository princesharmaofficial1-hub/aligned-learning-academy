import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import 'course_detail_screen.dart';
import 'video_player_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final inProgress = provider.inProgressCourses;
        final bookmarked = provider.bookmarkedCourses;
        final downloadedLectures = <Map<String, dynamic>>[];

        for (final c in provider.allCourses) {
          for (final l in c.lectures) {
            if (l.isDownloaded) {
              downloadedLectures.add({'course': c, 'lecture': l});
            }
          }
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
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
                      Icons.workspace_premium_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MY LEARNING WORKSPACE',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryGlow,
                        ),
                      ),
                      Text(
                        'Executive Learning Hub',
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder, width: 1),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(90),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_outline_rounded, size: 15),
                            const SizedBox(width: 6),
                            Text('Active (${inProgress.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bookmark_outline_rounded, size: 15),
                            const SizedBox(width: 6),
                            Text('Saved (${bookmarked.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.download_done_rounded, size: 15),
                            const SizedBox(width: 6),
                            Text('Offline (${downloadedLectures.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                // Top Executive KPI Metrics Row
                _buildMetricsBar(provider, inProgress.length, bookmarked.length),

                Expanded(
                  child: TabBarView(
                    children: [
                      // IN PROGRESS TAB
                      inProgress.isEmpty
                          ? _buildEmptyState(
                              context,
                              icon: Icons.play_circle_outline_rounded,
                              title: 'No Active Tracks in Progress',
                              subtitle:
                                  'Explore verified technology tracks in the catalog and begin watching lectures to track real-time mastery here.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                              itemCount: inProgress.length,
                              itemBuilder: (context, index) {
                                return _buildInProgressCard(context, inProgress[index]);
                              },
                            ),

                      // BOOKMARKED TAB
                      bookmarked.isEmpty
                          ? _buildEmptyState(
                              context,
                              icon: Icons.bookmark_border_rounded,
                              title: 'No Saved Curriculum Tracks',
                              subtitle:
                                  'Tap the bookmark icon on any course in the Explore catalog to build your custom technical curriculum.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                              itemCount: bookmarked.length,
                              itemBuilder: (context, index) {
                                return _buildBookmarkedCard(
                                    context, bookmarked[index], provider);
                              },
                            ),

                      // OFFLINE CACHE TAB
                      downloadedLectures.isEmpty
                          ? _buildEmptyState(
                              context,
                              icon: Icons.cloud_done_outlined,
                              title: 'No Offline Lectures Stored',
                              subtitle:
                                  'Download lectures and lab companions locally for uninterrupted study during executive travel or offline environments.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                              itemCount: downloadedLectures.length,
                              itemBuilder: (context, index) {
                                final course = downloadedLectures[index]['course'] as Course;
                                final lecture = downloadedLectures[index]['lecture'] as Lecture;
                                return _buildOfflineCard(
                                    context, course, lecture, provider);
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricsBar(CourseProvider provider, int activeCount, int savedCount) {
    int totalCompleted = 0;
    for (final c in provider.allCourses) {
      totalCompleted += c.completedLecturesCount;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppTheme.luxuryCardDecoration(
        radius: 18,
        hasGlow: true,
        glowColor: AppTheme.primary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricKPI(
            'ACTIVE TRACKS',
            '$activeCount',
            Icons.bolt_rounded,
            AppTheme.primaryGlow,
            const Color(0xFF0284C7).withAlpha(40),
          ),
          Container(
            width: 1,
            height: 38,
            color: AppTheme.cardBorder.withAlpha(150),
          ),
          _buildMetricKPI(
            'LESSONS DONE',
            '$totalCompleted',
            Icons.verified_rounded,
            AppTheme.secondary,
            AppTheme.secondary.withAlpha(35),
          ),
          Container(
            width: 1,
            height: 38,
            color: AppTheme.cardBorder.withAlpha(150),
          ),
          _buildMetricKPI(
            'BOOKMARKED',
            '$savedCount',
            Icons.bookmark_rounded,
            AppTheme.accent,
            AppTheme.accent.withAlpha(35),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricKPI(
      String label, String value, IconData icon, Color iconColor, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: iconColor.withAlpha(80), width: 1),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInProgressCard(BuildContext context, Course course) {
    if (course.lectures.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.luxuryCardDecoration(radius: 18),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            course.title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            course.university,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
              );
            },
            child: const Text('Open Track'),
          ),
        ),
      );
    }

    final activeLecture = course.lectures.firstWhere(
      (l) => l.watchProgress > 0 && l.watchProgress < 0.99,
      orElse: () => course.lectures.first,
    );

    final emoji = AppTheme.getTechEmoji(course.category);
    final techColor = AppTheme.getTechColor(course.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.luxuryCardDecoration(
        radius: 18,
        hasGlow: true,
        glowColor: techColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category & Progress Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: techColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: techColor.withAlpha(100), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        course.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: techColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.secondary.withAlpha(90), width: 0.8),
                  ),
                  child: Text(
                    '${(course.overallProgress * 100).toInt()}% COMPLETED',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Course Title
            Text(
              course.title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.25,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Active Lecture Title
            Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    size: 14, color: AppTheme.primaryGlow),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Lecture ${activeLecture.number}: ${activeLecture.title}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: course.overallProgress,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),

            // Bottom Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course.completedLecturesCount} of ${course.lectures.length} lessons finished',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(90),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text(
                      'Resume',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            course: course,
                            initialLecture: activeLecture,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedCard(
      BuildContext context, Course course, CourseProvider provider) {
    final emoji = AppTheme.getTechEmoji(course.category);
    final techColor = AppTheme.getTechColor(course.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.luxuryCardDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tech Stack Icon Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: techColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: techColor.withAlpha(80), width: 1),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            course.university,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 12, color: AppTheme.primaryGlow),
                          const SizedBox(width: 6),
                          Text(
                            '• ${course.lectures.isNotEmpty ? '${course.lectures.length} lessons' : 'Full Syllabus'}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Bookmark Button
                IconButton(
                  icon: const Icon(Icons.bookmark_rounded, color: AppTheme.accent, size: 22),
                  onPressed: () => provider.toggleBookmark(course.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineCard(BuildContext context, Course course, Lecture lecture,
      CourseProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.luxuryCardDecoration(radius: 18),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.secondary.withAlpha(80), width: 1),
          ),
          child: const Icon(Icons.play_circle_fill_rounded,
              color: AppTheme.secondary, size: 22),
        ),
        title: Text(
          lecture.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Text(
                course.title,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              Text(
                '• ${lecture.duration}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              size: 20, color: AppTheme.textMuted),
          onPressed: () => provider.toggleLectureDownloaded(lecture.id),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                course: course,
                initialLecture: lecture,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              child: Icon(icon, size: 36, color: AppTheme.primaryGlow),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
