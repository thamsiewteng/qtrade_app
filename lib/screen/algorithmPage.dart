import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qtrade_app/screen/algorithmDetailsPage.dart';
import '../widgets/customBottomNavigationBar.dart';

class AlgorithmPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF0D0828),
        elevation: 0,
        title: Text(
          'Algorithm',
          style: GoogleFonts.robotoCondensed(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('algorithm').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No Algorithms Found'));
            }

            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;
                return AlgorithmTile(
                  title: data['algo_name'],
                  description: data['algo_description'],
                  documentId: document.id,
                );
              }).toList(),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {},
      ),
    );
  }
}

class AlgorithmTile extends StatelessWidget {
  final String title;
  final String description;
  final String documentId;

  const AlgorithmTile({
    required this.title,
    required this.description,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlgorithmDetailsPage(
              documentId: documentId,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(8),
        color: Color(0xFFeeeef7),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Image.asset('assets/images/algorithmIcon.png'),
          ),
          title: Text(
            title,
            style: GoogleFonts.robotoCondensed(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            description,
            style: GoogleFonts.robotoCondensed(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
