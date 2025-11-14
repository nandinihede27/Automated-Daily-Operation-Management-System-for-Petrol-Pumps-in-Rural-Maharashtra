import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentDetailsPage extends StatelessWidget {
  final String employeeId;
  const PaymentDetailsPage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: StreamBuilder(
        stream: _firestore
            .collection('payments')
            .where('employeeId', isEqualTo: employeeId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No payment records found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(data['date'].toDate())}',
                  ),
                  subtitle: Text(
                      'Cash: ₹${data['cash']} | UPI: ₹${data['upi']}\nExpenses: ₹${data['expenseAmount']} (${data['expenseDescription']})'),
                  trailing: Text('Total: ₹${data['total']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
