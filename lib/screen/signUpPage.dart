import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:qtrade_app/screen/homePage.dart';
import 'package:qtrade_app/screen/onBoardingPage.dart';
import '../services/firebaseAuthenticationService.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FirebaseAuthenticationService _authService =
      FirebaseAuthenticationService();

  Future<void> _signUp() async {
    final String fullName = _fullNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (password == confirmPassword && password.isNotEmpty) {
      try {
        await _authService.signUp(
          email: email,
          password: password,
          fullName: fullName,
        );
        // If the sign-up is successful, navigate to the next screen or display a success message.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        ); // Make sure you define the '/home' route in your app
      } catch (e) {
        // If there is an error, show a dialog with the error message
        _showErrorDialog(e.toString());
      }
    } else {
      _showErrorDialog('Passwords do not match or fields are empty.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Full name'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email address'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm Password'),
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
                onPressed: _signUp,
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
                  // TODO: Implement Google sign-up logic
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OnboardingPage()),
                  );
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
