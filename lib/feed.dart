import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Feed extends StatelessWidget {
  final List<String> posts = [
    "https://source.unsplash.com/random/1",
    "https://source.unsplash.com/random/2",
    "https://source.unsplash.com/random/3",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(" Feed")),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: NetworkImage("https://source.unsplash.com/random/user"),
                ),
                title: Text("User ${index + 1}"),
                subtitle: const Text("2 hours ago"),
                trailing: const Icon(Icons.more_vert),
              ),

              // Post Image
              CachedNetworkImage(
                imageUrl: posts[index],
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
              ),

              // Like, Comment, Share Buttons
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.favorite_border),
                    SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline),
                    SizedBox(width: 16),
                    Icon(Icons.send),
                  ],
                ),
              ),

              // Caption
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "User ${index + 1}: This is a sample caption for the post!",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}
