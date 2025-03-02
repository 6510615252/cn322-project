import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSetupPage extends StatefulWidget {
  final User user;

  const ProfileSetupPage({super.key, required this.user});

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userPicController = TextEditingController();

  Future<void> _saveUserData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance.databaseId != null
      ? FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'dbmain',
        )
      : FirebaseFirestore.instance;
      
    await firestore.collection('User').doc(widget.user.uid).set({
      'name': _nameController.text,
      'user_pic': _userPicController.text,
      'email': widget.user.email,
      'uid': widget.user.uid,
      'following': [],
      'closefriend': [],
      'post': [],
    });

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home'); // กลับไปหน้า Home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Up Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Display Name"),
            ),
            TextField(
              controller: _userPicController,
              decoration: const InputDecoration(labelText: "Profile Picture URL"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUserData,
              child: const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
