import 'package:flutter/material.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

// Define AppTheme for use in this page
class AppTheme {
  static const Color creamColor = Color(0xFFF5F0DC);
  static const Color navyColor = Color(0xFF363B5C);
  static const Color tealColor = Color(0xFF8BB3A8);
  static const Color lightGreenColor = Color(0xFFB4DBA0);
}

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
      backgroundColor: AppTheme.creamColor,
      appBar: AppBar(
        backgroundColor: AppTheme.navyColor,
        elevation: 0,
        title: const Text(
          'Feed',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: AppTheme.tealColor,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.tealColor),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_album_outlined,
                      size: 70,
                      color: AppTheme.navyColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No posts available",
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.navyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final posts = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index];
                final bool isPrivate = postData['isPrivate'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.navyColor.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with user info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppTheme.tealColor.withOpacity(0.2),
                              radius: 20,
                              child: FutureBuilder<Widget>(
                                future: widget.postService.displayPostPic(
                                    postData['pic'] ?? "user_pic/UserPicDef.jpg"),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppTheme.tealColor),
                                        ),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return const Icon(Icons.error, size: 20);
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: snapshot.data ??
                                          const Icon(Icons.image, size: 20),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<String>(
                                  future: widget.userService.getUserNameByUid(
                                      postData['ownerId']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        'Loading...',
                                        style: TextStyle(
                                          color: AppTheme.navyColor
                                              .withOpacity(0.5),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return const Text('Error loading name');
                                    }
                                    return Text(
                                      snapshot.data ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navyColor,
                                      ),
                                    );
                                  },
                                ),
                                if (isPrivate)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.tealColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock_outline,
                                          size: 12,
                                          color: AppTheme.tealColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Close Friend Only",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.tealColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Post Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          postData['context'] ?? 'No caption',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.navyColor.withOpacity(0.8),
                          ),
                        ),
                      ),

                      // Post Image if available
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.navyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FutureBuilder<Widget>(
                            future: widget.postService.displayPostPic(
                                postData['pic'] ?? "user_pic/UserPicDef.jpg"),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return const Center(
                                  child: Icon(Icons.error),
                                );
                              }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: snapshot.data ?? const Icon(Icons.image),
                              );
                            },
                          ),
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