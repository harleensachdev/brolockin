import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _image;
  String _extractedText = "";
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();

  // Function to pick an image from camera
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = true;
      });

      _processImage();
    }
  }

  // Function to pick a file from storage
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['jpg', 'jpeg', 'png'], // Supported file types
    );

    if (result != null) {
      setState(() {
        _image = File(result.files.single.path!);
        _isProcessing = true;
      });

      _processImage();
    }
  }

  // Function to process the image and extract text
  Future<void> _processImage() async {
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(_image!);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognizedText.text;
        _isProcessing = false;
      });

      // Store the extracted text in the database
      _storeTextInDatabase(_extractedText);
    } catch (e) {
      print("Error recognizing text: $e");
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Function to store text in Firestore
  Future<void> _storeTextInDatabase(String text) async {
    final CollectionReference texts =
        FirebaseFirestore.instance.collection('texts');

    await texts.add({'content': text, 'timestamp': FieldValue.serverTimestamp()});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Text saved to database!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            _isProcessing
                ? CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _pickImageFromCamera,
                        child: Text('Take Picture'),
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
              'Extracted Text:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _extractedText.isNotEmpty ? _extractedText : 'No text detected.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
