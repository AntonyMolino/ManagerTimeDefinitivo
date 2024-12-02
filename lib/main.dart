import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:managertime/db/DatabaseHelper.dart';

import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Now you can safely call SystemChrome.setPreferredOrientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  runApp(MyApp());
  DatabaseHelper.getDatabase;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema di Registrazione',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        textTheme: TextTheme(
          headlineSmall: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
      home: LoginScreen(),
    );
  }
}
