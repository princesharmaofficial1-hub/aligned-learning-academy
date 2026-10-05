import 'package:flutter/foundation.dart';
import '../models/lecture.dart';
import '../services/storage_service.dart';

class NotesProvider extends ChangeNotifier {
  final StorageService _storage;

  NotesProvider(this._storage) {
    loadNotes();
  }

  List<LectureNote> _notes = [];
  List<LectureNote> get notes => _notes;

  void loadNotes() {
    _notes = _storage.getNotes();
    notifyListeners();
  }

  List<LectureNote> getNotesForLecture(String lectureId) {
    return _notes.where((n) => n.lectureId == lectureId).toList();
  }

  Future<void> addNote({
    required String courseId,
    required String lectureId,
    required String lectureTitle,
    required int timestampSeconds,
    required String content,
  }) async {
    final note = LectureNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseId: courseId,
      lectureId: lectureId,
      lectureTitle: lectureTitle,
      timestampSeconds: timestampSeconds,
      content: content,
      createdAt: DateTime.now(),
    );

    await _storage.addNote(note);
    loadNotes();
  }

  Future<void> deleteNote(String noteId) async {
    await _storage.deleteNote(noteId);
    loadNotes();
  }
}
