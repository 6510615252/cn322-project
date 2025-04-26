import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

class AppTheme {
  static const Color creamColor = Color(0xFFFDFCFB);
  static const Color navyColor = Color(0xFF607D8B);
  static const Color tealColor = Color(0xFF80CBC4);
  static const Color lightGreenColor = Color(0xFFB4DBA0);
}

class PostDetailPage extends StatelessWidget {
  final PostService postService = PostService();
  final UserService userService = UserService();
  final String postPicPath;
  final Map<String, dynamic> postData;

  late final String pUid;

  PostDetailPage({
    super.key,
    required this.postPicPath,
    required this.postData,
  }) {
    pUid = postData['ownerId'];
  }

  Future<String> getPostUserPicPath() async {
    try {
      var data = await userService.fetchUserData(pUid);
      return data?['user_pic'] ?? "";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamColor,
      appBar: AppBar(
        backgroundColor: AppTheme.navyColor,
        elevation: 0,
        title: Text("Post", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 6),
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
                    if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
                      return const CircleAvatar(
                        backgroundImage: AssetImage('assets/default_profile_pic.png'),
                      );
                    } else {
                      return FutureBuilder<Widget>(
                        future: userService.displayUserProfilePic(snapshot.data ?? ""),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
                            return const CircleAvatar(
                              backgroundImage: AssetImage('assets/default_profile_pic.png'),
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
                    return Text(
                      snapshot.data ?? 'User',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Post Image
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
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: snapshot.data ?? const SizedBox(),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // Caption
              FutureBuilder<String>(
                future: userService.getUserNameByUid(pUid),
                builder: (context, snapshot) {
                  return RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(
                          text: snapshot.data ?? 'User',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const TextSpan(text: "  "),
                        TextSpan(text: postData['context'] ?? 'No caption'),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
