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

  List<Course> get allCourses => _allCourses;
  bool get isLoading => _isLoading;
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
        'FastAPI',
        'React',
        'Docker',
        'Node.js',
        'Kubernetes',
        'Go',
        'Rust',
        'AWS',
        'Kafka',
        'Flutter',
        'Angular',
        'Python',
        'PostgreSQL',
        'Generative AI',
        'Cybersecurity',
      ];

  List<Course> get filteredCourses {
    return _allCourses.where((c) {
      final matchesCategory =
          _selectedCategory == 'All Technologies' || c.category == _selectedCategory;

      final matchesTechStack = _selectedTechStack == null ||
          _selectedTechStack!.isEmpty ||
          c.techStacks.any((t) => t.toLowerCase() == _selectedTechStack!.toLowerCase());

      final matchesLevel = _selectedLevel == 'All' || c.level == _selectedLevel;

      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.university.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.author.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.techStacks.any((t) => t.toLowerCase().contains(q));

      return matchesCategory && matchesTechStack && matchesLevel && matchesSearch;
    }).toList();
  }

  List<Course> get bookmarkedCourses {
    return _allCourses.where((c) => c.isBookmarked).toList();
  }

  List<Course> get inProgressCourses {
    return _allCourses.where((c) => c.overallProgress > 0 && c.overallProgress < 0.99).toList();
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
          final isDownloaded = _storage.getDownloadedLectureIds().contains(l.id);
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
      _allCourses[index] = current.copyWith(isBookmarked: !current.isBookmarked);
      notifyListeners();
    }
  }

  Future<void> updateLectureProgress(String courseId, String lectureId, double progress) async {
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
        final updated = course.lectures[lIndex].copyWith(isDownloaded: isDownloaded);
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
}
