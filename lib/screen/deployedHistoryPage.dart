import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qtrade_app/screen/deployedAlgoDetailsPage.dart';
import '../widgets/customBottomNavigationBar.dart';

class DeployedHistoryPage extends StatelessWidget {
  final String algoName;

  DeployedHistoryPage({required this.algoName});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting(); // Required for custom time zone
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black), // Added back button
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
        title: Text(
          'History',
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('deployed_algo')
              .where('deploy_algoName', isEqualTo: algoName)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No Deployments Found'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                var documentId =
                    snapshot.data!.docs[index].id; // Get the document ID here
                var date = (data['deploy_date'] as Timestamp).toDate();
                var formatter = DateFormat('yyyy-MM-dd h:mma');
                var timeZoneOffset = Duration(hours: 8); // Offset of UTC+8

                var formattedDate = formatter
                    .format(date.add(timeZoneOffset)); // Apply the offset

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DeployedAlgoDetailsPage(documentId: documentId),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Image.asset('assets/images/algorithmIcon.png'),
                      ),
                      title: Text(
                        data['deploy_algoName'] ?? 'No Name',
                        style: GoogleFonts.robotoCondensed(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        formatter.format(date),
                        style: GoogleFonts.robotoCondensed(
                          color: Colors.black54,
                        ),
                      ),
                      trailing: Text(
                        data['deploy_stockTicker'],
                        style: GoogleFonts.robotoCondensed(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2, // Assuming AlgorithmPage is the second tab
        onTap: (index) {
          // Handle navigation bar tap
        },
      ),
    );
  }
}
