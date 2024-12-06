import 'package:flutter/material.dart'; 
import 'pages/loginpage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bro, Lock In',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(), // Start with the login page
    );
  }
}
