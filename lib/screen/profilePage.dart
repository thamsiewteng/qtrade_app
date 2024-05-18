import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qtrade_app/screen/loginPage.dart';

import '../widgets/customBottomNavigationBar.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? user;
  String? fullName;
  String? email;
  String? rank;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user!.uid).get();
      setState(() {
        fullName = userDoc['fullName'];
        email = userDoc['email'];
        rank = userDoc['rank'];
      });
    }
  }

  String _getProfileImagePath(String? rank) {
    switch (rank) {
      case 'novice':
        return 'assets/images/novice.png';
      case 'intermediate':
        return 'assets/images/intermediate.png';
      case 'advanced':
        return 'assets/images/advanced.png';
      case 'expert':
        return 'assets/images/expert.png';
      case 'master':
        return 'assets/images/master.png';
      default:
        return 'assets/images/novice.png';
    }
  }

  void _logout() async {
    await _auth.signOut();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.robotoCondensed(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
        child: Column(
          children: [
            SizedBox(height: 30),
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(_getProfileImagePath(rank)),
            ),
            SizedBox(height: 20),
            Text(
              fullName ?? 'Full Name',
              style: GoogleFonts.robotoCondensed(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _buildProfileInfoRow(Icons.person, fullName ?? 'Full Name'),
                  _buildProfileInfoRow(Icons.email, email ?? 'Email Address'),
                  _buildProfileInfoRow(Icons.star, rank ?? 'Rank'),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Color.fromARGB(255, 230, 79, 68),
              ),
              child: Text(
                'Log Out',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 4, // Assuming ProfilePage is the fifth tab
        onTap: (index) {
          // Handle navigation bar tap
        },
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF0D0828)),
          SizedBox(width: 10),
          Text(
            info,
            style: GoogleFonts.robotoCondensed(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
