import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/customBottomNavigationBar.dart';

class TradingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 188, 208, 225),
        elevation: 0,
        title: Text(
          'Trading',
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
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3, // Assuming AlgorithmPage is the second tab
        onTap: (index) {
          // Handle navigation bar tap
        },
      ),
    );
  }
}
