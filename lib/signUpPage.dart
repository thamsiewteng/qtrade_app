import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Create an account', style: GoogleFonts.robotoCondensed()),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // Enable scrolling
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/signUpPage.png', height: 200),
              SizedBox(height: 16), // Reduced height to avoid overflow
              Text(
                'Invest smartly with zero risk.',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoCondensed(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 32),
              TextField(
                decoration: InputDecoration(labelText: 'Full name'),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(labelText: 'Email address'),
              ),
              SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 8),
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm Password'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D1545), // Button background color
                  foregroundColor: Colors.white, // Button text color
                  minimumSize: Size(double.infinity, 50), // Button size
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8), // Button border radius
                  ),
                ),
                onPressed: () {
                  // Implement sign-up logic
                },
                child: Text(
                  'Sign up',
                  style: GoogleFonts.robotoCondensed(fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: GoogleFonts.robotoCondensed()),
                  ),
                  Expanded(
                    child: Divider(thickness: 1),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SignInButton(
                Buttons.Google,
                text: "Sign up with Google",
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onPressed: () {
                  // Implement Google sign-up logic
                },
              ),
              SizedBox(height: 16), // Add space before the login prompt
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: Text(
                  'Already have an account? Login',
                  style: GoogleFonts.robotoCondensed(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
