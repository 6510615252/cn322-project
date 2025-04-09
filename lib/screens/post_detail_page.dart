import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

class PostDetailPage extends StatelessWidget {
  final PostService postService = PostService();
  final UserService userService = UserService();
  final String postPicPath;
  final Map<String, dynamic> postData;

  var pUid;

  PostDetailPage({
    super.key,
    required this.postPicPath,
    required this.postData,
  });

  // ฟังก์ชันดึง user_pic จาก Firebase Storage
  Future<String> getPostUserPicPath() async {
    try {
      var data = await userService.fetchUserData(pUid);

      if (data != null && data['user_pic'] != null) {
        return data['user_pic'] as String;
      } else {
        return "";
      }
    } catch (e) {
      print("❌ Error fetching data: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    pUid = postData['ownerId'];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          // User Info (optional)
          ListTile(
            leading: FutureBuilder<String>(
              future: getPostUserPicPath(), // ดึง user_pic path
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    backgroundImage: AssetImage(
                        'assets/default_profile_pic.png'),
                  );
                } else if (snapshot.hasError) {
                  return const CircleAvatar(
                    backgroundImage: AssetImage(
                        'assets/default_profile_pic.png'),
                  );
                } else {
                  return FutureBuilder<Widget>(
                    future:
                        userService.displayUserProfilePic(snapshot.data ?? ""),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          backgroundImage: AssetImage(
                              'assets/default_profile_pic.png'), 
                        );
                      } else if (snapshot.hasError) {
                        return const CircleAvatar(
                          backgroundImage: AssetImage(
                              'assets/default_profile_pic.png'), 
                        );
                      } else {
                        return CircleAvatar(
                          backgroundImage: (snapshot.data as Image).image,
                        );
                      }
                    },
                  );
                }
              },
            ),
            title: FutureBuilder<String>(
              future: userService.getUserNameByUid(pUid), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading...'); 
                } else if (snapshot.hasError) {
                  return const Text(
                      'Error loading username'); 
                } else {
                  return Text(
                    snapshot.data ?? 'User', 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                }
              },
            ),
          ),

          // Post Image
          FutureBuilder<Widget>(
            future: postService.displayPostPic(postPicPath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AspectRatio(
                  aspectRatio: 1,
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return const Center(child: Text("❌ Error loading image"));
              } else {
                return Container(
                  width: double.infinity,
                  height: 350,
                  child: snapshot.data ?? const SizedBox(),
                );
              }
            },
          ),

          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FutureBuilder<String>(
              future: userService.getUserNameByUid(pUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading...'); 
                } else if (snapshot.hasError) {
                  return const Text(
                      'Error loading username'); 
                } else {
                  return RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text:
                              snapshot.data ?? 'User', 
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(
                          text: postData['context'] ??
                              'No caption', 
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
