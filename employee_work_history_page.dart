import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeWorkHistoryPage extends StatelessWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeWorkHistoryPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$employeeName Work History'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workHistory')
            .where('employeeId', isEqualTo: employeeId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No work history found'));
          }

          final workRecords = snapshot.data!.docs;

          return ListView.builder(
            itemCount: workRecords.length,
            itemBuilder: (context, index) {
              final data = workRecords[index].data() as Map<String, dynamic>;
              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                color: Colors.orange[50],
                child: ListTile(
                  title: Text(
                      '${data['date'] ?? ''} | Shift: ${data['startShiftTime'] ?? ''} - ${data['endShiftTime'] ?? ''}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Diesel: ${data['startDiesel']} → ${data['endDiesel']} | Total: ${data['totalDiesel']} L'),
                      Text(
                          'Petrol: ${data['startPetrol']} → ${data['endPetrol']} | Total: ${data['totalPetrol']} L'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
