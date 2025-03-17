import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

class ProfilePage extends StatefulWidget {
  final String? uid;
  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService userService = UserService();
  final PostService postService = PostService();

  late String profileUid;
  bool isFollowing = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    profileUid = widget.uid ?? currentUser?.uid ?? '';
    fetchUserData();
  }

    Future<void> fetchUserData() async {
    final data = await userService.fetchUserData(profileUid);
    if (data != null) {
      setState(() {
        userData = data;
      });
      checkFollowingStatus();
    }
  }

  Future<void> checkFollowingStatus() async {
    bool following = await userService.isUserFollowing(profileUid, currentUser!.uid);
    setState(() {
      isFollowing = following;
    });
  }

  Future<void> toggleFollow() async {
    await userService.toggleFollowUser(profileUid, currentUser!.uid);
    checkFollowingStatus();
  }


  @override
  Widget build(BuildContext context) {
    final bool isMyProfile = profileUid == currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: isMyProfile
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
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder<Widget>(
                        future: userService.displayUserProfilePic(
                            userData!['user_pic'] ?? "user_pic/UserPicDef.jpg"),
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
                          Text('${userData!['post']?.length ?? 0}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const Text('Posts'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('${userData!['followers']?.length ?? 0}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const Text('Followers'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('${userData!['following']?.length ?? 0}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const Text('Following'),
                        ],
                      ),
                    ],
                  ),
                ),
                // ➜ แสดง Bio ของโปรไฟล์ที่เปิดอยู่
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      userData!['bio'] ?? "No bio available",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ➜ ปุ่ม Follow/Unfollow (ถ้าไม่ใช่โปรไฟล์ตัวเอง)
                if (!isMyProfile)
                  ElevatedButton(
                    onPressed: toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.red : Colors.blue,
                    ),
                    child: Text(
                      isFollowing ? "Unfollow" : "Follow",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: postService.fetchUserPosts(profileUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No posts available"));
                      }

                      final posts = snapshot.data!;

                      return GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postPicPath = posts[index]['pic'];

                          return FutureBuilder<Widget>(
                            future: postService.displayPostPic(postPicPath),
                            builder: (context, postPicSnapshot) {
                              if (postPicSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              return postPicSnapshot.data ?? Container();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}