import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController captionController = TextEditingController();
  File? _selectedImage;

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void submitPost() {
    if (captionController.text.isNotEmpty && _selectedImage != null) {
      Navigator.pop(context, {
        "image": _selectedImage!.path, // Send image path
        "user": "New User",
        "caption": captionController.text,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image and enter a caption")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Center(child: Text("Tap to select image"))
                    : null,
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your caption...",
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: submitPost,
              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }
}
