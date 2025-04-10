import 'package:sjut/models/student.dart';

class Comment {
  final int id;
  final String comment;
  final dynamic commentable; // Could be Student or User

  Comment({required this.id, required this.comment, required this.commentable});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      comment: json['comment'],
      commentable: json['commentable'] != null && json['commentable_type'] == 'App\\Models\\Student'
          ? Student.fromJson(json['commentable'])
          : null, // Handle User if needed
    );
  }
}