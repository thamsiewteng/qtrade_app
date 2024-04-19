import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qtrade_app/screen/deployedHistoryPage.dart';

import '../widgets/customBottomNavigationBar.dart';
import 'algorithmPage.dart';
import 'package:intl/intl.dart';

class StrategyPage extends StatelessWidget {
  final TextEditingController _tickerController = TextEditingController();

  StrategyPage({Key? key}) : super(key: key);

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
          padding: const EdgeInsets.only(
            left: 16.0,
            top: 16.0,
            right: 16.0,
            bottom: 120.0, // Enough bottom padding to fill out the space
          ),
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
                                  algoData['algo_name'], context);
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
                  color: Colors.black,
                ),
              ),
              _buildDeployAlgorithmSection(context, userId),
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

  Widget _buildAlgorithmCircle(String name, BuildContext context) {
    // Wrap your existing Padding with a GestureDetector to handle taps
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // Pass the selected algorithm name
            builder: (context) => DeployedHistoryPage(algoName: name),
          ),
        );
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

  Widget _buildDeployAlgorithmSection(BuildContext context, String userId) {
    // Calculate start date constraints based on current date
    DateTime currentDate = DateTime.now();
    DateTime eightYearsAgo = currentDate.subtract(Duration(days: 365 * 8));
    DateTime twelveYearsAgo = currentDate.subtract(Duration(days: 365 * 12));

    // Initialize start date to eight years ago by default
    DateTime selectedStartDate = eightYearsAgo;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                'Algorithm',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return Text('User not found');
                  }
                  List<dynamic> integratedAlgos = (snapshot.data!.data()
                          as Map<String, dynamic>)['integrated_algoID'] ??
                      [];
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('algorithm')
                        .where(FieldPath.documentId, whereIn: integratedAlgos)
                        .get(),
                    builder: (context, algoSnapshot) {
                      if (algoSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!algoSnapshot.hasData ||
                          algoSnapshot.data!.docs.isEmpty) {
                        return Text('No algorithms found');
                      }
                      List<DropdownMenuItem<String>> dropdownItems =
                          algoSnapshot.data!.docs.map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(doc.get('algo_name')),
                        );
                      }).toList();
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color.fromARGB(255, 235, 235, 245),
                        ),
                        hint: Text('Select Algorithm',
                            style: GoogleFonts.robotoCondensed(
                                color: Colors.black54)),
                        items: dropdownItems,
                        onChanged: (value) {
                          // Do something with the selected algorithm
                        },
                        icon: Icon(Icons.keyboard_arrow_down),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                'Stock Ticker Symbol',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('s&p500')
                    .doc('tickers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  List<String> tickers =
                      List<String>.from(snapshot.data!['symbols']);
                  return Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return tickers.where((String option) {
                          return option
                              .toLowerCase()
                              .startsWith(textEditingValue.text.toLowerCase());
                        });
                      }
                    },
                    onSelected: (String selection) {
                      debugPrint('You just selected $selection');
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          hintText: 'Enter ticker symbol',
                          hintStyle: GoogleFonts.robotoCondensed(
                              color: Colors.black54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color.fromARGB(255, 235, 235, 245),
                        ),
                      );
                    },
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Adjust the spacing as needed
                children: [
                  Text(
                    'Start Date (8-12 years ago)',
                    style: GoogleFonts.robotoCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.help_outline),
                    onPressed: () => _showInstructions(context),
                    padding: EdgeInsets
                        .zero, // This reduces the default padding around the icon
                    constraints:
                        BoxConstraints(), // Removes constraints for minimum hit testing size
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedStartDate,
                    firstDate: twelveYearsAgo,
                    lastDate: eightYearsAgo,
                  );
                  if (picked != null) {
                    // Update the start date if the user picks a valid date
                    selectedStartDate = picked;
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color.fromARGB(255, 235, 235, 245),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(selectedStartDate),
                        style:
                            GoogleFonts.robotoCondensed(color: Colors.black54),
                      ),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle the deploy action
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Deploy now',
                      style: GoogleFonts.robotoCondensed(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D0828), // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Button border radius
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instructions',
              style: GoogleFonts.robotoCondensed(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'For optimal algorithm performance:',
                  style: GoogleFonts.robotoCondensed(fontSize: 16),
                ),
                Text(
                    '• Select a start date 8 to 12 years prior to today.\n'
                    '• This time frame ensures sufficient historical data for accuracy.\n'
                    '• It also helps maintain manageable computation times.\n'
                    'Choosing within this range balances efficiency with predictive power.',
                    style: GoogleFonts.robotoCondensed(fontSize: 16)),
                // Add more Text widgets for additional instructions
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
