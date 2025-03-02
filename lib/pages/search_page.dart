import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
     FirebaseFirestore firestore = FirebaseFirestore.instance.databaseId != null
      ? FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'dbmain',
        )
      : FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection("User")
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff') // ใช้เพื่อค้นหาตามตัวอักษร
        .get();
    if (querySnapshot.docs.isEmpty) {
      print('No data found');
    } else {
      print('Found ${querySnapshot.docs.length} results');
      for (var doc in querySnapshot.docs) {
        print(doc.data()); // แสดงข้อมูลใน document
      }
    }
    List<Map<String, dynamic>> results = querySnapshot.docs.map((doc) => doc.data()).toList();

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
              onChanged: searchUsers,
              decoration: InputDecoration(
                labelText: "Search by Name",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => searchUsers(_searchController.text),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}