class Timetable {
  final int id;
  final String timetableType;
  final String courseCode;
  final String activity;
  final String day;
  final String timeStart;
  final String timeEnd;
  final int venueId;
  String? venueName; // Nullable, handled with fallback in UI

  Timetable({
    required this.id,
    required this.timetableType,
    required this.courseCode,
    required this.activity,
    required this.day,
    required this.timeStart,
    required this.timeEnd,
    required this.venueId,
    this.venueName,
  });

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      id: json['id'] ?? 0, // Fallback for ID if null
      timetableType: json['timetable_type'] ?? 'Unknown Type',
      courseCode: json['course_code'] ?? 'Unknown Course',
      activity: json['activity'] ?? 'Unknown Activity',
      day: json['day'] ?? 'Unknown Day',
      timeStart: json['time_start'] ?? '00:00',
      timeEnd: json['time_end'] ?? '00:00',
      venueId: json['venue_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timetable_type': timetableType,
        'course_code': courseCode,
        'activity': activity,
        'day': day,
        'time_start': timeStart,
        'time_end': timeEnd,
        'venue_id': venueId,
        'venue_name': venueName,
      };
}