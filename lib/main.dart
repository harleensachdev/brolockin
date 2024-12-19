import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:namer_app/pages/uploadpage.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bro, Lock In',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: UploadPage(), // Start with the upload page
    );
  }
}
