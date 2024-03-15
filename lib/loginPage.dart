import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Login', style: GoogleFonts.robotoCondensed()),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('assets/images/loginPage.png', height: 200),
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
              decoration: InputDecoration(labelText: 'Email address'),
            ),
            SizedBox(height: 8),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password logic
                },
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.robotoCondensed(),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D1545),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // TODO: Implement login logic
              },
              child: Text(
                'Login',
                style: GoogleFonts.robotoCondensed(fontSize: 20),
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
                  child: Text('or'),
                ),
                Expanded(
                  child: Divider(thickness: 1),
                ),
              ],
            ),
            SizedBox(height: 16),
            SignInButton(
              Buttons.Google,
              text: "Sign in with Google",
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onPressed: () {
                // TODO: Implement Google sign-in logic
              },
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to sign-up page
              },
              child: Text(
                "Don't have an account? Sign Up",
                style: GoogleFonts.robotoCondensed(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
