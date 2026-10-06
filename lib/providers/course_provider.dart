import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import '../services/academic_torrents_service.dart';
import '../services/storage_service.dart';

class CourseProvider extends ChangeNotifier {
  final AcademicTorrentsService _service;
  final StorageService _storage;

  CourseProvider(this._service, this._storage);

  List<Course> _allCourses = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All Technologies';
  String? _selectedTechStack;
  String _selectedLevel = 'All';

  bool _isLoadingMore = false;
  bool _hasMoreCourses = true;
  int _currentPage = 1;
  Timer? _searchDebounce;
  bool _isSearchingRemote = false;

  List<Course> get allCourses => _allCourses;
  bool get isLoading => _isLoading;
  bool get isSearchingRemote => _isSearchingRemote;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreCourses => _hasMoreCourses;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get selectedTechStack => _selectedTechStack;
  String get selectedLevel => _selectedLevel;

  List<String> get categories => [
        'All Technologies',
        'Python & Backend',
        'Frontend & Mobile',
        'Backend & Microservices',
        'Cloud & DevOps',
        'AI & Machine Learning',
        'Cybersecurity',
        'System Design & Architecture',
        'Databases & Data Streaming',
      ];

  List<String> get popularTechStacks => [
        'Azure',
        'AWS',
        'GCP',
        'Terraform',
        'DevOps',
        'Docker',
        'Kubernetes',
        'Python',
        'FastAPI',
        'Django',
        'React',
        'React Native',
        'Vue',
        'Angular',
        'Node.js',
        'Java',
        'Spring Boot',
        'C++',
        'C# / .NET',
        'Go',
        'Rust',
        'Android / Kotlin',
        'iOS / Swift',
        'Flutter',
        'PHP & Laravel',
        'Linux',
        'PostgreSQL',
        'MongoDB',
        'Kafka',
        'System Design',
        'Data Structures',
        'Cybersecurity',
        'Ethical Hacking',
        'Git & GitHub',
        'Generative AI',
      ];

  static List<String> _expandSearchSynonyms(String rawQuery) {
    final q = rawQuery.toLowerCase().trim();
    if (q.isEmpty) return const [];
    final synonyms = <String>{q};

    // Precise technology shortcuts & official aliases (NO generic catch-alls)
    if (q == 'az' || q.contains('azure')) {
      synonyms.addAll(['azure', 'microsoft azure']);
    }
    if (q == 'k8s' || q == 'kube' || q.contains('kubern')) {
      synonyms.addAll(['kubernetes', 'k8s']);
    }
    if (q == 'gcp' || q.contains('google cloud')) {
      synonyms.addAll(['gcp', 'google cloud']);
    }
    if (q == 'aws' || q.contains('amazon web')) {
      synonyms.addAll(['aws', 'amazon web services']);
    }
    if (q == 'iac' || q.contains('terra')) {
      synonyms.addAll(['terraform', 'iac']);
    }
    if (q == 'cicd' || q == 'ci/cd' || q.contains('devops')) {
      synonyms.addAll(['devops', 'ci/cd']);
    }
    if (q == 'sec' || q.contains('cyber') || q.contains('security')) {
      synonyms.addAll(['cybersecurity', 'security', 'zero trust']);
    }
    if (q == 'ai' ||
        q == 'ml' ||
        q.contains('genai') ||
        q.contains('deep learning')) {
      synonyms.addAll(['ai', 'machine learning', 'generative ai', 'deep learning']);
    }
    if (q == 'dsa' || q.contains('algo')) {
      synonyms.addAll(['data structures', 'algorithms', 'dsa']);
    }
    if (q == 'postgres' || q == 'psql' || q.contains('postgre')) {
      synonyms.addAll(['postgresql', 'postgres']);
    }
    if (q == 'sql' || q == 'mysql') {
      synonyms.addAll(['sql', 'mysql', 'postgresql']);
    }
    if (q == 'js' || q == 'javascript') {
      synonyms.addAll(['javascript', 'js']);
    }
    if (q == 'ts' || q == 'typescript') {
      synonyms.addAll(['typescript', 'ts']);
    }
    if (q == 'cpp' || q == 'c++') {
      synonyms.addAll(['c++', 'cpp']);
    }
    if (q == 'c#' ||
        q == 'csharp' ||
        q == '.net' ||
        q == 'dotnet' ||
        q == 'asp.net') {
      synonyms.addAll(['c#', 'csharp', '.net', 'dotnet', 'c# / .net']);
    }
    if (q == 'java') {
      synonyms.addAll(['java', 'spring boot']);
    }
    if (q == 'spring' || q.contains('spring boot')) {
      synonyms.addAll(['spring boot', 'spring']);
    }
    if (q == 'kotlin' || q == 'android') {
      synonyms.addAll(['kotlin', 'android', 'android / kotlin']);
    }
    if (q == 'swift' || q == 'ios' || q == 'swiftui') {
      synonyms.addAll(['swift', 'ios', 'swiftui', 'ios / swift']);
    }
    if (q == 'php' || q == 'laravel') {
      synonyms.addAll(['php', 'laravel', 'php & laravel']);
    }
    if (q == 'mongo' || q == 'mongodb' || q == 'nosql') {
      synonyms.addAll(['mongodb', 'nosql', 'mongo']);
    }
    if (q == 'redis') {
      synonyms.addAll(['redis', 'caching']);
    }
    if (q == 'graphql' || q == 'apollo') {
      synonyms.addAll(['graphql']);
    }
    if (q == 'git' || q == 'github') {
      synonyms.addAll(['git', 'github', 'git & github']);
    }
    if (q == 'hacking' ||
        q == 'kali' ||
        q == 'pentest' ||
        q.contains('ethical hack')) {
      synonyms.addAll(['ethical hacking', 'kali linux', 'cybersecurity']);
    }
    if (q == 'golang' || q == 'go') {
      synonyms.addAll(['go', 'golang']);
    }
    if (q == 'py' || q == 'python') {
      synonyms.addAll(['python']);
    }
    if (q.contains('vue')) {
      synonyms.addAll(['vue', 'pinia']);
    }
    if (q.contains('react native') || q == 'rn') {
      synonyms.addAll(['react native', 'rn']);
    } else if (q == 'react') {
      synonyms.addAll(['react', 'next.js']);
    }

    return synonyms.toList();
  }

  static int _calculateRelevanceScore(
      Course c, List<String> searchTerms, String rawQuery) {
    int score = 0;
    final title = c.title.toLowerCase();
    final techStacks = c.techStacks.map((t) => t.toLowerCase()).toList();
    final desc = c.description.toLowerCase();

    // 1. Direct query matching (highest priority)
    if (title.startsWith(rawQuery)) {
      score += 150;
    } else if (title.contains(rawQuery)) {
      score += 90;
    }

    if (techStacks.any((t) => t == rawQuery)) {
      score += 120;
    } else if (techStacks.any((t) => t.contains(rawQuery) || rawQuery.contains(t))) {
      score += 70;
    }

    // 2. Synonym matching
    for (final term in searchTerms) {
      if (term == rawQuery) continue;
      if (title.contains(term)) score += 50;
      if (techStacks.any((t) => t.contains(term))) score += 40;
    }

    if (desc.contains(rawQuery)) score += 15;

    return score;
  }

  List<Course> get filteredCourses {
    final rawQ = _searchQuery.trim().toLowerCase();
    final searchTerms = _expandSearchSynonyms(rawQ);

    if (rawQ.isNotEmpty) {
      final matchingCourses = _allCourses.where((c) {
        final title = c.title.toLowerCase();
        final desc = c.description.toLowerCase();
        final code = c.code.toLowerCase();
        final uni = c.university.toLowerCase();
        final author = c.author.toLowerCase();
        final cat = c.category.toLowerCase();
        final techList = c.techStacks.map((t) => t.toLowerCase()).toList();

        final matchesAnyTerm = searchTerms.any((term) {
          return title.contains(term) ||
              desc.contains(term) ||
              code.contains(term) ||
              uni.contains(term) ||
              author.contains(term) ||
              cat.contains(term) ||
              techList.any((t) => t.contains(term) || term.contains(t));
        });

        if (!matchesAnyTerm) return false;

        if (_selectedLevel != 'All' && c.level != _selectedLevel) {
          return false;
        }

        return true;
      }).toList();

      // Sort matching courses so the most relevant technology tracks appear first
      matchingCourses.sort((a, b) {
        final scoreA = _calculateRelevanceScore(a, searchTerms, rawQ);
        final scoreB = _calculateRelevanceScore(b, searchTerms, rawQ);
        return scoreB.compareTo(scoreA);
      });

      return matchingCourses;
    }

    // Standard category, tech stack, and level filters when search bar is empty
    return _allCourses.where((c) {
      final matchesCategory = _selectedCategory == 'All Technologies' ||
          c.category == _selectedCategory;

      final matchesTechStack = _selectedTechStack == null ||
          _selectedTechStack!.isEmpty ||
          c.techStacks.any((t) {
            final tLower = t.toLowerCase();
            final sLower = _selectedTechStack!.toLowerCase();
            return tLower == sLower ||
                tLower.contains(sLower) ||
                sLower.contains(tLower);
          }) ||
          c.title.toLowerCase().contains(_selectedTechStack!.toLowerCase());

      final matchesLevel = _selectedLevel == 'All' || c.level == _selectedLevel;

      return matchesCategory && matchesTechStack && matchesLevel;
    }).toList();
  }

  List<Course> get bookmarkedCourses {
    return _allCourses.where((c) => c.isBookmarked).toList();
  }

  List<Course> get inProgressCourses {
    return _allCourses
        .where((c) => c.overallProgress > 0 && c.overallProgress < 0.99)
        .toList();
  }

  Course? get lastActiveCourse {
    if (inProgressCourses.isNotEmpty) {
      return inProgressCourses.first;
    }
    return _allCourses.isNotEmpty ? _allCourses.first : null;
  }

  Future<void> loadCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final courses = await _service.fetchCourses();
      final bookmarks = _storage.getBookmarkedCourseIds();

      // Hydrate with local progress & bookmarks
      _allCourses = courses.map((course) {
        final isBookmarked = bookmarks.contains(course.id);
        final hydratedLectures = course.lectures.map((l) {
          final progress = _storage.getLectureProgress(l.id);
          final isDownloaded =
              _storage.getDownloadedLectureIds().contains(l.id);
          return l.copyWith(
            watchProgress: progress,
            isCompleted: progress >= 0.9,
            isDownloaded: isDownloaded,
          );
        }).toList();

        return course.copyWith(
          isBookmarked: isBookmarked,
          lectures: hydratedLectures,
        );
      }).toList();
    } catch (_) {
      // Keep preloaded
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches and hydrates the complete, authentic Udemy-style course curriculum
  /// (all 20-100+ real lecture videos and documents) from the open repository manifest.
  Future<Course> loadFullCourseCurriculum(Course course) async {
    if (course.isCurriculumLoaded) return course;

    final updated = await _service.fetchFullCourseCurriculum(course);
    final bookmarks = _storage.getBookmarkedCourseIds();
    final isBookmarked = bookmarks.contains(updated.id);

    final hydratedLectures = updated.lectures.map((l) {
      final progress = _storage.getLectureProgress(l.id);
      final isDownloaded = _storage.getDownloadedLectureIds().contains(l.id);
      return l.copyWith(
        watchProgress: progress,
        isCompleted: progress >= 0.9,
        isDownloaded: isDownloaded,
      );
    }).toList();

    final finalCourse = updated.copyWith(
      isBookmarked: isBookmarked,
      lectures: hydratedLectures,
      isCurriculumLoaded: true,
    );

    final index = _allCourses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _allCourses[index] = finalCourse;
      notifyListeners();
    }
    return finalCourse;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _hasMoreCourses = true;
    notifyListeners();

    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length >= 2) {
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        _triggerRemoteSearch(trimmed);
      });
    }
  }

  Future<void> _triggerRemoteSearch(String query) async {
    if (_isSearchingRemote) return;
    _isSearchingRemote = true;
    notifyListeners();

    try {
      final remoteCourses =
          await _service.fetchMoreCourses(page: 1, query: query);
      if (remoteCourses.isNotEmpty) {
        final bookmarks = _storage.getBookmarkedCourseIds();
        bool addedAny = false;
        for (final c in remoteCourses) {
          if (!_allCourses.any((existing) => existing.id == c.id)) {
            final isBookmarked = bookmarks.contains(c.id);
            _allCourses.add(c.copyWith(isBookmarked: isBookmarked));
            addedAny = true;
          }
        }
        if (addedAny) {
          notifyListeners();
        }
      }
    } catch (_) {
      // Graceful fallback to local cache
    } finally {
      _isSearchingRemote = false;
      notifyListeners();
    }
  }

  /// Infinite scroll loader: fetches next batch from open archive Swarm & appends seamlessly
  Future<void> loadMoreCourses() async {
    if (_isLoadingMore || !_hasMoreCourses) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final newCourses = await _service.fetchMoreCourses(
        page: nextPage,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (newCourses.isEmpty) {
        // Attempt next page to bypass any batches of non-tech movies that were filtered out
        final nextNextPage = nextPage + 1;
        final retryCourses = await _service.fetchMoreCourses(
          page: nextNextPage,
          query: _searchQuery.isNotEmpty ? _searchQuery : null,
        );
        if (retryCourses.isEmpty) {
          _hasMoreCourses = false;
        } else {
          _currentPage = nextNextPage;
          final bookmarks = _storage.getBookmarkedCourseIds();
          for (final c in retryCourses) {
            final isBookmarked = bookmarks.contains(c.id);
            if (!_allCourses.any((existing) => existing.id == c.id)) {
              _allCourses.add(c.copyWith(isBookmarked: isBookmarked));
            }
          }
        }
      } else {
        final bookmarks = _storage.getBookmarkedCourseIds();
        final hydrated = newCourses.map((c) {
          final isBookmarked = bookmarks.contains(c.id);
          return c.copyWith(isBookmarked: isBookmarked);
        }).toList();

        for (final c in hydrated) {
          if (!_allCourses.any((existing) => existing.id == c.id)) {
            _allCourses.add(c);
          }
        }
        _currentPage = nextPage;
      }
    } catch (_) {
      // Graceful error recovery
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setTechStack(String? techStack) {
    if (_selectedTechStack == techStack) {
      _selectedTechStack = null; // Toggle off if clicked again
    } else {
      _selectedTechStack = techStack;
    }
    notifyListeners();
  }

  void setLevel(String level) {
    _selectedLevel = level;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All Technologies';
    _selectedTechStack = null;
    _selectedLevel = 'All';
    notifyListeners();
  }

  Future<void> toggleBookmark(String courseId) async {
    await _storage.toggleBookmark(courseId);
    final index = _allCourses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      final current = _allCourses[index];
      _allCourses[index] =
          current.copyWith(isBookmarked: !current.isBookmarked);
      notifyListeners();
    }
  }

  Future<void> updateLectureProgress(
      String courseId, String lectureId, double progress) async {
    await _storage.saveLectureProgress(lectureId, progress);

    final courseIndex = _allCourses.indexWhere((c) => c.id == courseId);
    if (courseIndex != -1) {
      final course = _allCourses[courseIndex];
      final lectureIndex = course.lectures.indexWhere((l) => l.id == lectureId);
      if (lectureIndex != -1) {
        final updatedLecture = course.lectures[lectureIndex].copyWith(
          watchProgress: progress,
          isCompleted: progress >= 0.9,
        );
        final newLectures = List<Lecture>.from(course.lectures);
        newLectures[lectureIndex] = updatedLecture;

        _allCourses[courseIndex] = course.copyWith(
          lectures: newLectures,
          lastWatchedLectureId: lectureId,
        );
        notifyListeners();
      }
    }
  }

  Future<void> toggleLectureDownloaded(String lectureId) async {
    await _storage.toggleDownloaded(lectureId);
    final isDownloaded = _storage.getDownloadedLectureIds().contains(lectureId);

    for (int i = 0; i < _allCourses.length; i++) {
      final course = _allCourses[i];
      final lIndex = course.lectures.indexWhere((l) => l.id == lectureId);
      if (lIndex != -1) {
        final updated =
            course.lectures[lIndex].copyWith(isDownloaded: isDownloaded);
        final newLectures = List<Lecture>.from(course.lectures);
        newLectures[lIndex] = updated;
        _allCourses[i] = course.copyWith(lectures: newLectures);
        notifyListeners();
        break;
      }
    }
  }

  Course? getCourseById(String id) {
    try {
      return _allCourses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
