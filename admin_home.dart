import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'employee_management.dart';
import 'work_history_page.dart';
import 'package:intl/intl.dart';

class AdminHomePage extends StatefulWidget {
  final String id;
  const AdminHomePage({super.key, required this.id});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // Controllers for stock and rate
  final petrolStock = TextEditingController();
  final dieselStock = TextEditingController();
  final petrolRate = TextEditingController();
  final dieselRate = TextEditingController();

  // Controllers for payments
  final cashInHand = TextEditingController();
  final upiInHand = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchStockData();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(widget.id).get();
      setState(() {
        userData = snap.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Fetch existing stock data if available
  Future<void> fetchStockData() async {
    final snap = await _firestore.collection('stock').doc('currentStock').get();
    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        petrolStock.text = data['petrolStock'].toString();
        dieselStock.text = data['dieselStock'].toString();
        petrolRate.text = data['petrolRate'].toString();
        dieselRate.text = data['dieselRate'].toString();
      });
    }
  }

  // Update stock and rate in Firestore
  Future<void> updateStockAndRate() async {
    await _firestore.collection('stock').doc('currentStock').set({
      'petrolStock': double.tryParse(petrolStock.text) ?? 0,
      'dieselStock': double.tryParse(dieselStock.text) ?? 0,
      'petrolRate': double.tryParse(petrolRate.text) ?? 0,
      'dieselRate': double.tryParse(dieselRate.text) ?? 0,
      'lastUpdated': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock and rates updated successfully')),
    );
  }

  // Update payments
  Future<void> updatePayment() async {
    await _firestore.collection('payments').add({
      'cashInHand': double.tryParse(cashInHand.text) ?? 0,
      'upiInHand': double.tryParse(upiInHand.text) ?? 0,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payments updated successfully')),
    );
  }

  // Generate daily report
  Future<void> generateReport() async {
    final reportSnapshot = await _firestore.collection('dailyReports').get();

    double totalCash = 0;
    double totalUPI = 0;
    double totalExpense = 0;
    double totalAmount = 0;

    for (var doc in reportSnapshot.docs) {
      final data = doc.data();
      totalCash += (data['cashCollection'] ?? 0).toDouble();
      totalUPI += (data['upiCollection'] ?? 0).toDouble();
      totalExpense += (data['employeeExpense'] ?? 0).toDouble();
      totalAmount += (data['totalAmount'] ?? 0).toDouble();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Report Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Cash: ₹$totalCash'),
            Text('Total UPI: ₹$totalUPI'),
            Text('Total Expense: ₹$totalExpense'),
            const Divider(),
            Text('Net Total: ₹$totalAmount',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  // ---- Show Employee List with Work History ----
  void openEmployeeList(BuildContext context) async {
    final employees = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .get();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: employees.docs.length,
          itemBuilder: (context, index) {
            final emp = employees.docs[index];
            return ListTile(
              leading: const Icon(Icons.person, color: Colors.orange),
              title: Text(emp['name']),
              subtitle: Text(emp['email']),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkHistoryPage(employeeId: emp.id), // <-- fixed
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.orange,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userData?['name'] ?? 'Loading...'),
              accountEmail: Text(userData?['email'] ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userData?['name'] != null
                      ? userData!['name'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 26,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.orange),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: widget.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Manage Employees'),
              onTap: () => openEmployeeList(context),
            ),
            const Divider(),
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
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ---- Update Stock Section ----
                  Card(
                    elevation: 4,
                    color: Colors.orange[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Update Stock & Rate',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          buildField('Petrol Stock (L)', petrolStock),
                          buildField('Diesel Stock (L)', dieselStock),
                          buildField('Petrol Rate (₹/L)', petrolRate),
                          buildField('Diesel Rate (₹/L)', dieselRate),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: updateStockAndRate,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: const Text('Save Stock & Rates'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---- Update Payment Section ----
                  Card(
                    elevation: 4,
                    color: Colors.orange[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Update Payment',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          buildField('Cash in Hand (₹)', cashInHand),
                          buildField('UPI in Hand (₹)', upiInHand),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: updatePayment,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: const Text('Save Payment'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ---- Generate Report Section ----
                  ElevatedButton.icon(
                    onPressed: generateReport,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        minimumSize: const Size(double.infinity, 50)),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Generate Daily Report'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.orange.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
