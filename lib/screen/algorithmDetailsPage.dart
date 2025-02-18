import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/customBottomNavigationBar.dart';

class AlgorithmDetailsPage extends StatelessWidget {
  final String documentId;

  AlgorithmDetailsPage({required this.documentId});

  Future<void> integrateAlgorithm(BuildContext context) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference algorithmRef =
        FirebaseFirestore.instance.collection('algorithm').doc(documentId);

    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    return userDoc.update({
      'integrated_algoID': FieldValue.arrayUnion([algorithmRef])
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Algorithm successfully integrated!')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to integrate algorithm: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Color(0xFF0D0828),
        title: Text(
          'Algorithm Details',
          style: GoogleFonts.robotoCondensed(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('algorithm')
            .doc(documentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Algorithm not found."));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Image.asset('assets/images/algorithmIcon.png',
                            height: 50),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data['algo_name'],
                            style: GoogleFonts.robotoCondensed(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    sectionHeader(
                        'Description', Icons.info, data['algo_details']),
                    SizedBox(height: 20),
                    sectionHeader(
                        'Strengths', Icons.thumb_up, data['algo_strength']),
                    SizedBox(height: 20),
                    sectionHeader(
                        'Weaknesses', Icons.thumb_down, data['algo_weakness']),
                    SizedBox(height: 20),
                    sectionHeader('Suitability', Icons.lightbulb_outline,
                        data['algo_suitability']),
                    SizedBox(height: 20),
                    sectionHeader(
                        'Examples', Icons.insights, data['algo_examples']),
                    SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () => integrateAlgorithm(context),
                          child: Text('Integrate now',
                              style: GoogleFonts.robotoCondensed()),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Color(0xFF0D0828),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }

  Widget sectionHeader(String title, IconData icon, dynamic content) {
    List<String> stringList;
    if (content is List) {
      stringList = content.map((e) => e.toString()).toList();
    } else if (content is String) {
      stringList = [content];
    } else {
      stringList = ['Invalid content'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF0D0828)),
            SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.robotoCondensed(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        ...stringList
            .map((line) => Text(
                  '• $line',
                  style: GoogleFonts.robotoCondensed(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ))
            .toList(),
      ],
    );
  }
}
