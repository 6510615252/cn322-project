import 'package:flutter/material.dart';

class Feed extends StatelessWidget {
  Feed({super.key});

  // Placeholder post data
  final List<Map<String, String>> posts = List.generate(5, (index) => {
        "image": "https://ih1.redbubble.net/image.2148260610.1173/bg,f8f8f8-flat,750x,075,f-pad,750x1000,f8f8f8.jpg",
        "user": "User ${index + 1}",
        "caption": "This is a placeholder caption for post ${index + 1}.",
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feed")),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Placeholder
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage:
                      NetworkImage("https://source.unsplash.com/random/user"),
                ),
                title: Text(posts[index]["user"]!),
                subtitle: const Text("3 hours ago"),
                trailing: const Icon(Icons.more_vert),
              ),

              // Post Image Placeholder
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(posts[index]["image"]!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Like, Comment, Share Icons (Static for now)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.favorite_border),
                    SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline),
                    SizedBox(width: 16),
                    Icon(Icons.send),
                  ],
                ),
              ),

              // Caption Placeholder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  posts[index]["caption"]!,
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
