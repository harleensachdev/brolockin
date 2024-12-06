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
        title: Text('Upload Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                        child: Text('Take Pictures'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _pickFile,
                        child: Text('Upload File'),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            Text(
              'Pages Processed:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _extractedTexts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      'Page ${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _extractedTexts[index],
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
