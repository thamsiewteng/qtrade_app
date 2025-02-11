import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qtrade_app/screen/deployedAlgoDetailsPage.dart';
import '../widgets/customBottomNavigationBar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeployedHistoryPage extends StatelessWidget {
  final String algoName;

  DeployedHistoryPage({required this.algoName});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('No user found')),
      );
    }

    final String userId = user.uid;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        backgroundColor: Color(0xFF0D0828),
        elevation: 0,
        title: Text(
          'History',
          style: GoogleFonts.robotoCondensed(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (userSnapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return Center(child: Text('No Deployments Found'));
            }

            var userDoc = userSnapshot.data!;
            var deployedAlgoRefs =
                userDoc['deploy_algoID'] as List<dynamic>? ?? [];

            if (deployedAlgoRefs.isEmpty) {
              return Center(child: Text('No Deployments Found'));
            }

            return FutureBuilder<List<DocumentSnapshot>>(
              future: Future.wait(deployedAlgoRefs
                  .map((ref) => (ref as DocumentReference).get())),
              builder: (context, algoSnapshots) {
                if (algoSnapshots.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (algoSnapshots.hasError) {
                  return Center(child: Text('Something went wrong'));
                }
                if (!algoSnapshots.hasData || algoSnapshots.data!.isEmpty) {
                  return Center(child: Text('No Deployments Found'));
                }

                var algoDocs = algoSnapshots.data!
                    .where((doc) =>
                        (doc.data()
                            as Map<String, dynamic>)['deploy_algoName'] ==
                        algoName)
                    .toList();

                if (algoDocs.isEmpty) {
                  return Center(child: Text('No Deployments Found'));
                }

                return ListView.builder(
                  itemCount: algoDocs.length,
                  itemBuilder: (context, index) {
                    var data = algoDocs[index].data() as Map<String, dynamic>;
                    var documentId = algoDocs[index].id;
                    var date = (data['deploy_date'] as Timestamp).toDate();
                    var formatter = DateFormat('yyyy-MM-dd h:mma');
                    var timeZoneOffset = Duration(hours: 0);

                    var formattedDate =
                        formatter.format(date.add(timeZoneOffset));

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
                            child:
                                Image.asset('assets/images/algorithmIcon.png'),
                          ),
                          title: Text(
                            data['deploy_algoName'] ?? 'No Name',
                            style: GoogleFonts.robotoCondensed(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            formattedDate,
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
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }
}
