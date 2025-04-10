class Student {
  final int id;
  final String name; // Added
  final String regNo;
  final int yearOfStudy;
  final int facultyId;
  final String email;
  final String gender;

  Student({
    required this.id,
    required this.name,
    required this.regNo,
    required this.yearOfStudy,
    required this.facultyId,
    required this.email,
    required this.gender,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'], // Added
      regNo: json['reg_no'],
      yearOfStudy: json['year_of_study'],
      facultyId: json['faculty_id'],
      email: json['email'],
      gender: json['gender'],
    );
  }
}