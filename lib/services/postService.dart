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
  String get currentUid => currentUser?.uid ?? '';

  // 🔹 ฟังก์ชันสำหรับแสดงภาพโพสต์จาก path
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

  // 🔹 ฟังก์ชันสำหรับอัปโหลดภาพโพสต์
  Future<String> uploadPostPic(
      Uint8List imageBytes, String fileName, bool isPrivate) async {
    if (isPrivate) {
      try {
        Reference ref = _firebaseStorage.ref('secret_post_pic/$fileName');
        await ref.putData(imageBytes);
        addPost(
            postId: fileName,
            picName: fileName,
            context: "",
            isPrivate: isPrivate);
        return await ref.getDownloadURL();
      } catch (e) {
        throw Exception("Upload failed: $e");
      }
    } else {
      try {
        Reference ref = _firebaseStorage.ref('post_pic/$fileName');
        await ref.putData(imageBytes);
        addPost(
            postId: fileName,
            picName: fileName,
            context: "",
            isPrivate: isPrivate);
        return await ref.getDownloadURL();
      } catch (e) {
        throw Exception("Upload failed: $e");
      }
    }
  }

  // 🔹 สร้างหรืออัปเดตข้อมูลผู้ใช้
  Future<void> updateUserPost({
    required String uId,
    required String postId,
    required bool isPrivate,
  }) async {
    try {
      if (isPrivate) {
        await _firestore.collection("usersecret").doc(uId).set({
          'post': FieldValue.arrayUnion([postId]), // เพิ่มข้อมูล
        }, SetOptions(merge: true)); // ใช้ merge เฉพาะฟิลด์
      } else {
        await _firestore.collection("user").doc(uId).set({
          'post': FieldValue.arrayUnion([postId]), // เพิ่มข้อมูล
        }, SetOptions(merge: true)); // ใช้ merge เฉพาะฟิลด์
      }
    } catch (e) {
      print("❌ Error updating current: $e");
      throw e;
    }
  }

  // 🔹 ฟังก์ชันสำหรับเพิ่มโพสต์ใหม่
  Future<void> addPost({
    required String postId,
    required String picName,
    required String context,
    required bool isPrivate,
  }) async {
    try {
      if (isPrivate) {
        await _firestore.collection("postsecret").doc(postId).set({
          'ownerId': currentUid,
          'pic': 'secret_post_pic/$picName',
          'context': context,
          'timestamp': Timestamp.fromDate(DateTime.now())
        }, SetOptions(merge: true));
      } else {
        await _firestore.collection("post").doc(postId).set({
          'ownerId': currentUid,
          'pic': 'post_pic/$picName',
          'context': context,
          'timestamp': Timestamp.fromDate(DateTime.now())
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("❌ Error updating current: $e");
      throw e;
    }
  }

  // 🔹 ฟังก์ชันสำหรับดึงข้อมูลโพสต์
  Future<Map<String, dynamic>?> fetchPostData(
      String postId, bool isPrivate) async {
    try {
      DocumentSnapshot doc;
      if (isPrivate) {
        doc = await _firestore.collection('postsecret').doc(postId).get();
      } else {
        doc = await _firestore.collection('post').doc(postId).get();
      }
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
    final postRef = _firestore.collection('post');
    final postsecretRef = _firestore.collection('postsecret');

    try {
      final List<QuerySnapshot> snapshots = [];

      try {
        snapshots.add(await postRef.where('ownerId', isEqualTo: uid).get());
      } catch (e) {
        print("⚠️ Skip 'post' collection due to error: $e");
      }

      try {
        snapshots.add(await postsecretRef.where('ownerId', isEqualTo: uid).get());
      } catch (e) {
        print("⚠️ Skip 'secretpost' collection due to error: $e");
      }

      final posts = snapshots.expand((snapshot) =>
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>)
      ).toList();

      posts.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      return posts;
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFollowingPosts() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return [];

    try {
      final userSnapshot =
          await _firestore.collection('user').doc(currentUser.uid).get();
      final following =
          List<String>.from(userSnapshot.data()?['following'] ?? []);
      // เพิ่ม uid ของผู้ใช้ปัจจุบันในรายการโพสต์ที่จะแสดง
      following.add(currentUser.uid);

      final futures = following.map((uid) => fetchUserPosts(uid));
      final results = await Future.wait(futures);

      List<Map<String, dynamic>> post =
          results.expand((postList) => postList).toList();

      post.sort((a, b) =>
        (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      return post;
    } catch (e) {
      print("Error fetching following posts: $e");
      return [];
    }
  }
}
