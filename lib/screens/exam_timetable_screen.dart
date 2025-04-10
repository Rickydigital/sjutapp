import 'package:flutter/material.dart';
import 'package:sjut/services/api_service.dart';
import 'package:sjut/models/examination_timetable.dart';
import 'package:logger/logger.dart';

class ExamTimetableScreen extends StatefulWidget {
  const ExamTimetableScreen({super.key});

  @override
  ExamTimetableScreenState createState() => ExamTimetableScreenState();
}

class ExamTimetableScreenState extends State<ExamTimetableScreen> {
  final ApiService _apiService = ApiService();
  List<ExaminationTimetable> _timetables = [];
  bool _isLoading = true;
  String? _error;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _fetchTimetables();
  }

  Future<void> _fetchTimetables() async {
    setState(() => _isLoading = true);
    try {
      _timetables = await _apiService.fetchExaminationTimetables();
      await _apiService.enrichTimetablesWithVenueNames(_timetables);
      await _apiService.saveTimetables('examination_timetables', _timetables);
      _logger.i('Examination timetables fetched successfully');
    } catch (e) {
      _logger.e('Error fetching exam timetables: $e');
      setState(() => _error = e.toString());
      _timetables = await _apiService.loadTimetables('examination_timetables', ExaminationTimetable.fromJson);
      await _apiService.enrichTimetablesWithVenueNames(_timetables);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcomingExams = _timetables.where((exam) => DateTime.parse(exam.examDate).isAfter(now)).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Exams Timetable',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 10),
                      Text('Error: $_error', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: upcomingExams.isEmpty
                      ? const Center(
                          child: Text(
                            'Currently, there is no timetable for you.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: upcomingExams.length,
                          itemBuilder: (context, index) {
                            final exam = upcomingExams[index];
                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(
                                  '${exam.courseCode} - ${exam.program}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Date: ${exam.examDate}\nTime: ${exam.startTime} - ${exam.endTime}\nVenue: ${exam.venueName ?? 'Unknown Venue'}',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}