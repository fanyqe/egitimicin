import 'dart:convert';
import 'package:intl/intl.dart';

class StudyRecord {
  final String id;
  final String studentId;
  final DateTime studyDate;
  final DateTime createdAt;
  final String? note;

  StudyRecord({
    required this.id,
    required this.studentId,
    required this.studyDate,
    required this.createdAt,
    this.note,
  });

  factory StudyRecord.fromJson(Map<String, dynamic> json) {
    return StudyRecord(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studyDate: DateTime.parse(json['study_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      note: json['note'] as String?,
    );
  }

  factory StudyRecord.fromMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      studyDate: DateTime.parse(map['study_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'study_date': studyDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'note': note,
    };
  }
}

class StudentStudyStatus {
  final String studentId;
  final String name;
  final String surname;
  final String schoolNumber;
  final Map<DateTime, bool> studyDays;

  StudentStudyStatus({
    required this.studentId,
    required this.name,
    required this.surname,
    required this.schoolNumber,
    required this.studyDays,
  });

  bool hasStudiedOn(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    return studyDays[dayStart] ?? false;
  }

  String getFormattedDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  int getTotalStudyDays() {
    return studyDays.values.where((studied) => studied).length;
  }
}
