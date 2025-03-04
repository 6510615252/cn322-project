import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class UserService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  // ดึงข้อมูลผู้ใช้จาก Firestore ตาม UID
  Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance.databaseId != null
        ? FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'dbmain',
          )
        : FirebaseFirestore.instance;

    try {
      DocumentSnapshot doc =
          await firestore.collection('User').doc(userId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print("⚠️ Document does not exist");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching data: $e");
      return null;
    }
  }
}
