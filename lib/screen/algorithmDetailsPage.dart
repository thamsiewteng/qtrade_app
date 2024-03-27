import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/customBottomNavigationBar.dart';

class AlgorithmDetailsPage extends StatelessWidget {
  final String documentId;

  AlgorithmDetailsPage({required this.documentId});

  Future<void> integrateAlgorithm(BuildContext context) async {
    String userId =
        FirebaseAuth.instance.currentUser!.uid; // Get the current user's ID
    DocumentReference algorithmRef = FirebaseFirestore.instance
        .collection('algorithm')
        .doc(documentId); // Reference to the algorithm document

    // Reference to the user's document
    DocumentReference userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId);

    // Add the algorithm DocumentReference to the user's document
    return userDoc.update({
      'integrated_algoID': FieldValue.arrayUnion(
          [algorithmRef]) // Use arrayUnion with a DocumentReference
    }).then((_) {
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Algorithm successfully integrated!')),
      );
      // Optionally pop the current page
      // Navigator.of(context).pop();
    }).catchError((error) {
      // Handle any errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to integrate algorithm: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        title: Text(
          'Algorithm Details',
          style: GoogleFonts.robotoCondensed(color: Colors.black),
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 188, 208, 225),
                  Color.fromARGB(255, 168, 185, 229)
                ],
              ),
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
                        SizedBox(
                            width:
                                10), // Add some space between the image and the text
                        Expanded(
                          // Wrap the text in an Expanded to handle overflow
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
        onTap: (index) {
          // Handle bottom navigation tap.
        },
      ),
    );
  }

  Widget sectionHeader(String title, IconData icon, dynamic content) {
    // First, check if content is a list or a single string
    List<String> stringList;
    if (content is List) {
      // Cast each element in the list to String, assuming all elements can be represented as strings
      stringList = content.map((e) => e.toString()).toList();
    } else if (content is String) {
      // If it's a single string, wrap it in a list
      stringList = [content];
    } else {
      // If it's neither, handle this case appropriately (perhaps an empty list or some default value)
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
