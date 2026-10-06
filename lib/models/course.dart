import 'course_document.dart';
import 'lecture.dart';

class Course {
  final String id;
  final String title;
  final String code;
  final String university;
  final String category;
  final String description;
  final String infoHash;
  final String sizeFormatted;
  final String webSeedUrl;
  final int seeders;
  final List<Lecture> lectures;
  final List<CourseDocument> documents;
  final String thumbnailUrl;
  final bool isBookmarked;
  final String? lastWatchedLectureId;
  final List<String> techStacks;
  final String level; // Beginner, Intermediate, Advanced
  final double rating;
  final int enrolledCount;
  final String estimatedHours;
  final String? archiveIdentifier;
  final String author;
  final String badge; // Bestseller, Trending, Enterprise, Foundational
  final bool isCurriculumLoaded;

  const Course({
    required this.id,
    required this.title,
    required this.code,
    required this.university,
    required this.category,
    required this.description,
    required this.infoHash,
    required this.sizeFormatted,
    required this.webSeedUrl,
    this.archiveIdentifier,
    this.seeders = 18,
    required this.lectures,
    this.documents = const [],
    this.thumbnailUrl = '',
    this.isBookmarked = false,
    this.lastWatchedLectureId,
    this.techStacks = const ['Software Engineering'],
    this.level = 'Intermediate',
    this.rating = 4.8,
    this.enrolledCount = 12500,
    this.estimatedHours = '10 hrs',
    this.author = 'Academic Faculty',
    this.badge = 'Trending',
    this.isCurriculumLoaded = false,
  });

  String get effectiveArchiveIdentifier {
    if (archiveIdentifier != null && archiveIdentifier!.isNotEmpty) {
      return archiveIdentifier!;
    }
    if (!id.startsWith('tech_') && !id.contains(' ')) {
      return id;
    }
    if (webSeedUrl.contains('archive.org/details/')) {
      return webSeedUrl
          .split('archive.org/details/')
          .last
          .split('/')
          .first
          .split('?')
          .first;
    }
    return '';
  }

  String get magnetUri =>
      'magnet:?xt=urn:btih:$infoHash&dn=${Uri.encodeComponent(title)}&tr=https%3A%2F%2Facademictorrents.com%2Fannounce.php&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce';

  double get overallProgress {
    if (lectures.isEmpty) return 0.0;
    final total =
        lectures.fold<double>(0.0, (sum, item) => sum + item.watchProgress);
    return total / lectures.length;
  }

  int get completedLecturesCount =>
      lectures.where((l) => l.isCompleted || l.watchProgress >= 0.9).length;

  Course copyWith({
    bool? isBookmarked,
    String? lastWatchedLectureId,
    List<Lecture>? lectures,
    List<CourseDocument>? documents,
    String? thumbnailUrl,
    int? seeders,
    List<String>? techStacks,
    String? level,
    double? rating,
    int? enrolledCount,
    String? estimatedHours,
    String? author,
    String? badge,
    bool? isCurriculumLoaded,
    String? sizeFormatted,
    String? archiveIdentifier,
  }) {
    return Course(
      id: id,
      title: title,
      code: code,
      university: university,
      category: category,
      description: description,
      infoHash: infoHash,
      sizeFormatted: sizeFormatted ?? this.sizeFormatted,
      webSeedUrl: webSeedUrl,
      archiveIdentifier: archiveIdentifier ?? this.archiveIdentifier,
      seeders: seeders ?? this.seeders,
      lectures: lectures ?? this.lectures,
      documents: documents ?? this.documents,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      lastWatchedLectureId: lastWatchedLectureId ?? this.lastWatchedLectureId,
      techStacks: techStacks ?? this.techStacks,
      level: level ?? this.level,
      rating: rating ?? this.rating,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      author: author ?? this.author,
      badge: badge ?? this.badge,
      isCurriculumLoaded: isCurriculumLoaded ?? this.isCurriculumLoaded,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'code': code,
        'university': university,
        'category': category,
        'description': description,
        'infoHash': infoHash,
        'sizeFormatted': sizeFormatted,
        'webSeedUrl': webSeedUrl,
        'archiveIdentifier': archiveIdentifier,
        'seeders': seeders,
        'lectures': lectures.map((l) => l.toJson()).toList(),
        'documents': documents.map((d) => d.toJson()).toList(),
        'thumbnailUrl': thumbnailUrl,
        'isBookmarked': isBookmarked,
        'lastWatchedLectureId': lastWatchedLectureId,
        'techStacks': techStacks,
        'level': level,
        'rating': rating,
        'enrolledCount': enrolledCount,
        'estimatedHours': estimatedHours,
        'author': author,
        'badge': badge,
        'isCurriculumLoaded': isCurriculumLoaded,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        title: json['title'] as String,
        code: json['code'] as String? ?? '',
        university: json['university'] as String? ?? 'Open University',
        category: json['category'] as String? ?? 'Computer Science',
        description: json['description'] as String? ?? '',
        infoHash: json['infoHash'] as String,
        sizeFormatted: json['sizeFormatted'] as String? ?? 'Unknown',
        webSeedUrl: json['webSeedUrl'] as String? ?? '',
        archiveIdentifier: json['archiveIdentifier'] as String?,
        seeders: json['seeders'] as int? ?? 12,
        lectures: (json['lectures'] as List<dynamic>?)
                ?.map((e) => Lecture.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        documents: (json['documents'] as List<dynamic>?)
                ?.map((e) => CourseDocument.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        isBookmarked: json['isBookmarked'] as bool? ?? false,
        lastWatchedLectureId: json['lastWatchedLectureId'] as String?,
        techStacks: (json['techStacks'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['Software Engineering'],
        level: json['level'] as String? ?? 'Intermediate',
        rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
        enrolledCount: json['enrolledCount'] as int? ?? 12500,
        estimatedHours: json['estimatedHours'] as String? ?? '10 hrs',
        author: json['author'] as String? ?? 'Academic Faculty',
        badge: json['badge'] as String? ?? 'Trending',
        isCurriculumLoaded: json['isCurriculumLoaded'] as bool? ?? false,
      );
}
