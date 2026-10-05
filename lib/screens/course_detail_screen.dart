import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/course_document.dart';
import '../models/lecture.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import 'video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course? course;
  final String? courseId;

  const CourseDetailScreen({
    super.key,
    this.course,
    this.courseId,
  }) : assert(course != null || courseId != null, 'Provide either course or courseId');

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _selectedTabIndex = 0; // 0 = Lectures, 1 = Documents, 2 = Overview
  bool _isLoadingCurriculum = false;
  String? _curriculumError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurriculum();
    });
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
      if (mounted) {
        setState(() {
          _curriculumError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurriculum = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, _) {
        final targetId = widget.course?.id ?? widget.courseId!;
        final resolvedCourse = provider.getCourseById(targetId) ?? widget.course;
        if (resolvedCourse == null) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGlow),
            ),
          );
        }

        final firstUnfinishedLecture = resolvedCourse.lectures.isEmpty
            ? null
            : resolvedCourse.lectures.firstWhere(
                (l) => !l.isCompleted && l.watchProgress < 0.9,
                orElse: () => resolvedCourse.lectures.first,
              );

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            slivers: [
              // Modern Hero Sliver App Bar with Course Thumbnail
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppTheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Backdrop Course Thumbnail Image or Gradient
                      if (resolvedCourse.thumbnailUrl.isNotEmpty)
                        Image.network(
                          resolvedCourse.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildHeroFallback(),
                        )
                      else
                        _buildHeroFallback(),

                      // Dark Vignette Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withAlpha(120),
                              AppTheme.surface.withAlpha(180),
                              AppTheme.background,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // Info Overlays
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 75, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    resolvedCourse.category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: Text(
                                    resolvedCourse.level,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.accent.withAlpha(100), width: 0.8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_outlined, size: 13, color: AppTheme.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Enterprise Verified',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              resolvedCourse.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${resolvedCourse.university} • ${resolvedCourse.author}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      resolvedCourse.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: resolvedCourse.isBookmarked ? AppTheme.accent : Colors.white,
                    ),
                    onPressed: () => provider.toggleBookmark(resolvedCourse.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: resolvedCourse.magnetUri));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('BitTorrent magnet link copied to clipboard!'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Content Body Header & Play Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resume or Start Watching Hero Button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(90),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(
                            firstUnfinishedLecture != null
                                ? Icons.play_circle_fill
                                : (_isLoadingCurriculum ? Icons.sync : Icons.refresh),
                            size: 22,
                          ),
                          label: Text(
                            firstUnfinishedLecture != null
                                ? (resolvedCourse.overallProgress > 0
                                    ? 'Resume Lecture ${firstUnfinishedLecture.number}'
                                    : 'Start Course (Lecture 1)')
                                : (_isLoadingCurriculum
                                    ? 'Synchronizing Curriculum...'
                                    : (_curriculumError != null
                                        ? 'Retry Loading Curriculum'
                                        : 'Load Curriculum')),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onPressed: () {
                            if (firstUnfinishedLecture != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                    course: resolvedCourse,
                                    initialLecture: firstUnfinishedLecture,
                                  ),
                                ),
                              );
                            } else {
                              _loadCurriculum();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Course progress indicator if started
                      if (resolvedCourse.overallProgress > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Course Progress: ${(resolvedCourse.overallProgress * 100).toInt()}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary),
                            ),
                            Text(
                              resolvedCourse.lectures.isNotEmpty ? '${resolvedCourse.completedLecturesCount} of ${resolvedCourse.lectures.length} completed' : 'Comprehensive Curriculum',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: resolvedCourse.overallProgress,
                            backgroundColor: AppTheme.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // SEGMENTED TABS: Videos (XX) | Documents & Slides (XX) | Overview
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSegmentButton(
                                label: resolvedCourse.lectures.isEmpty
                                    ? (_isLoadingCurriculum ? 'Videos (...)' : 'Videos (0)')
                                    : 'Videos (${resolvedCourse.lectures.length})',
                                icon: Icons.video_library_outlined,
                                isSelected: _selectedTabIndex == 0,
                                onTap: () => setState(() => _selectedTabIndex = 0),
                              ),
                            ),
                            Expanded(
                              child: _buildSegmentButton(
                                label: 'Docs & Slides (${resolvedCourse.documents.length})',
                                icon: Icons.description_outlined,
                                isSelected: _selectedTabIndex == 1,
                                onTap: () => setState(() => _selectedTabIndex = 1),
                              ),
                            ),
                            Expanded(
                              child: _buildSegmentButton(
                                label: 'Overview',
                                icon: Icons.info_outline,
                                isSelected: _selectedTabIndex == 2,
                                onTap: () => setState(() => _selectedTabIndex = 2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // LIVE CURRICULUM SYNC BANNER
              if (_isLoadingCurriculum)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryGlow.withAlpha(120), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Synchronizing Complete Curriculum...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Fetching all 50-300+ videos & materials from open repository manifests.',
                                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_curriculumError != null && !resolvedCourse.isCurriculumLoaded)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppTheme.secondary),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Showing authentic preview lectures. Connect online to load full archive.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadCurriculum,
                          child: const Text('Retry', style: TextStyle(color: AppTheme.secondary, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),

              // TAB CONTENT SLIVER
              if (_selectedTabIndex == 0)
                // TAB 0: ALL VIDEO LECTURES
                if (_isLoadingCurriculum && resolvedCourse.lectures.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
                      child: Center(
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.8,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Fetching Authentic Curriculum...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Scanning verified open repository manifests for all lecture videos & resources.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (resolvedCourse.lectures.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              _curriculumError != null ? Icons.wifi_off_rounded : Icons.video_library_outlined,
                              size: 46,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _curriculumError != null
                                  ? 'Curriculum Sync Interrupted'
                                  : 'Curriculum Not Yet Loaded',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _curriculumError ?? 'Tap below to download the complete lecture curriculum.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Load Full Curriculum'),
                              onPressed: _loadCurriculum,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final lecture = resolvedCourse.lectures[index];
                          final isFirstInSection = index == 0 ||
                              resolvedCourse.lectures[index - 1].section !=
                                  lecture.section;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isFirstInSection) ...[
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: index == 0 ? 0 : 16,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          lecture.section.isNotEmpty
                                              ? lecture.section
                                              : 'Module ${(index ~/ 10) + 1}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              _buildLectureItem(
                                  context, resolvedCourse, lecture, provider),
                            ],
                          );
                        },
                        childCount: resolvedCourse.lectures.length,
                      ),
                    ),
                  )
              else if (_selectedTabIndex == 1)
                // TAB 1: DOCUMENTS, SLIDES & CODE REPOSITORIES
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: resolvedCourse.documents.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: const [
                                  Icon(Icons.folder_open, size: 48, color: AppTheme.textMuted),
                                  SizedBox(height: 8),
                                  Text(
                                    'No companion documents attached yet.',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = resolvedCourse.documents[index];
                              return _buildDocumentItem(context, doc);
                            },
                            childCount: resolvedCourse.documents.length,
                          ),
                        ),
                )
              else
                // TAB 2: OVERVIEW & STACKS
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tech Stacks Covered
                        const Text(
                          'Technologies & Stacks',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: resolvedCourse.techStacks.map((tech) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Text(
                                '#$tech',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Curriculum Description
                        const Text(
                          'Course Curriculum Overview',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          resolvedCourse.description,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                        ),
                        const SizedBox(height: 18),

                        // Metadata Info Box (Size, Peers, WebSeed, Delivery)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            children: [
                              _buildInfoTile('Total Curriculum Size', resolvedCourse.sizeFormatted, Icons.storage_outlined),
                              const Divider(color: AppTheme.cardBorder, height: 16),
                              _buildInfoTile('Video Lectures in Syllabus', resolvedCourse.lectures.isNotEmpty ? '${resolvedCourse.lectures.length} lessons' : 'Full Curriculum', Icons.video_library_outlined),
                              const Divider(color: AppTheme.cardBorder, height: 16),
                              _buildInfoTile('Learning Resources & Docs', '${resolvedCourse.documents.length} materials', Icons.file_present_outlined),
                              const Divider(color: AppTheme.cardBorder, height: 16),
                              _buildInfoTile('Student Rating', '★ ${resolvedCourse.rating} (${resolvedCourse.enrolledCount} engineers)', Icons.star_border),
                              const Divider(color: AppTheme.cardBorder, height: 16),
                              _buildInfoTile('Streaming Protocol', 'Enterprise High-Speed CDN', Icons.speed_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(90),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, CourseDocument doc) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (doc.type) {
      case 'slides':
      case 'pdf':
        icon = Icons.picture_as_pdf;
        iconColor = const Color(0xFFF43F5E);
        bgColor = const Color(0xFFF43F5E).withAlpha(40);
        break;
      case 'code':
        icon = Icons.code_rounded;
        iconColor = AppTheme.primaryGlow;
        bgColor = AppTheme.primary.withAlpha(40);
        break;
      case 'cheatsheet':
        icon = Icons.bolt;
        iconColor = AppTheme.accent;
        bgColor = AppTheme.accent.withAlpha(40);
        break;
      default:
        icon = Icons.article_outlined;
        iconColor = AppTheme.secondary;
        bgColor = AppTheme.secondary.withAlpha(40);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Type Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Title, Description & Size
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc.description,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          doc.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        doc.sizeFormatted,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Open / Download Action Button
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined, color: AppTheme.secondary),
              tooltip: 'Save Document Offline',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.secondary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Cached "${doc.title}" for offline study!'),
                        ),
                      ],
                    ),
                    backgroundColor: AppTheme.surfaceElevated,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0072CE),
            Color(0xFF0D1322),
            Color(0xFF080C14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/aligned_icon.png',
          height: 60,
          errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 60, color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.secondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLectureItem(
    BuildContext context,
    Course course,
    Lecture lecture,
    CourseProvider provider,
  ) {
    final isCompleted = lecture.isCompleted || lecture.watchProgress >= 0.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Index badge or checkmark
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.success.withAlpha(40)
                        : AppTheme.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: AppTheme.success, size: 18)
                        : Text(
                            '${lecture.number}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title, summary, and progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lecture.summary,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            lecture.duration,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          if (lecture.watchProgress > 0) ...[
                            const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
                            Text(
                              isCompleted
                                  ? '✓ Watched'
                                  : '${(lecture.watchProgress * 100).toInt()}% watched',
                              style: TextStyle(
                                fontSize: 11,
                                color: isCompleted ? AppTheme.success : AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Download toggle button
                IconButton(
                  icon: Icon(
                    lecture.isDownloaded ? Icons.download_done : Icons.download_outlined,
                    size: 20,
                    color: lecture.isDownloaded ? AppTheme.secondary : AppTheme.textMuted,
                  ),
                  tooltip: lecture.isDownloaded ? 'Downloaded' : 'Save Offline',
                  onPressed: () {
                    provider.toggleLectureDownloaded(lecture.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lecture.isDownloaded
                              ? 'Removed from downloads'
                              : 'Lecture saved for offline viewing!',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // Play icon
                const Icon(Icons.play_circle_outline, color: AppTheme.primaryGlow, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
