import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outstragram/services/userService.dart';
import 'package:outstragram/screens/home_page.dart';

class ProfileSetupPage extends StatefulWidget {
  final User user;

  const ProfileSetupPage({super.key, required this.user});

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _profilePicPath; // ✅ เพิ่มตัวแปรนี้

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicPath = image.path; // ✅ เก็บ path ไว้ใช้งาน
      });
    }
  }

  Future<void> _saveUserData() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a display name")),
      );
      return;
    }

    if (_profilePicPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a profile picture")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: อัปโหลดรูปภาพไปยัง Firebase Storage และรับ URL
      final Uint8List imageBytes = await File(_profilePicPath!).readAsBytes();
      final String imageUrl = await _userService.uploadProfilePic(imageBytes, widget.user.uid + '_profile.jpg');

      // Step 2: บันทึกข้อมูลผู้ใช้ใน Firestore
      await _userService.updateUserProfile(
        uid: widget.user.uid,
        name: _nameController.text.trim(),
        userPic: imageUrl, // ✅ ใช้ URL ของภาพที่อัปโหลด
      );

      // Step 3: เปลี่ยนหน้าไปยัง HomePage
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

            const SizedBox(height: 20),
            _profilePicPath == null
                ? ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Pick Profile Picture"),
                  )
                : (kIsWeb
                    ? Image.network(_profilePicPath!)
                    : Image.file(
                        File(_profilePicPath!),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveUserData,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Save Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
