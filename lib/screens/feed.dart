import 'package:flutter/material.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';

class Feed extends StatelessWidget {
  final PostService postService = PostService();
  final UserService userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: postService.fetchFollowingPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No posts available"));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(postData['context'] ?? 'No caption'),
                  subtitle: FutureBuilder<String>(
                    future: userService.getUserNameByUid(postData['ownerId']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...');
                      }
                      if (snapshot.hasError) {
                        return const Text('Error');
                      }
                      return Text('By ${snapshot.data ?? 'Unknown'}');
                    },
                  ),
                  leading: FutureBuilder<Widget>(
                    future: postService.displayPostPic(postData['pic'] ?? "user_pic/UserPicDef.jpg"),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return const Icon(Icons.error);
                      }
                      return snapshot.data ?? const Icon(Icons.image);
                    },
                  )
                ),
              );
            },
          );
        },
      ),
    );
  }
}