import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/auth.dart';
import 'package:outstragram/pages/search_page.dart';


class HomePage extends StatefulWidget {
  HomePage({super.key});

  User? user = Auth().currentUser;
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title() {
    return const Text("Firebase Auth");
  }

  Widget _userUID() {
    return Text(user?.email ?? 'User email');
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: () async {
        await Auth().signOut();
        setState(() {});
      },
      child: Text("Sign Out"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
      ),
    );
  }


  Widget _searchButton(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchPage()),
      );
    },
    child: const Text("Search Users"),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity, 
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userUID(),
             _searchButton(context),
            _signOutButton()
            ],
          ),
        ),
    );
  }
}