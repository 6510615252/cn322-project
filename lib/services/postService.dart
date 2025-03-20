import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class PostService {
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
  String get profileUid => currentUser?.uid ?? '';

  Future<Widget> displayPostPic(String postPicPath) async {
    try {
      // Fetch the image URL from Firebase Storage using the given path
      String downloadUrl =
          await FirebaseStorage.instance.ref(postPicPath).getDownloadURL();

      // Display the image using the fetched URL
      return Image.network(downloadUrl);
    } catch (e) {
      print("❌ Error loading image: $e");
      // Return a default image if there was an error
      return Image.asset('assets/default_posts_pic.png');
    }
  }

  // ฟังก์ชันสำหรับอัปโหลดรูปภาพ
  Future<String> uploadPostPic(Uint8List imageBytes, String fileName) async {
    try {
      Reference ref = _firebaseStorage.ref('posts_pic/$fileName');
      await ref.putData(imageBytes);
      addPost(postId: fileName, isPrivate : false, picPath: 'posts_pic/$fileName', context: "");
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  // 🔹 สร้างหรืออัปเดตข้อมูลผู้ใช้
  Future<void> updateUserPost({
    required String uId,
    required String postId,
  }) async {
    try {
      // add post id to array 'post'
      await _firestore.collection("User").doc(uId).set({
        'post': FieldValue.arrayUnion([postId]), // ใช้ FieldValue.arrayUnion เพื่อเพิ่มข้อมูลเข้าไปใน array
      }, SetOptions(merge: true)); // ใช้ merge เพื่ออัปเดตเฉพาะฟิลด์ที่ส่งมา
    } catch (e) {
      print("❌ Error updating profile: $e");
      throw e;
    }
  }

  // 🔹 สร้างหรืออัปเดตข้อมูลผู้ใช้
  Future<void> addPost({
    required String postId,
    required bool isPrivate,
    required String picPath,
    required String context,
  }) async {
    try {
      // add post id to array 'post'
      await _firestore.collection("post").doc(postId).set({
        'ownerId' : profileUid,
        'pic' : picPath,
        'isPrivate' : isPrivate,
        'context' : context,
      }, SetOptions(merge: true)); 
    } catch (e) {
      print("❌ Error updating profile: $e");
      throw e;
    }
  }

  // ตรวจสอบว่ามีข้อมูลผู้ใช้นี้ใน Firestore หรือไม่
  Future<bool> checkPostExists(String postId) async {
    DocumentSnapshot postDoc =
        await _firestore.collection("post").doc(postId).get();
    return postDoc.exists;
  }

  // ดึงข้อมูลผู้ใช้จาก Firestore
  Future<Map<String, dynamic>?> fetchPostData(String postId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('post').doc(postId).get();

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

  Future<List<Map<String, dynamic>>> fetchUserPosts(String uid) async {
    final postSnapshot = await _firestore
        .collection('post')
        .where('ownerId', isEqualTo: uid)
        .get();

    return postSnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> fetchFollowingPosts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final userSnapshot = await _firestore.collection('User').doc(currentUser.uid).get();
    final following = List<String>.from(userSnapshot['following'] ?? []);

    List<Map<String, dynamic>> allPosts = [];

    for (String uid in following) {
      final posts = await fetchUserPosts(uid);
      allPosts.addAll(posts);
    }

    return allPosts;
  }
}
