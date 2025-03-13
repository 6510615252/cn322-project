import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:outstragram/services/userService.dart';

class Authservice {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService(); // 💡 ใช้ UserService

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // 🔹 Sign In with Email & Password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 🔹 Register (สร้างบัญชีใหม่)
  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      await _userService.createUser(uid: uid, email: email); // 📌 บันทึกลง Firestore
      return uid;
    } catch (e) {
      print("❌ Error: $e");
      return null;
    }
  }

  // 🔹 Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      String uid = userCredential.user!.uid;
      String? email = userCredential.user?.email;

      await _userService.createUser(uid: uid, email: email); // 📌 บันทึกลง Firestore
      return userCredential;
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      return null;
    }
  }

  // 🔹 Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}