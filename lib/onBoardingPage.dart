import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qtrade_app/loginPage.dart';
import 'package:qtrade_app/signUpPage.dart';

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Spacer(),
          // Use an appropriate widget to load your image
          Image.asset('assets/images/onBoardingPage.png', height: 200),
          SizedBox(height: 24),
          Text(
            'Stay on top of your finance with us.',
            textAlign: TextAlign.center,
            style: GoogleFonts.robotoCondensed(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Master the markets with us and build your investing skills at your own pace.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.robotoCondensed(fontSize: 16, color: Colors.grey),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add create account action
                // When you need to navigate to the sign-up page, you can use:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text('Create account',
                  style: GoogleFonts.robotoCondensed(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 40), // set the size
                backgroundColor: Color(0xFF0D1545), // background (button) color
                foregroundColor: Colors.white, // foreground (text) color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Add login action
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Login', style: GoogleFonts.robotoCondensed()),
          ),
          SizedBox(height: 30), // add some space at the bottom
        ],
      ),
    );
  }
}
