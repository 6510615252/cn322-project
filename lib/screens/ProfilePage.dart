import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/services/userService.dart';

class ProfilePage extends StatelessWidget {
  final String? uid;
  ProfilePage({super.key, this.uid});

  final User? currentuser = FirebaseAuth.instance.currentUser;
  final UserService userService = UserService();

  @override
  Widget build(BuildContext context) {
    final String profileUid = uid ?? currentuser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: uid == null
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ]
            : [],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userService.fetchUserData(profileUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("User data not found"));
          }

          var userData =
              snapshot.data ?? {}; // Use an empty map in case of null data
          final bool isMyProfile = profileUid == currentuser?.uid;
          final bool isFollowing =
              userData['followers']?.contains(currentuser?.uid) ?? false;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<Widget>(
                      future: userService.displayUserProfilePic(
                          userData['user_pic'] ?? "user_pic/UserPicDef.jpg"),
                      builder: (context, profilePicSnapshot) {
                        if (profilePicSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 40,
                            child: CircularProgressIndicator(),
                          );
                        }

                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          child: ClipOval(child: profilePicSnapshot.data),
                        );
                      },
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
              if (!isMyProfile)
                ElevatedButton(
                  onPressed: () => _toggleFollow(profileUid, currentuser!.uid),
                  child: Text(isFollowing ? "Unfollow" : "Follow"),
                ),
            ],
          );
        },
      ),
    );
  }

  void _toggleFollow(String profileUid, String currentUid) async {
    final FirebaseFirestore firestore =
        FirebaseFirestore.instance.databaseId != null
            ? FirebaseFirestore.instanceFor(
                app: Firebase.app(),
                databaseId: 'dbmain',
              )
            : FirebaseFirestore.instance;
    final userRef = firestore.collection("User").doc(profileUid);
    final currentUserRef = firestore.collection("User").doc(currentUid);

    var userDoc = await userRef.get();
    var currentUserDoc = await currentUserRef.get();

    if (!userDoc.exists || !currentUserDoc.exists) return;

    List followers = userDoc['followers'] ?? [];
    List following = currentUserDoc['following'] ?? [];

    if (followers.contains(currentUid)) {
      userRef.update({
        'followers': FieldValue.arrayRemove([currentUid])
      });
      currentUserRef.update({
        'following': FieldValue.arrayRemove([profileUid])
      });
    } else {
      userRef.update({
        'followers': FieldValue.arrayUnion([currentUid])
      });
      currentUserRef.update({
        'following': FieldValue.arrayUnion([profileUid])
      });
    }
  }
}
