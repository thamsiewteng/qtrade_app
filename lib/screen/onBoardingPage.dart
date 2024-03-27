import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qtrade_app/screen/loginPage.dart';
import 'package:qtrade_app/screen/signUpPage.dart';

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text('Create account',
                  style: GoogleFonts.robotoCondensed(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 40),
                backgroundColor: Color(0xFF0D1545),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Text('Login', style: GoogleFonts.robotoCondensed()),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
