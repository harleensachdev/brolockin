import 'dart:io';
import 'feedback.dart';
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
  final List<File> _images = [];
  final List<String> _extractedTexts = [];
  bool _isProcessing = false;

  final TextEditingController percentageController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    percentageController.addListener(_updateButtonState);
    targetController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    percentageController.dispose();
    targetController.dispose();
    super.dispose();
  }

  // Update Button State
  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _isValidPercentage(percentageController.text) &&
          _isValidPercentage(targetController.text) &&
          _images.isNotEmpty;
    });
  }

  // Pick Image from Camera
  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        if (await imageFile.exists()) {
          setState(() {
            _images.add(imageFile);
          });
          await _processImage(imageFile);
          _updateButtonState(); // Update button state after adding an image
        }
      }
    } catch (e) {
      print("Camera error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera not supported on this device.")),
      );
    }
  }

  // Pick Files from Storage
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null && await File(file.path!).exists()) {
            File imageFile = File(file.path!);
            setState(() {
              _images.add(imageFile);
            });
            await _processImage(imageFile);
            _updateButtonState(); // Update button state after adding an image
          }
        }
      }
    } catch (e) {
      print("File picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files.")),
      );
    }
  }

  // Process Image for Text Recognition
  Future<void> _processImage(File imageFile) async {
    setState(() => _isProcessing = true);

    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      setState(() => _extractedTexts.add(recognizedText.text));
    } catch (e) {
      print("Error recognizing text: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to recognize text from the image.")),
      );
    } finally {
      textRecognizer.close();
      setState(() => _isProcessing = false);
    }
  }

  // Validate Percentage Input
  bool _isValidPercentage(String value) {
    final num = int.tryParse(value);
    return num != null && num >= 0 && num <= 100;
  }

  // Store Data in Firestore
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
    } catch (e) {
      print("Error storing data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save data.")),
      );
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
            Text(
              'Upload your test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Your data is secure',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),
            _isProcessing
                ? Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Processing... Please wait.'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImageFromCamera,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                        child: Text('Take Picture',
                            style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _pickFile,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                        child: Text('Upload Files',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
            SizedBox(height: 20),
            _images.isNotEmpty
                ? Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Image.file(_images[index], fit: BoxFit.cover);
                      },
                    ),
                  )
                : Text('No images uploaded yet'),
            SizedBox(height: 10),
            TextField(
              controller: percentageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Input your percentage score:',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Input your target score:',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () async {
                      await _storeTextsInDatabase();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackPage(
                            extractedTexts: _extractedTexts,
                            percentageScore: percentageController.text,
                            targetScore: targetController.text,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text('Get Feedback',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
