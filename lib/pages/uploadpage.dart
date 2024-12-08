import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  List<String> _extractedTexts = []; // Store text for each page
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();

  // Function to pick an image from the camera
  Future<void> _pickImageFromCamera() async {
    while (true) {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile == null) {
        // User canceled or finished taking pictures
        if (_extractedTexts.isNotEmpty) {
          _storeTextsInDatabase();
        }
        break;
      }

      setState(() {
        _isProcessing = true;
      });

      await _processImage(File(pickedFile.path));
    }
  }

  // Function to pick an image from file picker
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'], // Supported file types
    );

    if (result != null) {
      setState(() {
        _isProcessing = true;
      });

      await _processImage(File(result.files.single.path!));
      _storeTextsInDatabase(); // Save to database after processing
    }
  }

  // Function to process the image and extract text
  Future<void> _processImage(File imageFile) async {
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _extractedTexts.add(recognizedText.text);
        _isProcessing = false;
      });
    } catch (e) {
      print("Error recognizing text: $e");
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Function to store all extracted texts in Firestore
  Future<void> _storeTextsInDatabase() async {
    final CollectionReference texts =
        FirebaseFirestore.instance.collection('texts');

    for (var i = 0; i < _extractedTexts.length; i++) {
      await texts.add({
        'content': _extractedTexts[i],
        'page': i + 1,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All pages saved to database!')),
    );

    setState(() {
      _extractedTexts.clear(); // Clear stored texts after saving
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Your Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Upload your test',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your data is secure',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            _isProcessing
                ? Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Processing... Please wait.'),
                    ],
                  )
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _pickImageFromCamera,
                        child: Text('Take picture'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _pickFile,
                        child: Text('Upload file'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Input your percentage score:',
                suffixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Input your target score:',
                suffixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to feedback page
                Navigator.pushNamed(context, '/feedback');
              },
              child: Text('Get feedback'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to progress page
                Navigator.pushNamed(context, '/progresspage');
              },
              child: Text('See my progress'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
