import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/screens/profile_setup_page.dart';
import 'package:outstragram/services/authService.dart';
import 'package:outstragram/screens/search_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/widgets/widget_tree.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  User? user = Authservice().currentUser;
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final User? user = Authservice().currentUser;

  Future<void> signOut() async {
    await Authservice().signOut();
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
        await Authservice().signOut();
        setState(() {});
      },
      child: Text("Sign xd"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
      ),
    );
  }


  Widget _start(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WidgetTree()),
      );
    },
    child: const Text("start"),
  );
}
  @override
  Widget build(BuildContext context) {
    // redirect ทันทีโดยไม่แสดง widget
    Future.microtask(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WidgetTree()),
      );
    });

    return const SizedBox(); // หรือ Scaffold เปล่าๆ ก็ได้
  }

}