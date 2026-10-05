import 'package:flutter/material.dart';
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/aligned_icon.png',
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 24, color: AppTheme.secondary),
              ),
              const SizedBox(width: 10),
              const Text(
                'My Learning Workspace',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.secondary,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'In Progress'),
              Tab(text: 'Bookmarked'),
              Tab(text: 'Offline Cache'),
            ],
          ),
        ),
        body: Consumer<CourseProvider>(
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

            return Column(
              children: [
                // Top Metrics Overview Bar
                _buildMetricsBar(provider),

                Expanded(
                  child: TabBarView(
                    children: [
                      // IN PROGRESS
                      inProgress.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.play_circle_outline,
                              title: 'No active courses in progress',
                              subtitle:
                                  'Explore technology tracks and start watching any lecture to track progress here.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: inProgress.length,
                              itemBuilder: (context, index) {
                                return _buildInProgressCard(context, inProgress[index]);
                              },
                            ),

                      // BOOKMARKED
                      bookmarked.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.bookmark_border,
                              title: 'No bookmarked tech tracks',
                              subtitle:
                                  'Tap the bookmark icon on any curriculum to save it to your personal library.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: bookmarked.length,
                              itemBuilder: (context, index) {
                                final course = bookmarked[index];
                                return _buildBookmarkedCard(context, course, provider);
                              },
                            ),

                      // OFFLINE CACHE
                      downloadedLectures.isEmpty
                          ? _buildEmptyState(
                              icon: Icons.download_done,
                              title: 'No offline lectures cached',
                              subtitle:
                                  'Tap the download icon next to any lecture to save it locally for offline learning.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: downloadedLectures.length,
                              itemBuilder: (context, index) {
                                final course = downloadedLectures[index]['course'] as Course;
                                final lecture = downloadedLectures[index]['lecture'] as Lecture;
                                return _buildOfflineCard(context, course, lecture, provider);
                              },
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricsBar(CourseProvider provider) {
    int totalCompleted = 0;
    for (final c in provider.allCourses) {
      totalCompleted += c.completedLecturesCount;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'In Progress',
            '${provider.inProgressCourses.length}',
            Icons.timelapse,
            AppTheme.secondary,
          ),
          Container(width: 1, height: 28, color: AppTheme.cardBorder),
          _buildMetricItem(
            'Completed',
            '$totalCompleted',
            Icons.check_circle_outline,
            AppTheme.success,
          ),
          Container(width: 1, height: 28, color: AppTheme.cardBorder),
          _buildMetricItem(
            'Saved',
            '${provider.bookmarkedCourses.length}',
            Icons.bookmark_outline,
            AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInProgressCard(BuildContext context, Course course) {
    final activeLecture = course.lectures.firstWhere(
      (l) => l.watchProgress > 0 && l.watchProgress < 0.99,
      orElse: () => course.lectures.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(course.overallProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Next: ${activeLecture.title}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: course.overallProgress,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${course.completedLecturesCount} of ${course.lectures.length} finished',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Continue', style: TextStyle(fontSize: 12)),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedCard(
      BuildContext context, Course course, CourseProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${course.university} • ${course.lectures.length} lessons • ${course.level}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: AppTheme.accent),
          onPressed: () => provider.toggleBookmark(course.id),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(course: course),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineCard(BuildContext context, Course course, Lecture lecture,
      CourseProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.surfaceElevated,
          child: Icon(Icons.play_arrow, color: AppTheme.secondary),
        ),
        title: Text(
          lecture.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        subtitle: Text(
          '${course.title} • ${lecture.duration}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
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

  Widget _buildEmptyState({
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
            Icon(icon, size: 56, color: AppTheme.textMuted.withAlpha(120)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
