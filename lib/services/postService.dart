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
        'timestamp' : Timestamp.fromDate(DateTime.now())
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
  final userRef = _firestore.collection('User').doc(uid);
  final postRef = _firestore.collection('post');
  final currentUserUid = _firebaseAuth.currentUser!.uid;

  // ดึงข้อมูล user profile
  final userSnap = await userRef.get();
  final isCloseFriend = (userSnap.data()?['closefriend'] ?? []).contains(currentUserUid);

  Query query;

  if (currentUserUid == uid) {
    // 🔵 เป็นเจ้าของโพสต์ → เห็นทุกโพสต์
    query = postRef
        .where('ownerId', isEqualTo: uid)
        .where('isPrivate', whereIn: [true, false])
        .orderBy('timestamp', descending: true);
  } else if (isCloseFriend) {
    // 🟢 เป็น close friend → เห็นทั้ง public + private
    // ต้องสร้าง index สำหรับ: ownerId == xxx, isPrivate in [true, false], orderBy timestamp
    query = postRef
        .where('ownerId', isEqualTo: uid)
        .where('isPrivate', whereIn: [true, false])
        .orderBy('timestamp', descending: true);
  } else {
    // 🔴 คนทั่วไป → เห็นแค่ public
    // ต้องสร้าง index: ownerId == xxx, isPrivate == false, orderBy timestamp
    query = postRef
        .where('ownerId', isEqualTo: uid)
        .where('isPrivate', isEqualTo: false)
        .orderBy('timestamp', descending: true);
  }

  try {
    final querySnapshot = await query.get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  } catch (e) {
    print("Error fetching posts: $e");
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchFollowingPosts() async {
  final currentUser = _firebaseAuth.currentUser;
  if (currentUser == null) return [];

  try {
    // ดึง list following ของ current user
    final userSnapshot = await _firestore.collection('User').doc(currentUser.uid).get();
    final following = List<String>.from(userSnapshot.data()?['following'] ?? []);

    // รวมตัวเองไว้ด้วย (กรณีอยากเห็นโพสต์ตัวเองใน feed)
    following.add(currentUser.uid);

    // ดึงโพสต์ของทุกคนพร้อมกัน
    final futures = following.map((uid) => fetchUserPosts(uid));
    final results = await Future.wait(futures);

    // รวมโพสต์ทั้งหมด
    List<Map<String, dynamic>> allPosts = results.expand((postList) => postList).toList();

    // เรียงตาม timestamp ใหม่สุด → เก่าสุด
    allPosts.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

    return allPosts;
  } catch (e) {
    print("Error fetching following posts: $e");
    return [];
  }
}

}