import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  final String employeeId;
  const AttendancePage({super.key, required this.employeeId});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool? isPresentToday;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTodayAttendance();
  }

  Future<void> _checkTodayAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final query = await _firestore
          .collection('attendance')
          .where('employeeId', isEqualTo: widget.employeeId)
          .where('date', isEqualTo: today)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          isPresentToday = query.docs.first['isPresent'];
          isLoading = false;
        });
      } else {
        setState(() {
          isPresentToday = null; // Not marked yet
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching attendance: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAttendance(bool present) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await _firestore.collection('attendance').add({
        'employeeId': widget.employeeId,
        'date': today,
        'timestamp': Timestamp.now(),
        'isPresent': present,
      });

      setState(() {
        isPresentToday = present;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            present
                ? '✅ Attendance marked as Present'
                : '❌ Attendance marked as Absent',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mark your Attendance for Today',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (isPresentToday == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _markAttendance(true),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Present'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(130, 50),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: () => _markAttendance(false),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Absent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(130, 50),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Icon(
                          isPresentToday!
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: isPresentToday! ? Colors.green : Colors.red,
                          size: 80,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isPresentToday!
                              ? 'You are marked PRESENT today'
                              : 'You are marked ABSENT today',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}
