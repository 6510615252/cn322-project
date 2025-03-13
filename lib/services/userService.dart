import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UserService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance.databaseId != null
          ? FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'dbmain',
            )
          : FirebaseFirestore.instance;

  final FirebaseStorage _firebaseStorage = FirebaseStorage.instanceFor(
    app: Firebase.app(),
    bucket: 'gs://cn322-3a8fa.firebasestorage.app',
  );

  User? get currentUser => _firebaseAuth.currentUser;

  Future<Widget> displayUserProfilePic(String userPicPath) async {
  try {
    // Fetch the image URL from Firebase Storage using the given path
    String downloadUrl = await FirebaseStorage.instance
        .ref(userPicPath)
        .getDownloadURL();

    // Display the image using the fetched URL
    return Image.network(downloadUrl);
  } catch (e) {
    print("❌ Error loading image: $e");
    // Return a default image if there was an error
    return Image.asset('assets/default_profile_pic.png');
  }
}


  // ฟังก์ชันสำหรับอัปโหลดรูปภาพ
  Future<String> uploadProfilePic(Uint8List imageBytes, String fileName) async {
    try {
      // สร้าง Reference สำหรับ Firebase Storage
      Reference storageRef = _firebaseStorage.ref().child('user_pic/$fileName');

      // อัปโหลดไฟล์ไปยัง Firebase Storage
      UploadTask uploadTask = storageRef.putData(imageBytes);

      // รอการอัปโหลดเสร็จสิ้น
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

      // ดึง URL ของไฟล์ที่อัปโหลดสำเร็จ
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL; // ส่ง URL ของไฟล์ที่อัปโหลด
    } catch (e) {
      print("❌ Error uploading image: $e");
      throw e;
    }
  }

  // ฟังก์ชันเพื่อบันทึก path รูปใน Firestore
  Future<void> saveUserProfilePicToFirestore(
      String userId, String filePath) async {
    try {
      // บันทึก path ของรูปภาพลงใน Firestore
      await _firestore.collection("User").doc(userId).update({
        'user_pic': filePath,
      });
    } catch (e) {
      print("❌ Error saving image path to Firestore: $e");
      throw e;
    }
  }

  // ฟังก์ชันนี้ใช้เพื่ออัปโหลดและบันทึกข้อมูล
  Future<void> uploadAndSaveUserProfilePic(
      Uint8List imageBytes, String userId, String fileName) async {
    try {
      // อัปโหลดรูปภาพไปยัง Firebase Storage และรับ URL
      String filePath = await uploadProfilePic(imageBytes, fileName);

      // บันทึก URL หรือ path ของรูปภาพลงใน Firestore
      await saveUserProfilePicToFirestore(userId, filePath);

      print("✔️ Image uploaded and saved successfully!");
    } catch (e) {
      print("❌ Error uploading and saving profile pic: $e");
    }
  }

  // ตรวจสอบว่ามีข้อมูลผู้ใช้นี้ใน Firestore หรือไม่
  Future<bool> checkUserExists(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection("User").doc(userId).get();
    return userDoc.exists;
  }

  // บันทึกข้อมูลผู้ใช้ลง Firestore
  Future<void> saveUserData({
    required String userId,
    required String username,
    String? userPic,
  }) async {
    await _firestore.collection("User").doc(userId).set({
      'name': username,
      'closefriend': [],
      'following': [],
      'post': [],
      'user_pic': userPic ?? "user_pic/UserPicDef.jpg"
    });
  }

  // 🔹 สร้างหรืออัปเดตข้อมูลผู้ใช้
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String userPic,
  }) async {
    try {
      await _firestore.collection("User").doc(uid).set({
        'name': name,
        'user_pic': userPic.isNotEmpty ? userPic : "gs://default_profile.png",
      }, SetOptions(merge: true)); // ✅ ใช้ merge เพื่ออัปเดตเฉพาะฟิลด์ที่ส่งมา
    } catch (e) {
      print("❌ Error updating profile: $e");
      throw e;
    }
  }

  // ดึงข้อมูลผู้ใช้จาก Firestore
  Future<Map<String, dynamic>?> fetchUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('User').doc(userId).get();

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

  Future<void> createUser({required String uid, String? email}) async {
    try {
      DocumentReference userRef = _firestore.collection("User").doc(uid);

      DocumentSnapshot userDoc = await userRef.get();
      if (!userDoc.exists) {
        await userRef.set({
          'name': "Unknown User",
          'email': email ?? "No email",
          'uid': uid,
          'following': [],
          'closefriend': [],
          'post': [],
          'user_pic': "user_pic/UserPicDef.jpg"
        });
      }
    } catch (e) {
      print("❌ Error saving user data: $e");
    }
  }
}
