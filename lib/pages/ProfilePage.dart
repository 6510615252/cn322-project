import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/auth.dart';


class ProfilePage extends StatelessWidget {
  final String? uid;
  ProfilePage({super.key, this.uid});

  final FirebaseFirestore firestore = FirebaseFirestore.instance.databaseId != null
      ? FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'dbmain',
        )
      : FirebaseFirestore.instance;

  final User? currentuser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final String profileUid = uid ?? currentuser?.uid ?? ''; // ใช้ uid ของ currentUser ถ้าไม่มีการส่งค่า

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: uid == null
            ? [ // แสดงปุ่ม Logout เฉพาะเมื่อดูโปรไฟล์ตัวเอง
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await Auth().signOut();
                  },
                ),
              ]
            : [],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection("User").doc(profileUid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null) {
            return const Center(child: Text("User data not found"));
          }

          final bool isMyProfile = profileUid == currentuser?.uid;
          final bool isFollowing = userData['followers']?.contains(currentuser?.uid) ?? false;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                          userData['user_pic'] ?? 'https://via.placeholder.com/150'),
                    ),
                    Column(
                      children: [
                        Text('${userData['post']?.length ?? 0}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('Posts'),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${userData['followers']?.length ?? 0}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('Followers'),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${userData['following']?.length ?? 0}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('Following'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData['name'] ?? 'No Name',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(userData['bio'] ?? 'No bio available'),
                  ],
                ),
              ),
              if (!isMyProfile) // แสดงปุ่ม Follow/Unfollow เฉพาะเมื่อดูโปรไฟล์คนอื่น
                ElevatedButton(
                  onPressed: () => _toggleFollow(profileUid, currentuser!.uid),
                  child: Text(isFollowing ? "Unfollow" : "Follow"),
                ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: userData['post']?.length ?? 0,
                  itemBuilder: (context, index) {
                    return Container(
                      color: Colors.grey[300],
                      child: Image.network(
                        userData['post'][index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }

  void _toggleFollow(String profileUid, String currentUid) async {
    final userRef = firestore.collection("User").doc(profileUid);
    final currentUserRef = firestore.collection("User").doc(currentUid);

    var userDoc = await userRef.get();
    var currentUserDoc = await currentUserRef.get();

    if (!userDoc.exists || !currentUserDoc.exists) return;

    List followers = userDoc['followers'] ?? [];
    List following = currentUserDoc['following'] ?? [];

    if (followers.contains(currentUid)) {
      // Unfollow
      userRef.update({
        'followers': FieldValue.arrayRemove([currentUid])
      });
      currentUserRef.update({
        'following': FieldValue.arrayRemove([profileUid])
      });
    } else {
      // Follow
      userRef.update({
        'followers': FieldValue.arrayUnion([currentUid])
      });
      currentUserRef.update({
        'following': FieldValue.arrayUnion([profileUid])
      });
    }
  }
}