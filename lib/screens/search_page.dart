import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:outstragram/services/userService.dart';
import 'ProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserService userService = UserService();
  List<Map<String, dynamic>> searchResults = [];

  void updateSearchResults(List<Map<String, dynamic>> results) {
    setState(() {
      searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search User")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                userService.searchUsers(query, updateSearchResults);  // เรียกฟังก์ชัน searchUsers และส่ง callback
              },
              decoration: InputDecoration(
                labelText: "Search by Name",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => userService.searchUsers(_searchController.text, updateSearchResults),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                return ListTile(
                  title: Text(user['name']),
                  leading: FutureBuilder<Widget>(
                    future: userService.displayUserProfilePic(user['user_pic'] ?? "user_pic/UserPicDef.jpg"),
                    builder: (context, profilePicSnapshot) {
                      if (profilePicSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 40,
                          child: CircularProgressIndicator(),
                        );
                      }
                      return CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: ClipOval(child: profilePicSnapshot.data),
                      );
                    },
                  ),
                  onTap: () {
                    // นำไปหน้าโปรไฟล์ของ user ที่ถูกค้นหา
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(uid: user['uid']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

