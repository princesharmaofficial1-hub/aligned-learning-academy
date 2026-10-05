import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import 'course_detail_screen.dart';
import 'video_player_screen.dart';
import '../widgets/aligned_logo_view.dart';
import '../widgets/sources_credits_dialog.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      final provider = context.read<CourseProvider>();
      if (!provider.isLoadingMore && provider.hasMoreCourses) {
        provider.loadMoreCourses();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const AlignedLogoView(
          height: 32,
          fit: BoxFit.contain,
        ),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => SourcesCreditsDialog.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Credits & Sources',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, _) {
          final courses = provider.filteredCourses;
          final lastCourse = provider.lastActiveCourse;

          return RefreshIndicator(
            color: AppTheme.primaryGlow,
            backgroundColor: AppTheme.surface,
            onRefresh: () => provider.loadCourses(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // SEARCH BAR WITH INSTANT CLEAR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      onChanged: provider.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search Python, FastAPI, React, Docker, Rust, Go...',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGlow, size: 20),
                        suffixIcon: provider.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: AppTheme.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.primaryGlow, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),

                // QUICK RESUME HERO BANNER (if user has active course and no active search)
                if (provider.searchQuery.isEmpty &&
                    provider.selectedTechStack == null &&
                    lastCourse != null &&
                    lastCourse.lectures.isNotEmpty &&
                    lastCourse.overallProgress > 0)
                  SliverToBoxAdapter(
                    child: _buildQuickResumeCard(context, lastCourse),
                  ),

                // POPULAR TECH STACKS PILLS MATRIX
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Featured Tech Stacks',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (provider.selectedTechStack != null ||
                            provider.selectedCategory != 'All Technologies' ||
                            provider.searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              provider.resetFilters();
                            },
                            child: const Text(
                              'Reset All',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Tech stack chips carousel
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.popularTechStacks.length,
                      itemBuilder: (context, index) {
                        final tech = provider.popularTechStacks[index];
                        final isSelected = provider.selectedTechStack == tech;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tech),
                            selected: isSelected,
                            onSelected: (_) => provider.setTechStack(tech),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                            selectedColor: AppTheme.primary,
                            backgroundColor: AppTheme.surface,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryGlow : AppTheme.cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // DOMAIN CATEGORY TABS
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: provider.categories.length,
                      itemBuilder: (context, index) {
                        final cat = provider.categories[index];
                        final isSelected = cat == provider.selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => provider.setCategory(cat),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                            selectedColor: AppTheme.surfaceElevated,
                            backgroundColor: AppTheme.surface,
                            side: BorderSide(
                              color: isSelected ? AppTheme.secondary : AppTheme.cardBorder,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ACTIVE SEARCH / FILTER STATUS ROW
                if (provider.selectedTechStack != null || provider.searchQuery.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Row(
                        children: [
                          if (provider.searchQuery.isNotEmpty) ...[
                            Text(
                              'Search: "${provider.searchQuery}"',
                              style: const TextStyle(
                                  color: AppTheme.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (provider.selectedTechStack != null)
                            Chip(
                              label: Text(provider.selectedTechStack!),
                              onDeleted: () => provider.setTechStack(null),
                              deleteIconColor: Colors.white,
                              backgroundColor: AppTheme.primary.withAlpha(70),
                              side: const BorderSide(color: AppTheme.primary),
                              labelStyle: const TextStyle(
                                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),

                // SECTION HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${courses.length} Available Curricula',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          provider.selectedCategory,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),

                // COURSE LIST
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGlow),
                    ),
                  )
                else if (courses.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 54, color: AppTheme.textMuted.withAlpha(120)),
                          const SizedBox(height: 12),
                          const Text(
                            'No tech courses match your search.',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try searching for Python, React, Docker, or reset filters.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              provider.resetFilters();
                            },
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = courses[index];
                          return _buildProMaxCourseCard(context, course, provider);
                        },
                        childCount: courses.length,
                      ),
                    ),
                  ),

                // INFINITE SCROLL LOADING INDICATOR AT BOTTOM
                if (provider.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Loading additional verified courses...',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (!provider.hasMoreCourses && courses.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          '— You have reached the end of the catalog —',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickResumeCard(BuildContext context, Course course) {
    if (course.lectures.isEmpty) return const SizedBox.shrink();
    final activeLecture = course.lectures.firstWhere(
      (l) => l.watchProgress > 0 && l.watchProgress < 0.99,
      orElse: () => course.lectures.first,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(90),
            AppTheme.secondary.withAlpha(40),
            AppTheme.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryGlow.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(60),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.play_circle_fill, size: 16, color: AppTheme.secondary),
                  SizedBox(width: 6),
                  Text(
                    'CONTINUE LEARNING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Text(
                '${(course.overallProgress * 100).toInt()}% Done',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            activeLecture.title,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: course.overallProgress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Resume Lecture', style: TextStyle(fontSize: 12)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
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
    );
  }

  Widget _buildProMaxCourseCard(
      BuildContext context, Course course, CourseProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen(course: course),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 16:9 Banner Thumbnail with Gradient & Overlays
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail Image or Fallback
                      if (course.thumbnailUrl.isNotEmpty)
                        Image.network(
                          course.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackThumbnail(course),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppTheme.surfaceElevated,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryGlow,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        _buildFallbackThumbnail(course),

                      // Subtle Vignette Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(120),
                              Colors.transparent,
                              Colors.black.withAlpha(140),
                            ],
                          ),
                        ),
                      ),

                      // Overlaid Top Meta (Category, Badge & Bookmark)
                      Positioned(
                        top: 10,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withAlpha(220),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    course.category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(160),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.accent.withAlpha(140), width: 0.8),
                                  ),
                                  child: Text(
                                    course.badge,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(140),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 18,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  course.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                  color: course.isBookmarked ? AppTheme.accent : Colors.white70,
                                ),
                                onPressed: () => provider.toggleBookmark(course.id),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Overlaid Bottom Meta (Lectures & Docs count + Seeders)
                      Positioned(
                        bottom: 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withAlpha(70),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: AppTheme.primaryGlow.withAlpha(100), width: 0.6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.video_library, size: 11, color: AppTheme.primaryGlow),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course.lectures.length} Videos',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withAlpha(60),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: AppTheme.secondary.withAlpha(120), width: 0.6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description_outlined, size: 11, color: AppTheme.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${course.documents.length} Docs',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Verified Track',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondary,
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
              ),

              // Card Body Details
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Code
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.university} • ${course.author}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),

                    // Tech Stacks Pills Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: course.techStacks.take(4).map((tech) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: AppTheme.cardBorder, width: 0.8),
                          ),
                          child: Text(
                            '#$tech',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGlow,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Divider
                    const Divider(color: AppTheme.cardBorder, height: 1),
                    const SizedBox(height: 10),

                    // Bottom Metrics Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${course.rating}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.people_outline, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${course.enrolledCount}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              course.estimatedHours,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Text(
                            course.level,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
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
      ),
    );
  }

  Widget _buildFallbackThumbnail(Course course) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withAlpha(140),
            AppTheme.surfaceElevated,
            AppTheme.secondary.withAlpha(90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/aligned_icon.png',
              height: 40,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.play_circle_fill,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              course.code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
