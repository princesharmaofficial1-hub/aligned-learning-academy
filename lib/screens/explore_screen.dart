import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../providers/course_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/tech_palette.dart';
import '../widgets/aligned_logo_view.dart';
import '../widgets/app_components.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';
import 'video_player_screen.dart';
import '../widgets/sources_credits_dialog.dart';

/// Catalogue entry point: search, stack/category filters, and the course grid.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 320) {
      final provider = context.read<CourseProvider>();
      if (!provider.isLoadingMore && provider.hasMoreCourses) {
        provider.loadMoreCourses();
      }
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters(CourseProvider provider) {
    _searchController.clear();
    provider.resetFilters();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.canvas,
      appBar: _ExploreAppBar(
        liveTrackCount: context.watch<CourseProvider>().allCourses.length,
      ),
      body: Consumer<CourseProvider>(
        builder: (context, provider, _) {
          final courses = provider.filteredCourses;
          final hasActiveFilters = provider.selectedTechStack != null ||
              provider.selectedCategory != provider.categories.first ||
              provider.searchQuery.isNotEmpty;

          return RefreshIndicator(
            color: context.colors.primary,
            backgroundColor: context.tokens.surfaceRaised,
            displacement: 40,
            onRefresh: () => provider.loadCourses(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.gutter,
                      AppSpace.sm,
                      AppSpace.gutter,
                      AppSpace.lg,
                    ),
                    child: _SearchField(
                      controller: _searchController,
                      hasQuery: provider.searchQuery.isNotEmpty,
                      isLoading: provider.isSearchingRemote,
                      onChanged: provider.setSearchQuery,
                      onClear: () => _resetFilters(provider),
                    ),
                  ),
                ),

                // ---- Featured hero: resume, or the academy banner -------------
                SliverToBoxAdapter(
                  child: _HeroSlot(
                    isFiltered: provider.searchQuery.isNotEmpty ||
                        provider.selectedTechStack != null,
                    resumeCourse: provider.lastActiveCourse,
                    onResetFilters: () => _resetFilters(provider),
                  ),
                ),

                // ---- Featured tech stacks ------------------------------------
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Featured Tech Stacks',
                    subtitle: 'Filter the catalogue by discipline',
                    actionLabel: hasActiveFilters ? 'Reset' : null,
                    onAction:
                        hasActiveFilters ? () => _resetFilters(provider) : null,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.gutter,
                      AppSpace.xl,
                      AppSpace.gutter,
                      AppSpace.md,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.gutter,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.popularTechStacks.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpace.sm),
                      itemBuilder: (context, index) {
                        final tech = provider.popularTechStacks[index];
                        final selected = provider.selectedTechStack == tech;
                        final color = TechPalette.colorFor(tech);

                        return _TechChip(
                          tech: tech,
                          color: color,
                          selected: selected,
                          onTap: () {
                            provider.setTechStack(
                              selected ? null : tech,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // ---- Category tabs -------------------------------------------
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.gutter,
                        AppSpace.lg,
                        AppSpace.gutter,
                        0,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: provider.categories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpace.sm),
                      itemBuilder: (context, index) {
                        final cat = provider.categories[index];
                        return _CategoryChip(
                          label: cat,
                          selected: cat == provider.selectedCategory,
                          onTap: () => provider.setCategory(cat),
                        );
                      },
                    ),
                  ),
                ),

                // ---- Active filter summary -----------------------------------
                if (hasActiveFilters)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.gutter,
                        AppSpace.md,
                        AppSpace.gutter,
                        0,
                      ),
                      child: _ActiveFilterBar(
                        query: provider.searchQuery,
                        tech: provider.selectedTechStack,
                        category: provider.selectedCategory,
                        baseCategory: provider.categories.first,
                        onClearSearch: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                        onClearTech: () => provider.setTechStack(null),
                      ),
                    ),
                  ),

                // ---- Results header ------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.gutter,
                      AppSpace.xl,
                      AppSpace.gutter,
                      AppSpace.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            provider.isLoading
                                ? 'Loading catalogue…'
                                : '${courses.length} '
                                    '${courses.length == 1 ? 'curriculum' : 'curricula'}',
                            style: context.text.headlineSmall,
                          ),
                        ),
                        if (!provider.isLoading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: AppPill(
                              label: provider.searchQuery.trim().isNotEmpty
                                  ? 'Search Results'
                                  : provider.selectedCategory,
                              color: context.tokens.textMuted,
                              dense: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ---- Body ------------------------------------------------------
                if (provider.isLoading)
                  const SliverToBoxAdapter(child: _LoadingGrid())
                else if (courses.isEmpty)
                  SliverToBoxAdapter(
                    child: AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No courses match',
                      message:
                          'Try a different technology — Python, React, Docker, Rust or Go — or clear your filters.',
                      actionLabel: 'Reset all filters',
                      onAction: () => _resetFilters(provider),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.gutter,
                      0,
                      AppSpace.gutter,
                      AppSpace.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => CourseCard(
                          course: courses[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CourseDetailScreen(course: courses[index]),
                            ),
                          ),
                          onBookmark: () =>
                              provider.toggleBookmark(courses[index].id),
                        ),
                        childCount: courses.length,
                      ),
                    ),
                  ),

                // ---- Pagination footer ---------------------------------------
                SliverToBoxAdapter(
                  child: _ListFooter(
                    isLoadingMore: provider.isLoadingMore,
                    hasMore: provider.hasMoreCourses,
                    isEmpty: courses.isEmpty,
                  ),
                ),

                // Clear the floating dock.
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpace.dockClearance),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// App bar
// =============================================================================

class _ExploreAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ExploreAppBar({required this.liveTrackCount});

  final int liveTrackCount;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return AppBar(
      backgroundColor: t.canvas,
      toolbarHeight: 60,
      titleSpacing: AppSpace.gutter,
      title: const AlignedLogoView(height: 28, fit: BoxFit.contain),
      actions: <Widget>[
        Center(
          child: AppPill(
            label: '$liveTrackCount TRACKS',
            icon: Icons.circle,
            color: t.green,
            dense: true,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        AppIconButton(
          icon: Icons.verified_user_rounded,
          tooltip: 'Credits & verified sources',
          onTap: () => SourcesCreditsDialog.show(context),
          color: context.colors.primary,
          size: 42,
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
// Search
// =============================================================================

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Search courses by technology',
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: context.text.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search Azure, AWS, GCP, DevOps, Python, React…',
          prefixIcon: Icon(
            Icons.search_rounded,
            size: AppIcon.md,
            color: context.colors.primary,
          ),
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpace.md),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: AppIcon.sm),
                      tooltip: 'Clear search',
                      onPressed: onClear,
                    )
                  : null),
        ),
      ),
    );
  }
}

// =============================================================================
// Hero
// =============================================================================

class _HeroSlot extends StatelessWidget {
  const _HeroSlot({
    required this.isFiltered,
    required this.resumeCourse,
    required this.onResetFilters,
  });

  final bool isFiltered;
  final Course? resumeCourse;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    if (isFiltered) return const SizedBox.shrink();

    final course = resumeCourse;
    if (course != null &&
        course.lectures.isNotEmpty &&
        course.overallProgress > 0) {
      return _ResumeCard(course: course);
    }

    return const _AcademyBanner();
  }
}

class _AcademyBanner extends StatelessWidget {
  const _AcademyBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: AppSurface(
        radius: AppRadius.xl,
        glow: c.primary,
        border: BorderSide(color: c.primary.withValues(alpha: 0.30)),
        gradient: LinearGradient(
          colors: <Color>[
            Color.alphaBlend(c.primary.withValues(alpha: 0.16), t.surface),
            t.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppPill(
                  label: 'ALIGNED ENTERPRISE ACADEMY',
                  icon: Icons.circle,
                  color: t.green,
                  dense: true,
                ),
                const Spacer(),
                Icon(Icons.auto_awesome_rounded,
                    color: t.accent, size: AppIcon.sm),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'Production-grade engineering upskilling',
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Continuous technical mastery across cloud, distributed '
              'microservices, AI and systems programming — from MIT and other '
              'leading open institutions.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpace.lg),
            const Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: <Widget>[
                _StatChip(label: '18 tracks', icon: Icons.layers_rounded),
                _StatChip(
                    label: '1,200+ HD lectures',
                    icon: Icons.ondemand_video_rounded),
                _StatChip(label: '100% free OER', icon: Icons.verified_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: AppIcon.xs, color: t.textMuted),
        const SizedBox(width: AppSpace.xs),
        Text(label, style: context.text.labelMedium),
      ],
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = context.colors;

    final lecture = course.lectures.firstWhere(
      (l) => l.watchProgress > 0 && l.watchProgress < 0.99,
      orElse: () => course.lectures.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: AppSurface(
        radius: AppRadius.xl,
        selected: true,
        glow: c.primary,
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppPill(
                  label: 'CONTINUE LEARNING',
                  icon: Icons.play_circle_fill_rounded,
                  color: t.green,
                  dense: true,
                ),
                const Spacer(),
                Text(
                  '${(course.overallProgress * 100).round()}% done',
                  style: context.text.labelMedium!.copyWith(color: t.green),
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
            const SizedBox(height: AppSpace.xs),
            Text(
              lecture.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall,
            ),
            const SizedBox(height: AppSpace.lg),
            AppProgressBar(value: course.overallProgress, color: t.green),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: 'Resume lecture',
              icon: Icons.play_arrow_rounded,
              expand: false,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => VideoPlayerScreen(
                    course: course,
                    initialLecture: lecture,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Filter chips
// =============================================================================

class _TechChip extends StatelessWidget {
  const _TechChip({
    required this.tech,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String tech;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter by $tech',
      child: Material(
        color: selected
            ? color.withValues(alpha: AppAlpha.strong)
            : t.surfaceRaised,
        borderRadius: AppRadius.allPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.allPill,
              border: Border.all(
                color: selected ? color : t.hairline,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  TechPalette.iconFor(tech),
                  size: AppIcon.sm,
                  color: selected ? color : t.textMuted,
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  tech,
                  style: context.text.labelMedium!.copyWith(
                    color: selected ? t.textPrimary : t.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.primary : Colors.transparent,
        borderRadius: AppRadius.allPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm + 2,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.allPill,
              border: Border.all(
                color: selected ? c.primary : t.hairline,
              ),
            ),
            child: Text(
              label,
              style: context.text.labelMedium!.copyWith(
                color: selected ? t.textOnBrand : t.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.query,
    required this.tech,
    required this.category,
    required this.baseCategory,
    required this.onClearSearch,
    required this.onClearTech,
  });

  final String query;
  final String? tech;
  final String category;
  final String baseCategory;
  final VoidCallback onClearSearch;
  final VoidCallback onClearTech;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: AppAlpha.wash),
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: context.colors.primary.withValues(alpha: AppAlpha.soft),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.filter_alt_rounded,
              size: AppIcon.sm, color: context.colors.primary),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (query.isNotEmpty)
                  AppPill(
                    label: '“$query”',
                    icon: Icons.search_rounded,
                    color: context.colors.primary,
                    dense: true,
                    selected: true,
                    onTap: onClearSearch,
                  ),
                if (tech != null)
                  AppPill(
                    label: tech!,
                    icon: TechPalette.iconFor(tech!),
                    color: TechPalette.colorFor(tech!),
                    dense: true,
                    selected: true,
                    onTap: onClearTech,
                  ),
                if (category != baseCategory)
                  Text(
                    category,
                    style:
                        context.text.labelSmall!.copyWith(color: t.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// States
// =============================================================================

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < 3; i++)
            AppSurface(
              radius: AppRadius.lg,
              margin: const EdgeInsets.only(bottom: AppSpace.lg),
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const AppSkeletonBox(height: 120, radius: AppRadius.md),
                  const SizedBox(height: AppSpace.lg),
                  const AppSkeletonBox(height: 18, width: 220),
                  const SizedBox(height: AppSpace.md),
                  const AppSkeletonBox(height: 12, width: 150),
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    children: <Widget>[
                      AppSkeletonBox(
                          height: 22, width: 64, radius: AppRadius.pill),
                      const SizedBox(width: AppSpace.sm),
                      AppSkeletonBox(
                          height: 22, width: 88, radius: AppRadius.pill),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.isEmpty,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox(height: AppSpace.xl);

    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpace.md),
              Text(
                'Loading more verified courses…',
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
        child: Center(
          child: Text(
            'You have reached the end of the catalogue',
            style: context.text.bodySmall,
          ),
        ),
      );
    }

    return const SizedBox(height: AppSpace.lg);
  }
}
