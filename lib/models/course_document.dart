class CourseDocument {
  final String id;
  final String title;
  final String type; // 'pdf', 'slides', 'code', 'cheatsheet', 'doc'
  final String fileUrl;
  final String sizeFormatted;
  final String description;

  const CourseDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.fileUrl,
    required this.sizeFormatted,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'fileUrl': fileUrl,
        'sizeFormatted': sizeFormatted,
        'description': description,
      };

  factory CourseDocument.fromJson(Map<String, dynamic> json) => CourseDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String? ?? 'pdf',
        fileUrl: json['fileUrl'] as String? ?? '',
        sizeFormatted: json['sizeFormatted'] as String? ?? '1.2 MB',
        description: json['description'] as String? ?? '',
      );
}
