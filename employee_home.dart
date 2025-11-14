import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'work_history_page.dart';
import 'package:intl/intl.dart';

class EmployeeHomePage extends StatefulWidget {
  final String id;
  const EmployeeHomePage({super.key, required this.id});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final startDiesel = TextEditingController();
  final endDiesel = TextEditingController();
  final startPetrol = TextEditingController();
  final endPetrol = TextEditingController();
  final cashCollection = TextEditingController();
  final upiCollection = TextEditingController();
  final employeeExpense = TextEditingController();

  TimeOfDay? startShiftTime;
  TimeOfDay? endShiftTime;

  double totalDiesel = 0;
  double totalPetrol = 0;
  double totalAmount = 0;

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool attendanceMarked = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    checkAttendance();
  }

  void fetchUserData() async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(widget.id).get();
      setState(() {
        userData = snap.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')));
    }
  }

  Future<void> checkAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snap = await _firestore
        .collection('attendance')
        .where('employeeId', isEqualTo: widget.id)
        .where('date', isEqualTo: today)
        .get();

    if (snap.docs.isNotEmpty) {
      setState(() => attendanceMarked = true);
    }
  }

  Future<void> markAttendance() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (attendanceMarked) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance already marked')));
      return;
    }

    await _firestore.collection('attendance').add({
      'employeeId': widget.id,
      'date': today,
      'time': DateFormat('hh:mm a').format(DateTime.now()),
    });

    setState(() => attendanceMarked = true);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance marked successfully')));
  }

  void pickStartTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => startShiftTime = time);
  }

  void pickEndTime() async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => endShiftTime = time);
  }

  void calculateTotals() {
    setState(() {
      totalDiesel = ((double.tryParse(endDiesel.text) ?? 0) -
              (double.tryParse(startDiesel.text) ?? 0))
          .abs();
      totalPetrol = ((double.tryParse(endPetrol.text) ?? 0) -
              (double.tryParse(startPetrol.text) ?? 0))
          .abs();

      final cash = double.tryParse(cashCollection.text) ?? 0;
      final upi = double.tryParse(upiCollection.text) ?? 0;
      final exp = double.tryParse(employeeExpense.text) ?? 0;

      totalAmount = (cash + upi) - exp;
    });
  }

  void submitWorkHistory() async {
    if (startShiftTime == null || endShiftTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select shift times')));
      return;
    }

    calculateTotals();

    try {
      await _firestore.collection('workHistory').add({
        'employeeId': widget.id,
        'date': Timestamp.now(),
        'startShiftTime': startShiftTime!.format(context),
        'endShiftTime': endShiftTime!.format(context),
        'startDiesel': double.tryParse(startDiesel.text) ?? 0,
        'endDiesel': double.tryParse(endDiesel.text) ?? 0,
        'totalDiesel': totalDiesel,
        'startPetrol': double.tryParse(startPetrol.text) ?? 0,
        'endPetrol': double.tryParse(endPetrol.text) ?? 0,
        'totalPetrol': totalPetrol,
        'cash': double.tryParse(cashCollection.text) ?? 0,
        'upi': double.tryParse(upiCollection.text) ?? 0,
        'expense': double.tryParse(employeeExpense.text) ?? 0,
        'totalAmount': totalAmount,
      });

      await _firestore.collection('dailyReports').add({
        'employeeId': widget.id,
        'employeeName': userData?['name'] ?? '',
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'cashCollection': double.tryParse(cashCollection.text) ?? 0,
        'upiCollection': double.tryParse(upiCollection.text) ?? 0,
        'employeeExpense': double.tryParse(employeeExpense.text) ?? 0,
        'totalAmount': totalAmount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift data submitted successfully')));

      // Clear fields
      startDiesel.clear();
      endDiesel.clear();
      startPetrol.clear();
      endPetrol.clear();
      cashCollection.clear();
      upiCollection.clear();
      employeeExpense.clear();

      setState(() {
        startShiftTime = null;
        endShiftTime = null;
        totalDiesel = 0;
        totalPetrol = 0;
        totalAmount = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ----- Apply Leave -----
  void applyLeave() async {
    TextEditingController reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                  labelText: 'Reason', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) selectedDate = picked;
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: const Text('Select Date'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () async {
              await _firestore.collection('leaveRequests').add({
                'employeeId': widget.id,
                'employeeName': userData?['name'] ?? '',
                'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                'reason': reasonController.text,
                'status': 'Pending',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Leave request submitted successfully')));
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
          title: const Text('Employee Dashboard'),
          backgroundColor: Colors.deepOrange),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userData?['name'] ?? 'Loading...'),
              accountEmail: Text(userData?['email'] ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.deepOrange.shade200,
                child: Text(
                  userData?['name'] != null
                      ? userData!['name'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              decoration: BoxDecoration(color: Colors.deepOrange),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: widget.id)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Work History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => WorkHistoryPage(employeeId: widget.id)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.time_to_leave),
              title: const Text('Apply for Leave'),
              onTap: applyLeave,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: markAttendance,
                    icon: Icon(attendanceMarked
                        ? Icons.check
                        : Icons.assignment_turned_in),
                    label: Text(attendanceMarked
                        ? 'Attendance Marked'
                        : 'Mark Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          attendanceMarked ? Colors.green : Colors.deepOrange,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: pickStartTime,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange),
                          child: Text(startShiftTime == null
                              ? 'Select Start Time'
                              : 'Start: ${startShiftTime!.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: pickEndTime,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange),
                          child: Text(endShiftTime == null
                              ? 'Select End Time'
                              : 'End: ${endShiftTime!.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  buildFuelField('Start Diesel', startDiesel),
                  const SizedBox(height: 10),
                  buildFuelField('End Diesel', endDiesel),
                  const SizedBox(height: 10),
                  buildFuelField('Start Petrol', startPetrol),
                  const SizedBox(height: 10),
                  buildFuelField('End Petrol', endPetrol),
                  const SizedBox(height: 20),
                  buildMoneyField(
                      'Cash Collection', cashCollection, Icons.money),
                  const SizedBox(height: 10),
                  buildMoneyField(
                      'UPI Collection', upiCollection, Icons.qr_code),
                  const SizedBox(height: 10),
                  buildMoneyField(
                      'Employee Expenses', employeeExpense, Icons.receipt),
                  const SizedBox(height: 20),
                  Text(
                    'Total Diesel: $totalDiesel | Total Petrol: $totalPetrol',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Net Total (Cash + UPI - Expense): ₹$totalAmount',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: submitWorkHistory,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text('Submit Shift Data',
                        style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildFuelField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.local_gas_station),
        filled: true,
        fillColor: Colors.orange.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget buildMoneyField(
      String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.orange.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
