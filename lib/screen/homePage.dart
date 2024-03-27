import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/customBottomNavigationBar.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference guidesCollection =
      FirebaseFirestore.instance.collection('investment_guides');

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No user found. Please login.',
            style: GoogleFonts.robotoCondensed(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
      ),
      body: Container(
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
          child: FutureBuilder<DocumentSnapshot>(
            future: firestore.collection('users').doc(user.uid).get(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Something went wrong"));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("User not found."));
              }

              Map<String, dynamic> userData =
                  snapshot.data!.data() as Map<String, dynamic>;
              String fullName = userData['fullName'] ?? 'User';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Welcome, $fullName.',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      color: Color(0xFFeeeef7), // Match the screenshot color
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Your total asset portfolio',
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '\$10,000',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.robotoCondensed(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Handle invest now action
                              },
                              child: Text('Invest now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color(0xFF0D0828), // Background color
                                foregroundColor: Colors.white, // Text color
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Stocks',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        StockTile(
                          stockName: 'Google',
                          stockPrice: '\$904.00',
                          priceChange: '-1.80%',
                          iconColor: Colors.red, // Change as needed
                        ),
                        StockTile(
                          stockName: 'Apple',
                          stockPrice: '\$321.00',
                          priceChange: '+2.10%',
                          iconColor: Colors.green, // Change as needed
                        ),
                        StockTile(
                          stockName: 'Amazon',
                          stockPrice: '\$1,893.00',
                          priceChange: '-0.32%',
                          iconColor: Colors.red, // Change as needed
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Handle see all action
                            },
                            child: Text(
                              'See All',
                              style: GoogleFonts.robotoCondensed(
                                color: Color(
                                    0xFF0D0828), // Adjust to match the screenshot
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Investment Guide',
                          style: GoogleFonts.robotoCondensed(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: guidesCollection.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text("Something went wrong");
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Text("No Investment Guides Found");
                            }

                            // Randomize and get three documents
                            var allGuides = snapshot.data!.docs;
                            allGuides.shuffle(Random());
                            var randomGuides = allGuides.take(3).toList();

                            return Column(
                              children: randomGuides.map((doc) {
                                var guideData =
                                    doc.data() as Map<String, dynamic>;
                                return InvestmentGuideItem(
                                  title: guideData['title'],
                                  content: guideData['content'],
                                );
                              }).toList(),
                            );
                          },
                        ), // ... More content
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      // BottomNavigationBar is assumed to be a custom widget created elsewhere
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0, // Assuming HomePage is the first tab
        onTap: (index) {
          // Handle navigation bar tap
        },
      ),
    );
  }
}

class StockTile extends StatelessWidget {
  final String stockName;
  final String stockPrice;
  final String priceChange;
  final Color iconColor;

  StockTile({
    required this.stockName,
    required this.stockPrice,
    required this.priceChange,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor.withOpacity(0.2),
        ),
        child: Icon(Icons.show_chart, color: iconColor),
      ),
      title: Text(
        stockName,
        style: GoogleFonts.robotoCondensed(),
      ),
      subtitle: Text(
        priceChange,
        style: GoogleFonts.robotoCondensed(color: iconColor),
      ),
      trailing: Text(
        stockPrice,
        style: GoogleFonts.robotoCondensed(),
      ),
    );
  }
}

class InvestmentGuideItem extends StatelessWidget {
  final String title;
  final String content;

  const InvestmentGuideItem({
    required this.title,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.robotoCondensed(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              content,
              style: GoogleFonts.robotoCondensed(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
