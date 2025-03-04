import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:outstragram/auth.dart';
import 'package:outstragram/userService.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class ProfilePage extends StatelessWidget {
  final String? uid;
  ProfilePage({super.key, this.uid});

  final User? currentuser = FirebaseAuth.instance.currentUser;
  final UserService userService = UserService();
  final FirebaseStorage storage = FirebaseStorage.instanceFor(
    app: Firebase.app(),
    bucket: 'gs://cn322-3a8fa.firebasestorage.app',
  );

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
                    await Auth().signOut();
                  },
                ),
              ]
            : [],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        // Fetch user data
        future: userService.fetchUserData(profileUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("User data not found"));
          }

          var userData = snapshot.data;

          final bool isMyProfile = profileUid == currentuser?.uid;
          final bool isFollowing =
              userData!['followers']?.contains(currentuser?.uid) ?? false;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<String>(
                      // Use FutureBuilder to fetch image URL
                      future: _getImageUrl(userData['user_pic']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 40,
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                NetworkImage('https://via.placeholder.com/150'),
                          );
                        }

                        // Show the image fetched from Firebase Storage
                        return CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(snapshot.data!),
                        );
                      },
                    ),
                    // ส่วนอื่นๆ ของข้อมูลผู้ใช้
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
                      child: CachedNetworkImage(
                        imageUrl: userData['post'][index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
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

  // Fetch image URL from Firebase Storage
  Future<String> _getImageUrl(String imagePath) async {
    try {
      if (imagePath.isEmpty) {
        return 'https://via.placeholder.com/150';
      }

      final storageReference = storage.ref().child(imagePath);
      final imageUrl = await storageReference.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Error fetching image: $e');
      return 'https://via.placeholder.com/150'; // Use placeholder image
    }
  }

  void _toggleFollow(String profileUid, String currentUid) async {
    final firestore = FirebaseFirestore.instance;
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
