import 'package:flutter/material.dart';
import 'employee_home.dart';
import 'admin_home.dart';

class HomePage extends StatelessWidget {
  final String id;
  final String role;

  const HomePage({super.key, required this.id, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == 'admin') {
      return AdminHomePage(id: id);
    } else {
      return EmployeeHomePage(id: id);
    }
  }
}
