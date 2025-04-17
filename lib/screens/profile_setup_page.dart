import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outstragram/services/userService.dart';
import 'package:outstragram/screens/home_page.dart';
import 'package:outstragram/widgets/widget_tree.dart';

class ProfileSetupPage extends StatefulWidget {
  final User user;

  const ProfileSetupPage({super.key, required this.user});

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  Uint8List? _imageBytes; // ใช้แทน Path เพื่อรองรับ Web & Mobile

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageBytes =
          await image.readAsBytes(); // ใช้ได้ทั้ง Web & Mobile
      setState(() {
        _imageBytes = imageBytes;
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

    if (_bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a bio")),
      );
      return;
    }

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a profile picture")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: อัปโหลดรูปภาพไปยัง Firebase Storage
      final String imageUrl = await _userService.uploadProfilePic(
        _imageBytes!,
        '${widget.user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Step 2: บันทึกข้อมูลผู้ใช้ใน Firestore
      await _userService.updateUserNameAndBio(
        uid: widget.user.uid,
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // Step 3: เปลี่ยนหน้าไปยัง home
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
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: "Your bio"),
            ),
            const SizedBox(height: 20),
            // Always show the button to pick image
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Pick Profile Picture"),
            ),
            const SizedBox(height: 10),
            // Display the selected image if available
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.memory(
                  _imageBytes!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
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