import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:qtrade_app/screen/homePage.dart';
import 'package:qtrade_app/screen/signUpPage.dart';

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _loginWithEmail(BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => HomePage(), // Replace with your home page
      ));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    }
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomePage(), // Replace with your home page
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to sign in with Google: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black),
        elevation: 0,
        title: Text('Login', style: GoogleFonts.roboto(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/images/signUpPage.png', height: 200),
            SizedBox(height: 16),
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
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Email address'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: InkWell(
                  onTap: () {
                    // TODO: Implement forgot password feature
                  },
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.roboto(color: Colors.blue),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loginWithEmail(context),
              child: Text('Login',
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D1545),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: SignInButton(
                Buttons.Google,
                text: "Sign in with Google",
                onPressed: () => _loginWithGoogle(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(0),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text(
                "Don't have an account? Sign Up",
                style: GoogleFonts.roboto(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
