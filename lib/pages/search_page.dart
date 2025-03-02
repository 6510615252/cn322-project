import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  Timer? _debounce;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    // แก้ไขตรงนี้: อ้างอิง subcollection ที่ถูกต้อง
    final usersCollection = FirebaseFirestore.instance
        .collection('dbmain')
        .doc('TestUser')
        .collection('User');

    try {
      final querySnapshot = await usersCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No data found');
      } else {
        print('Found ${querySnapshot.docs.length} results');
        for (var doc in querySnapshot.docs) {
          print(doc.data());
        }
      }

      List<Map<String, dynamic>> results =
          querySnapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        searchResults = results;
      });
    } catch (e) {
      print('Error searching users: $e'); // เพิ่ม print(e)
      setState(() {
        searchResults = [];
      });
    }
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
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  searchUsers(value);
                });
              },
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
                  title: Text(user['name']), // แสดงเฉพาะชื่อ
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}