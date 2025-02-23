import 'package:flutter/material.dart';
import 'package:outstragram/feed.dart';
import 'package:outstragram/CreatePost.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "My title",
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> posts = [];

  void addPost(Map<String, String> newPost) {
    setState(() {
      posts.insert(0, newPost);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 200, 255),
      appBar: AppBar(title: const Text("Outstragram")),
      body: Feed(posts: posts), // Pass posts list to Feed
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newPost = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );

          if (newPost != null) {
            addPost(newPost);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
