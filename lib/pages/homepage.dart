import 'package:flutter/material.dart'; // Brings in Flutter Material UI Package
import 'uploadpage.dart'; // Importing of custom screens
import 'progresspage.dart';
import 'feedback.dart';
import 'loginpage.dart';

class HomePage extends StatelessWidget { // Homepage class with stateless widget (doesnt change after building)
  @override
  Widget build(BuildContext context) { // Returns widget tree
    return Scaffold(
      appBar: AppBar( // App title
        title: Text('Bro, Lock In'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout), // Logout icon
            onPressed: () {
              // Navigate back to the LoginPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Bro, Lock In!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  // Navigate to upload page
                  MaterialPageRoute(builder: (context) => UploadPage()),
                );
              },
              child: Text('Upload Test'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  // Navigate to progress page
                  MaterialPageRoute(builder: (context) => ProgressPage()),
                );
              },
              child: Text('View Progress'),
            ),
          ],
        ),
      ),
    );
  }
}
