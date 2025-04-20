import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

class AppTheme {
  static const Color creamColor = Color(0xFFF5F0DC);
  static const Color navyColor = Color(0xFF363B5C);
  static const Color tealColor = Color(0xFF8BB3A8);
  static const Color lightGreenColor = Color(0xFFB4DBA0);
}

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
    backgroundColor: AppTheme.creamColor,
    appBar: AppBar(
      title: const Text("Post"),
      backgroundColor: AppTheme.navyColor,
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    // Replace the ListView body with this updated version

body: Center(
  child: Container(
    width: 400, // fixed width for post box
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Info
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: FutureBuilder<String>(
            future: getPostUserPicPath(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.hasError) {
                return const CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/default_profile_pic.png'),
                );
              } else {
                return FutureBuilder<Widget>(
                  future: userService
                      .displayUserProfilePic(snapshot.data ?? ""),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        snapshot.hasError) {
                      return const CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/default_profile_pic.png'),
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
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.hasError) {
                return const Text('Loading...');
              } else {
                return Text(
                  snapshot.data ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              }
            },
          ),
        ),

        const SizedBox(height: 12),

        // Fixed Size Post Image
        FutureBuilder<Widget>(
          future: postService.displayPostPic(postPicPath),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 350,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return const Center(child: Text("❌ Error loading image"));
            } else {
              return Container(
                height: 350,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: snapshot.data ?? const SizedBox(),
              );
            }
          },
        ),

        const SizedBox(height: 12),

        // Caption
        FutureBuilder<String>(
          future: userService.getUserNameByUid(pUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.hasError) {
              return const Text('Loading...');
            } else {
              return RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: snapshot.data ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: postData['context'] ?? 'No caption',
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    ),
  ),
),
);
}
}