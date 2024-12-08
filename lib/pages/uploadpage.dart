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
  List<String> _extractedTexts = [];
  bool _isProcessing = false;
  TextEditingController percentageController = TextEditingController();
  TextEditingController targetController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromCamera() async {
    while (true) {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _isProcessing = true;
      });

      await _processImage(File(result.files.single.path!));
      _storeTextsInDatabase();
    }
  }

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

  Future<void> _storeTextsInDatabase() async {
    final CollectionReference texts =
        FirebaseFirestore.instance.collection('user_data');

    try {
      await texts.add({
        'extractedTexts': _extractedTexts,
        'percentageScore': percentageController.text,
        'targetScore': targetController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully!')),
      );

      setState(() {
        _extractedTexts.clear();
        percentageController.clear();
        targetController.clear();
      });
    } catch (e) {
      print("Error storing data: $e");
    }
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
                        child: Text('Take picture', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _pickFile,
                        child: Text('Upload file', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            TextField(
              controller: percentageController,
              decoration: InputDecoration(
                labelText: 'Input your percentage score:',
                suffixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: targetController,
              decoration: InputDecoration(
                labelText: 'Input your target score:',
                suffixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _storeTextsInDatabase();
                Navigator.pushNamed(context, '/feedback');
              },
              child: Text('Get feedback', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/progresspage');
              },
              child: Text('See my progress', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
