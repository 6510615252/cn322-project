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
  late final String profileUid;

  UserService() {
    profileUid = currentUser?.uid ?? '';
  }

  Future<bool> isUserFollowing(String profileUid, String currentUid) async {
    final currenUserData = await fetchUserData(currentUid);
    return currenUserData?['following']?.contains(profileUid) ?? false;
  }

  Future<void> toggleFollowUser(String profileUid, String currentUid) async {
    final userDoc = _firestore.collection('User').doc(profileUid);
    final currentUserDoc = _firestore.collection('User').doc(currentUid);

    // if userDoc private, TODO NA

    // if userDoc Public
    final currentUserData = await currentUserDoc.get();
    List followers = currentUserData.data()?['following'] ?? [];

    if (followers.contains(profileUid)) {
      followers.remove(profileUid);
    } else {
      followers.add(profileUid);
    }

    await currentUserDoc.update({'following': followers});
  }

  Future<void> searchUsers(
      String query, Function(List<Map<String, dynamic>>) updateResults) async {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      updateResults([]); // หาก query ว่าง ให้เคลียร์ผลลัพธ์
      return;
    }

    final querySnapshot = await _firestore
        .collection("User")
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    List<Map<String, dynamic>> results = querySnapshot.docs.map((doc) {
      var data = doc.data();
      data['uid'] = doc.id; // เพิ่ม UID ของ user ลงใน map
      return data;
    }).toList();

    updateResults(results); // ส่งค่าผลลัพธ์กลับไปยัง SearchPage
  }

  Future<String> getUserNameByUid(String uid) async {
    try {
      // ดึงข้อมูลจาก collection "User" โดยใช้ uid ของผู้โพสต์
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(uid).get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown'; // ถ้าไม่พบ name ให้แสดง 'Unknown'
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown';
    }
  }

  Future<String> getUserBioByUid(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(uid).get();
      return userDoc['bio'] ??
          'No bio available'; // ถ้าไม่มี bio ให้แสดงข้อความเริ่มต้น
    } catch (e) {
      return 'No bio available'; // กัน error
    }
  }

  // ✅ ฟังก์ชันใหม่สำหรับดึง Widget แสดงรูปโปรไฟล์จาก UID
  Future<Widget> displayUserProfileImage(String uid, {double radius = 20}) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(uid).get();
      String? userPicPath = userDoc['user_pic'];
      String downloadUrl = await _firebaseStorage.ref(userPicPath).getDownloadURL();
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(downloadUrl),
        backgroundColor: Colors.grey.shade300, // สีพื้นหลังเผื่อโหลดไม่สำเร็จ
      );
    } catch (e) {
      print("❌ Error loading profile image for UID $uid: $e");
      return CircleAvatar(
        radius: radius,
        backgroundImage:
            const AssetImage('assets/images/default_profile.jpg'), // ใช้รูป default
        backgroundColor: Colors.grey.shade300,
      );
    }
  }

  // ฟังก์ชันสำหรับอัปโหลดรูปภาพ
  Future<String> uploadProfilePic(Uint8List imageBytes, String fileName) async {
    try {
      Reference ref = _firebaseStorage.ref('user_pic/$fileName');
      await ref.putData(imageBytes);
      saveUserPic(profileUid, 'user_pic/$fileName');
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  // 🔹 สร้างหรืออัปเดตข้อมูลผู้ใช้
  Future<void> updateUserNameAndBio({
    required String uid,
    required String name,
    required String bio,
  }) async {
    try {
      await _firestore.collection("User").doc(uid).set({
        'name': name.toLowerCase().trim(),
        'bio': bio.trim(),
      }, SetOptions(merge: true)); // ✅ ใช้ merge เพื่ออัปเดตเฉพาะฟิลด์ที่ส่งมา
    } catch (e) {
      print("❌ Error updating profile: $e");
      throw e;
    }
  }

  // ฟังก์ชันเพื่อบันทึก path รูปใน Firestore
  Future<void> saveUserPic(String userId, String filePath) async {
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
      'name': username.toLowerCase().trim(),
      'closefriend': [],
      'following': [],
      'post': [],
      'user_pic': userPic ?? "user_pic/UserPicDef.jpg"
    });
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
          'user_pic': "user_pic/UserPicDef.jpg",
          'bio': "",
        });
      }
    } catch (e) {
      print("❌ Error saving user data: $e");
    }
  }

  Future<int> countVisiblePosts(String uid) async {
    final userRef = _firestore.collection('User').doc(uid);
    final postRef = _firestore.collection('post');

    final userSnap = await userRef.get();
    final currentUserUid = _firebaseAuth.currentUser!.uid;

    final bool isCloseFriend =
        (userSnap.data()?['closefriend'] ?? []).contains(currentUserUid);

    Query query = postRef.where('ownerId', isEqualTo: uid);

    if (currentUserUid == uid || isCloseFriend) {
      query = query.where('isPrivate', whereIn: [true, false]);
    } else {
      query = query.where('isPrivate', isEqualTo: false);
    }

    final AggregateQuerySnapshot snapshot = await query.count().get();
    final postCount = snapshot.count;

    return Future.value(postCount);
  }

  Future<List<String>> getCloseFriends(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(uid).get();

      List<String> closeFriendsUid =
          List<String>.from(userDoc['closefriend'] ?? []);

      List<String> closeFriendsNames = [];
      for (String closeFriendUid in closeFriendsUid) {
        String name = await getUserNameByUid(closeFriendUid);
        closeFriendsNames.add(name);
      }

      return closeFriendsNames;
    } catch (e) {
      print("Error fetching close friends names: $e");
      return [];
    }
  }

  Future<List<String>> getCloseFriendsUid(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(uid).get();

      List<String> closeFriendsUid =
          List<String>.from(userDoc['closefriend'] ?? []);

      return closeFriendsUid;
    } catch (e) {
      print("Error fetching close friends uid: $e");
      return [];
    }
  }

  Future<List<String>> getNotCloseFriendsUser(String uid) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('User').get();

      List<String> closeFriendUids = await getCloseFriendsUid(uid);

      List<String> allUserNames = [];

      for (var doc in snapshot.docs) {
        String userId = doc.id;
        if (userId != uid && !closeFriendUids.contains(userId)) {
          String userName = await getUserNameByUid(userId);
          allUserNames.add(userName);
        }
      }

      return allUserNames;
    } catch (e) {
      throw Exception("Error getting all users: $e");
    }
  }

  Future<void> addCloseFriends(
      String uid, List<String> selectedUserNames) async {
    try {
      DocumentReference userRef = _firestore.collection('User').doc(uid);

      List<String> selectedUserUids = [];

      for (String name in selectedUserNames) {
        QuerySnapshot snapshot = await _firestore
            .collection('User')
            .where('name', isEqualTo: name)
            .get();

        if (snapshot.docs.isNotEmpty) {
          String selectedUid = snapshot.docs.first.id;
          selectedUserUids.add(selectedUid);
        }
      }

      await userRef.update({
        'closefriend': FieldValue.arrayUnion(selectedUserUids),
      });
    } catch (e) {
      throw Exception("Error adding close friends: $e");
    }
  }

  Future<void> updateBio(String uid, String newBio) async {
    try {
      // บันทึก path ของรูปภาพลงใน Firestore
      await _firestore.collection("User").doc(uid).update({
        'bio': newBio,
      });
    } catch (e) {
      print("❌ Error saving image path to Firestore: $e");
      throw e;
    }
  }

  //ฟังก์ชั่นดึงรายชื่อคนที่เราคิดตามอยู่
  Future<List<String>> getFollowingUsers(currentUserUid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('User').doc(currentUserUid).get();

      if (userDoc.exists) {
        List<dynamic> followingList = userDoc['following'] ?? [];

        List<String> followingNames = [];

        for (String uid in followingList) {
          String userName = await getUserNameByUid(uid);
          followingNames.add(userName);
        }

        return followingNames;
      } else {
        return [];
      }
    } catch (e) {
      print("Error getting following users with names: $e");
      return [];
    }
  }
  Future<Widget> displayUserProfilePic(String userPicPath) async {
    try {
      // Fetch the image URL from Firebase Storage using the given path
      String downloadUrl =
          await FirebaseStorage.instance.ref(userPicPath).getDownloadURL();

      // Display the image using the fetched URL
      return Image.network(
        downloadUrl,
        fit: BoxFit.cover,
      );
    } catch (e) {
      print("❌ Error loading image: $e");
      // Return a default image if there was an error
      return Image.asset(
        'assets/images/default_profile.jpg', // เปลี่ยน path ตามที่คุณมี
        fit: BoxFit.cover,
      );
    }
  }
}