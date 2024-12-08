import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Progress'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('user_data').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index];
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text('Percentage Score: ${data['percentageScore']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Score: ${data['targetScore']}'),
                      SizedBox(height: 5),
                      Text('Extracted Texts: ${data['extractedTexts'].join(", ")}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
