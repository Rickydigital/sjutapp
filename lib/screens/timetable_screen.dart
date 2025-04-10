import 'package:flutter/material.dart';
import 'package:sjut/services/api_service.dart';
import 'package:sjut/models/timetable.dart';
import 'package:logger/logger.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  TimetableScreenState createState() => TimetableScreenState();
}

class TimetableScreenState extends State<TimetableScreen> {
  final ApiService _apiService = ApiService();
  List<Timetable> _timetables = [];
  bool _isLoading = true;
  String? _error;
  final Logger _logger = Logger();
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  void initState() {
    super.initState();
    _fetchTimetables();
  }

  Future<void> _fetchTimetables() async {
    setState(() => _isLoading = true);
    try {
      _timetables = await _apiService.fetchLectureTimetables();
      await _apiService.enrichTimetablesWithVenueNames(_timetables);
      await _apiService.saveTimetables('lecture_timetables', _timetables);
      // No local scheduling here; backend handles it
    } catch (e) {
      _logger.e('Error fetching timetables: $e');
      setState(() => _error = e.toString());
      _timetables = await _apiService.loadTimetables('lecture_timetables', Timetable.fromJson);
      await _apiService.enrichTimetablesWithVenueNames(_timetables);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<Timetable>> _groupTimetablesByDay() {
    final grouped = <String, List<Timetable>>{};
    for (var day in _weekDays) {
      grouped[day] = _timetables.where((t) => t.day.toLowerCase() == day.toLowerCase()).toList();
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTimetables = _groupTimetablesByDay();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Lecture Timetable',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                  child: _timetables.isEmpty
                      ? const Center(
                          child: Text(
                            'No lecture timetable available.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView(
                          children: _weekDays.map((day) {
                            final dayTimetables = groupedTimetables[day]!;
                            if (dayTimetables.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    day,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                ...dayTimetables.map((timetable) => Card(
                                      elevation: 3,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(12),
                                        title: Text(
                                          '${timetable.courseCode} - ${timetable.activity}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Time: ${timetable.timeStart} - ${timetable.timeEnd}\nVenue: ${timetable.venueName ?? 'Unknown Venue'}',
                                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                                          ),
                                        ),
                                      ),
                                    )),
                              ],
                            );
                          }).toList(),
                        ),
                ),
    );
  }
}