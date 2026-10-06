import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture.dart';

class StorageService {
  static const String _keyBookmarks = 'bookmarked_course_ids';
  static const String _keyNotes = 'lecture_notes_data';
  static const String _keyDownloads = 'downloaded_lecture_ids';
  static const String _keyProgressPrefix = 'lecture_progress_';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs => _prefs;

  // --- Bookmarks ---
  Set<String> getBookmarkedCourseIds() {
    final list = _prefs.getStringList(_keyBookmarks) ?? [];
    return list.toSet();
  }

  Future<void> toggleBookmark(String courseId) async {
    final set = getBookmarkedCourseIds();
    if (set.contains(courseId)) {
      set.remove(courseId);
    } else {
      set.add(courseId);
    }
    await _prefs.setStringList(_keyBookmarks, set.toList());
  }

  // --- Lecture Progress ---
  double getLectureProgress(String lectureId) {
    return _prefs.getDouble('$_keyProgressPrefix$lectureId') ?? 0.0;
  }

  Future<void> saveLectureProgress(String lectureId, double progress) async {
    await _prefs.setDouble(
        '$_keyProgressPrefix$lectureId', progress.clamp(0.0, 1.0));
  }

  // --- Downloads ---
  Set<String> getDownloadedLectureIds() {
    final list = _prefs.getStringList(_keyDownloads) ?? [];
    return list.toSet();
  }

  Future<void> setLectureDownloaded(String lectureId, bool downloaded) async {
    final set = getDownloadedLectureIds();
    if (downloaded) {
      set.add(lectureId);
    } else {
      set.remove(lectureId);
    }
    await _prefs.setStringList(_keyDownloads, set.toList());
  }

  Future<void> toggleDownloaded(String lectureId) async {
    final set = getDownloadedLectureIds();
    if (set.contains(lectureId)) {
      set.remove(lectureId);
    } else {
      set.add(lectureId);
    }
    await _prefs.setStringList(_keyDownloads, set.toList());
  }

  // --- Notes ---
  List<LectureNote> getNotes() {
    final rawList = _prefs.getStringList(_keyNotes) ?? [];
    return rawList.map((str) {
      final jsonMap = jsonDecode(str) as Map<String, dynamic>;
      return LectureNote.fromJson(jsonMap);
    }).toList();
  }

  Future<void> addNote(LectureNote note) async {
    final notes = getNotes();
    notes.insert(0, note);
    final rawList = notes.map((n) => jsonEncode(n.toJson())).toList();
    await _prefs.setStringList(_keyNotes, rawList);
  }

  Future<void> deleteNote(String noteId) async {
    final notes = getNotes();
    notes.removeWhere((n) => n.id == noteId);
    final rawList = notes.map((n) => jsonEncode(n.toJson())).toList();
    await _prefs.setStringList(_keyNotes, rawList);
  }
}
