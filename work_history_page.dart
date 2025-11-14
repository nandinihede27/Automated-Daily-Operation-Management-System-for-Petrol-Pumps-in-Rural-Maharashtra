import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkHistoryPage extends StatelessWidget {
  final String? employeeId;
  const WorkHistoryPage({super.key, this.employeeId});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('workHistory');

    // ✅ Ensure filter only applied if employeeId exists
    if (employeeId != null && employeeId!.isNotEmpty) {
      query = query.where('employeeId', isEqualTo: employeeId);
    }

    // ✅ Don't use orderBy if Firestore index not created — instead, sort manually later
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work History'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No work history found'));
          }

          // ✅ Convert and sort manually (most recent first)
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final adate = (a['date'] as Timestamp).toDate();
              final bdate = (b['date'] as Timestamp).toDate();
              return bdate.compareTo(adate);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final formattedDate = DateFormat('dd MMM yyyy').format(date);

              return Card(
                color: Colors.orange.shade50,
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station,
                      color: Colors.deepOrange),
                  title: Text(
                    '$formattedDate | ${data['startShiftTime']} - ${data['endShiftTime']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Diesel: ${data['startDiesel']} → ${data['endDiesel']} (Total: ${data['totalDiesel']})\n'
                    'Petrol: ${data['startPetrol']} → ${data['endPetrol']} (Total: ${data['totalPetrol']})',
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
