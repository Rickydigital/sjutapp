import 'package:sjut/models/student.dart';

class Reaction {
  final int id;
  final String type;
  final dynamic reactable; // Could be Student or User

  Reaction({required this.id, required this.type, required this.reactable});

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'],
      type: json['type'],
      reactable: json['reactable'] != null && json['reactable_type'] == 'App\\Models\\Student'
          ? Student.fromJson(json['reactable'])
          : null, // Handle User if needed
    );
  }
}