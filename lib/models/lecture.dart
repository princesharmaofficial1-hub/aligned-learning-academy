class Lecture {
  final String id;
  final String courseId;
  final int number;
  final String title;
  final String section;
  final String videoUrl;
  final String duration;
  final String? localFilePath;
  final bool isDownloaded;
  final double watchProgress; // 0.0 to 1.0
  final bool isCompleted;
  final String summary;

  const Lecture({
    required this.id,
    required this.courseId,
    required this.number,
    required this.title,
    this.section = 'General Curriculum',
    required this.videoUrl,
    required this.duration,
    this.localFilePath,
    this.isDownloaded = false,
    this.watchProgress = 0.0,
    this.isCompleted = false,
    this.summary = 'Comprehensive technical deep-dive and production walkthrough.',
  });

  Lecture copyWith({
    String? title,
    String? section,
    String? videoUrl,
    String? duration,
    String? localFilePath,
    bool? isDownloaded,
    double? watchProgress,
    bool? isCompleted,
    String? summary,
  }) {
    return Lecture(
      id: id,
      courseId: courseId,
      number: number,
      title: title ?? this.title,
      section: section ?? this.section,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      localFilePath: localFilePath ?? this.localFilePath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      watchProgress: watchProgress ?? this.watchProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'number': number,
    'title': title,
    'section': section,
    'videoUrl': videoUrl,
    'duration': duration,
    'localFilePath': localFilePath,
    'isDownloaded': isDownloaded,
    'watchProgress': watchProgress,
    'isCompleted': isCompleted,
    'summary': summary,
  };

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    number: json['number'] as int? ?? 1,
    title: json['title'] as String,
    section: json['section'] as String? ?? 'General Curriculum',
    videoUrl: json['videoUrl'] as String,
    duration: json['duration'] as String? ?? '45:00',
    localFilePath: json['localFilePath'] as String?,
    isDownloaded: json['isDownloaded'] as bool? ?? false,
    watchProgress: (json['watchProgress'] as num?)?.toDouble() ?? 0.0,
    isCompleted: json['isCompleted'] as bool? ?? false,
    summary: json['summary'] as String? ?? 'Comprehensive technical deep-dive and production walkthrough.',
  );
}

class LectureNote {
  final String id;
  final String courseId;
  final String lectureId;
  final String lectureTitle;
  final int timestampSeconds;
  final String content;
  final DateTime createdAt;

  LectureNote({
    required this.id,
    required this.courseId,
    required this.lectureId,
    required this.lectureTitle,
    required this.timestampSeconds,
    required this.content,
    required this.createdAt,
  });

  String get formattedTimestamp {
    final m = timestampSeconds ~/ 60;
    final s = timestampSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'lectureId': lectureId,
    'lectureTitle': lectureTitle,
    'timestampSeconds': timestampSeconds,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LectureNote.fromJson(Map<String, dynamic> json) => LectureNote(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    lectureId: json['lectureId'] as String,
    lectureTitle: json['lectureTitle'] as String,
    timestampSeconds: json['timestampSeconds'] as int,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
