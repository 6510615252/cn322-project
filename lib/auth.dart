import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username, // เพิ่ม username
  }) async {
    UserCredential userCredential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // บันทึกข้อมูลลง Firestore
    FirebaseFirestore firestore = FirebaseFirestore.instance.databaseId != null
        ? FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'dbmain',
          )
        : FirebaseFirestore.instance;
    await firestore.collection("User").doc(userCredential.user!.uid).set({
      'name': username,
      'closefriend': [], // Array ว่างเปล่า
      'following': [], // Array ว่างเปล่า
      'post': [],
      'user_pic':
          "gs://cn322-3a8fa.firebasestorage.app/user_pic/image_2025-03-04_001450883.png"
    });
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(
        credential
      );
      FirebaseFirestore firestore =
          FirebaseFirestore.instance.databaseId != null
              ? FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: 'dbmain',
                )
              : FirebaseFirestore.instance;
      await firestore.collection("User").doc(userCredential.user!.uid).set({
        'name': userCredential.user?.displayName ?? 'Unknow User',
        'closefriend': [], // Array ว่างเปล่า
        'following': [], // Array ว่างเปล่า
        'post': [],
        'user_pic':
            "gs://cn322-3a8fa.firebasestorage.app/user_pic/image_2025-03-04_001450883.png"
      });
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }
}
