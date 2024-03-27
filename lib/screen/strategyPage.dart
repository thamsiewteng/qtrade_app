import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/customBottomNavigationBar.dart';
import 'algorithmPage.dart';

class StrategyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case where there is no user logged in
      return Scaffold(
        body: Center(child: Text('No user found')),
      );
    }

    // Get the current user's ID
    final String userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
        title: Text(
          'Strategy',
          style: GoogleFonts.robotoCondensed(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 188, 208, 225),
              Color.fromARGB(255, 168, 185, 229),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Deployed Algorithm',
                style: GoogleFonts.robotoCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 10),
              // Mockup for the Recent Deployed Algorithm
              Card(
                elevation: 4,
                color: Colors.white,
                child: ListTile(
                  title: Text('Prophet - AAPL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('MSE 5.36% RMSE 5.36% MAE 1.57% R² 5.36%'),
                ),
              ),
              Card(
                elevation: 4,
                color: Colors.white,
                child: ListTile(
                  title: Text('Prophet - AAPL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('MSE 5.36% RMSE 5.36% MAE 1.57% R² 5.36%'),
                ),
              ),
              // ... Repeat for other algorithms ...

              SizedBox(height: 20),
              Text(
                'Algorithm List',
                style: GoogleFonts.robotoCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 10),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return Text('No algorithms found');
                  }
                  var userDoc = snapshot.data;
                  var integratedAlgos =
                      userDoc!['integrated_algoID'] as List ?? [];

                  return Container(
                    height: 100, // Fixed height container
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          integratedAlgos.length + 1, // +1 for the add button
                      itemBuilder: (context, index) {
                        if (index < integratedAlgos.length) {
                          // Check if the reference is a DocumentReference and extract the ID
                          var docID = integratedAlgos[index]
                                  is DocumentReference
                              ? (integratedAlgos[index] as DocumentReference).id
                              : integratedAlgos[
                                  index]; // assuming it's already a string ID if not a DocumentReference

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('algorithm')
                                .doc(docID)
                                .get(),
                            builder: (context, algoSnapshot) {
                              if (algoSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!algoSnapshot.hasData) {
                                return Text('Loading...');
                              }
                              var algoData = algoSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              return _buildAlgorithmCircle(
                                  algoData['algo_name']);
                            },
                          );
                        } else {
                          return _buildAddAlgorithmCircle(context);
                        }
                      },
                    ),
                  );
                },
              ),

              SizedBox(height: 20),
              Text(
                'Deploy Algorithm',
                style: GoogleFonts.robotoCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              _buildDeployAlgorithmSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2, // Assuming StrategyPage is the third tab
        onTap: (index) {
          // Handle bottom navigation tap
        },
      ),
    );
  }

  Widget _buildAlgorithmCircle(String name) {
    // Wrap your existing Padding with a GestureDetector to handle taps
    return GestureDetector(
      onTap: () {
        // Implement what happens when you tap on the algorithm circle
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Image.asset('assets/images/algorithmIcon.png',
                  width: 40), // Placeholder for actual icon
            ),
            SizedBox(height: 5),
            Text(
              name,
              style: GoogleFonts.robotoCondensed(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAlgorithmCircle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => AlgorithmPage()));
        },
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: Colors.black),
            ),
            SizedBox(height: 5),
            Text(
              'Add',
              style: GoogleFonts.robotoCondensed(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // ... rest of your widget-building methods ...
  Widget _buildDeployAlgorithmSection(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black54,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFeeeef7),
              ),
              hint: Text(
                'Select Algorithm',
                style: GoogleFonts.robotoCondensed(color: Colors.black),
              ),
              items: ['Prophet', 'XGBoost', 'RF+LSTM', 'CNN+LSTM']
                  .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                  .toList(),
              onChanged: (value) {
                // TODO: Handle change
              },
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                hintText: 'Stock Ticker Symbol',
                hintStyle: GoogleFonts.robotoCondensed(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFeeeef7),
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: double.infinity, // Make the button full width
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement deployment action
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text('Deploy now',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D0828), // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(30), // Button border radius
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
