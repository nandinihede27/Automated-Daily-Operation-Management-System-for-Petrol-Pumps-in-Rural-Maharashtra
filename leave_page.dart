import 'package:flutter/material.dart';

class LeavePage extends StatelessWidget {
  final String employeeId;
  const LeavePage({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Requests')),
      body: const Center(child: Text('Leave form and history will go here')),
    );
  }
}
