import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/screens/home_page.dart';
import 'package:outstragram/widgets/widget_tree.dart';

class NewPostPage extends StatefulWidget {
  final String? uid;
  final PostService userService = PostService();

  NewPostPage({super.key, String? uid}) : uid = uid ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final TextEditingController _captionController = TextEditingController();
  final PostService _postService = PostService();

  bool _isLoading = false;
  Uint8List? _imageBytes;
  bool _isPrivate = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageBytes = await image.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }



  Future<void> _createNewPost() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a caption")),
      );
      return;
    }

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image for the post")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String postId = '${DateTime.now().millisecondsSinceEpoch}';

      // Upload image to Firebase Storage
      final String imageUrl = await _postService.uploadPostPic(
        _imageBytes!,
        postId,
      );

      // Add post details to Firestore
      await _postService.addPost(
        postId: postId,
        isPrivate: _isPrivate,
        picPath: 'posts_pic/$postId',
        context: _captionController.text.trim(),
      );

      await _postService.updateUserPost(uId: widget.uid!, postId: postId);

      // Navigate to home page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WidgetTree()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating post: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Post")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _imageBytes == null
                ? ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Pick an Image"),
                  )
                  
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: kIsWeb
                        ? Image.memory(_imageBytes!,
                            width: 150, height: 150, fit: BoxFit.cover)
                        : Image.memory(_imageBytes!,
                            width: 150, height: 150, fit: BoxFit.cover),
                  ),
                  TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: "Caption"),
            ),
            CheckboxListTile(
              title: const Text("Close Friends Only"),
              subtitle: const Text("Only close friends can see this post."),
              value: _isPrivate,
              onChanged: (bool? value) {
                setState(() {
                  _isPrivate = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _createNewPost,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create Post"),
            ),
          ],
        ),
      ),
    );
  }
}