import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:outstragram/widget_tree.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> testFirestoreCRUD() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance.databaseId != null
      ? FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'dbmain',
        )
      : FirebaseFirestore.instance;

  String testDocId = 'testUser123';
  // 1️⃣ สร้างข้อมูล (Create)
  try {
    await firestore.collection('User').doc(testDocId).set({
      'name': 'Test User',
      'user_pic': '/collection/test_user_pic',
      'closefriend': ['userX'],
      'following': ['userY'],
      'post': ['testPost123'],
    });
    print("✅ [CREATE] Document created successfully!");
  } catch (e) {
    print("❌ [CREATE] Error: $e");
  }

  // 2️⃣ อ่านข้อมูล (Read)
  try {
    DocumentSnapshot doc = await firestore.collection('User').doc(testDocId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      print("🔥 [READ] Name: ${data['name']}");
      print("🔥 [READ] User Pic: ${data['user_pic']}");
      print("🔥 [READ] Close Friends: ${data['closefriend']}");
      print("🔥 [READ] Following: ${data['following']}");
      print("🔥 [READ] Posts: ${data['post']}");
    } else {
      print("⚠️ [READ] Document does not exist");
    }
  } catch (e) {
    print("❌ [READ] Error: $e");
  }

  // 3️⃣ อัปเดตข้อมูล (Update)
  try {
    await firestore.collection('User').doc(testDocId).update({
      'name': 'Updated Test User',
      'following': FieldValue.arrayUnion(['newFollower']),
    });
    print("✅ [UPDATE] Document updated successfully!");
  } catch (e) {
    print("❌ [UPDATE] Error: $e");
  }

  // 4️⃣ ลบข้อมูล (Delete)
  try {
    await firestore.collection('User').doc(testDocId).delete();
    print("✅ [DELETE] Document deleted successfully!");
  } catch (e) {
    print("❌ [DELETE] Error: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
  testFirestoreCRUD();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const WidgetTree(),
    );
  }
}
