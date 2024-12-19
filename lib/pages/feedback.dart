import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackPage extends StatefulWidget {
  final List<String> extractedTexts;
  final String percentageScore;
  final String targetScore;

  FeedbackPage({
    required this.extractedTexts,
    required this.percentageScore,
    required this.targetScore,
  });

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String aiFeedback = "Generating feedback...";

  @override
  void initState() {
    super.initState();
    fetchFeedback();
  }

  Future<void> fetchFeedback() async {
    try {
      final url = Uri.parse('http://192.168.1.103:5000/api/feedback'); // Flask API URL
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "extracted_texts": widget.extractedTexts,
          "percentage_score": widget.percentageScore,
          "target_score": widget.targetScore,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aiFeedback = data['feedback'] ?? "No feedback generated.";
        });
      } else {
        setState(() {
          aiFeedback = "Failed to generate feedback. Try again later.";
        });
      }
    } catch (e) {
      setState(() {
        aiFeedback = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extracted Text:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.extractedTexts.length,
                itemBuilder: (context, index) {
                  return Text(widget.extractedTexts[index], style: TextStyle(fontSize: 14));
                },
              ),
            ),
            Divider(),
            Text('Your Score: ${widget.percentageScore}%', style: TextStyle(fontSize: 16)),
            Text('Target Score: ${widget.targetScore}%', style: TextStyle(fontSize: 16)),
            Divider(),
            SizedBox(height: 10),
            Text('AI Feedback:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(aiFeedback, style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
