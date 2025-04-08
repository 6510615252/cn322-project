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
  bool isEditingBio = false;
  final TextEditingController bioController = TextEditingController();

  late String profileUid;
  bool isFollowing = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    profileUid = widget.uid ?? currentUser?.uid ?? '';
    fetchUserData();
  }

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
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
    bool following =
        await userService.isUserFollowing(profileUid, currentUser!.uid);
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
        title: Text(userData?['name'] ?? "Profile"),
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
                    children: [
                      // รูปโปรไฟล์อยู่ด้านซ้าย
                      FutureBuilder<Widget>(
                        future: userService.displayUserProfilePic(
                            userData?['user_pic'] ?? "user_pic/UserPicDef.jpg"),
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
                            child: ClipOval(
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: profilePicSnapshot.data,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                          width: 20), // ระยะห่างระหว่างรูปโปรไฟล์กับข้อมูล

                      // ข้อมูล Posts และ Following อยู่ใน Row
                      Row(
                        children: [
                          Column(
                            children: [
                              // Posts
                              FutureBuilder<int>(
                                future:
                                    userService.countVisiblePosts(profileUid),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('Loading...');
                                  } else if (snapshot.hasError) {
                                    return const Text('Error');
                                  } else {
                                    return Text(
                                      '${snapshot.data ?? 0}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18), // เพิ่มขนาดตัวอักษร
                                    );
                                  }
                                },
                              ),
                              const Text('Posts',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(
                              width: 20), // ระยะห่างระหว่าง Posts และ Following

                          Column(
                            children: [
                              // Following
                              Text('${userData?['following']?.length ?? 0}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)), // เพิ่มขนาดตัวอักษร
                              const Text('Following',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: isEditingBio
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: bioController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText: "Enter your bio",
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await userService.updateBio(
                                      currentUser!.uid, bioController.text);
                                  await fetchUserData();
                                  setState(() {
                                    isEditingBio = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Bio updated successfully")),
                                  );
                                },
                                child: const Text("Save"),
                              )
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  userData?['bio'] ?? "No bio available",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              if (isMyProfile)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      isEditingBio = true;
                                      bioController.text =
                                          userData?['bio'] ?? '';
                                    });
                                  },
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
