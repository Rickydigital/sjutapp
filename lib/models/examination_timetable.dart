class ExaminationTimetable {
  final int id;
  final String timetableType;
  final String program;
  final String semester;
  final String courseCode;
  final int facultyId;
  final int yearId;
  final String examDate;
  final String startTime;
  final String endTime;
  final int venueId;
  String? venueName; // Add this to store the venue name

  ExaminationTimetable({
    required this.id,
    required this.timetableType,
    required this.program,
    required this.semester,
    required this.courseCode,
    required this.facultyId,
    required this.yearId,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.venueId,
    this.venueName, // Optional field
  });

  factory ExaminationTimetable.fromJson(Map<String, dynamic> json) {
    return ExaminationTimetable(
      id: json['id'],
      timetableType: json['timetable_type'],
      program: json['program'],
      semester: json['semester'],
      courseCode: json['course_code'],
      facultyId: json['faculty_id'],
      yearId: json['year_id'],
      examDate: json['exam_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      venueId: json['venue_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timetable_type': timetableType,
        'program': program,
        'semester': semester,
        'course_code': courseCode,
        'faculty_id': facultyId,
        'year_id': yearId,
        'exam_date': examDate,
        'start_time': startTime,
        'end_time': endTime,
        'venue_id': venueId,
        'venue_name': venueName, 
      };
}