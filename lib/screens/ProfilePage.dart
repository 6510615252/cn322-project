import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

class ProfilePage extends StatelessWidget {
  final String? uid;
  ProfilePage({super.key, this.uid});

  final User? currentuser = FirebaseAuth.instance.currentUser;
  final UserService userService = UserService();
  final PostService postService = PostService();

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

          var userData = snapshot.data ?? {};
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
          );
        },
      ),
    );
  }
}