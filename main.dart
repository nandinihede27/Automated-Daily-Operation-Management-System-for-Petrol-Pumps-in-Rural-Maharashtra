import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDGKYQb0XAEwm5R_FCBBphVX1YIg6wpLi4",
        authDomain: "mega-b0e15.firebaseapp.com",
        projectId: "mega-b0e15",
        storageBucket: "mega-b0e15.appspot.com",
        messagingSenderId: "293890065297",
        appId: "1:293890065297:web:34f8d774e89412cd52d030",
        measurementId: "G-G12D2XYHG7",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petrol Pump App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
    );
  }
}
