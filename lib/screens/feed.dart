import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

class Feed extends StatefulWidget {
  final PostService postService = PostService();
  final UserService userService = UserService();

  @override
  _FeedState createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  Future<List<Map<String, dynamic>>>? _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _postsFuture = widget.postService.fetchFollowingPosts();
    });
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB), // พื้นหลังสีเดียวกับ LoginPage
      appBar: AppBar(
        backgroundColor: const Color(0xFF80CBC4), // สีหลักที่ใช้ในปุ่ม login
        elevation: 3,
        centerTitle: true,
        title: Text(
          'Feed',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: const Color(0xFF80CBC4),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_album_outlined, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      "No posts available",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }

            final posts = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index];
                final bool isPrivate = postData['isPrivate'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Header
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            FutureBuilder<Widget>(
                              future: widget.userService.displayUserProfileImage(
                                postData['ownerId'],
                                radius: 24,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircleAvatar(
                                    radius: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                }
                                return snapshot.data ?? const CircleAvatar(radius: 24);
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<String>(
                                    future: widget.userService.getUserNameByUid(postData['ownerId']),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.data ?? 'Unknown',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      );
                                    },
                                  ),
                                  if (isPrivate)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.lock_outline, size: 14, color: Color(0xFF607D8B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Close Friend Only",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: const Color(0xFF607D8B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      // Caption
                      if (postData['context'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            postData['context'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Post Image
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: FutureBuilder<Widget>(
                          future: widget.postService.displayPostPic(postData['pic']),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade100,
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }
                            return snapshot.data ??
                                Container(
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.image, size: 40)),
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
