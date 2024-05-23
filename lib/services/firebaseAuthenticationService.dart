import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<User> signUp(
      {required String email,
      required String password,
      required String fullName}) async {
    UserCredential userCredential = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);
    User? user = userCredential.user;
    if (user != null) {
      // Optionally, update the user's profile with their full name
      await user.updateDisplayName(fullName);
      await user.reload();
      user = _firebaseAuth.currentUser;
    }
    return user!;
  }
}
