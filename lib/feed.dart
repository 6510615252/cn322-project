import 'dart:io'; // Import for File
import 'package:flutter/material.dart';

class Feed extends StatelessWidget {
  final List<Map<String, String>> posts;

  const Feed({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        String imagePath = posts[index]["image"]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundImage: NetworkImage("https://source.unsplash.com/random/user"),
              ),
              title: Text(posts[index]["user"]!),
              subtitle: const Text("Just now"),
              trailing: const Icon(Icons.more_vert),
            ),

            // Display local file or network image correctly
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imagePath.startsWith('http')
                      ? NetworkImage(imagePath) as ImageProvider // If URL, use NetworkImage
                      : FileImage(File(imagePath)), // If local file, use FileImage
                  fit: BoxFit.cover,
                ),
              ),
            ),

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
    );
  }
}
