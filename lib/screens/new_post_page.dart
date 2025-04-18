import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';
import 'package:outstragram/screens/home_page.dart';
import 'package:outstragram/widgets/widget_tree.dart';

class NewPostPage extends StatefulWidget {
  final String? uid;

  NewPostPage({super.key, String? uid})
      : uid = uid ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  _NewPostPageState createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  final TextEditingController _captionController = TextEditingController();
  final PostService _postService = PostService();
  final UserService _userService = UserService();

  List<String> _closeFriends = [];
  List<String> _allUsers = [];
  bool _isLoading = false;
  Uint8List? _imageBytes;
  bool _isPrivate = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCloseFriends();
    _loadAllUsers();
    _loadCloseFriends();
  }

  Future<void> _loadCloseFriends() async {
    try {
      // ดึงข้อมูล Close Friends จาก Firebase
      List<String> closeFriends =
          await _userService.getCloseFriends(widget.uid!);
      setState(() {
        _closeFriends = closeFriends;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading close friends: $e")),
      );
    }
  }

  //loadUser ที่ยังไม่อยู่ใน closefriends
  void _loadAllUsers() async {
    List<String> allUsers =
        await _userService.getNotCloseFriendsUser(widget.uid!);
    setState(() {
      _allUsers = allUsers;
    });
  }

  Future<void> _addToCloseFriends(List<String> selectedUsers) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // เพิ่มผู้ใช้ที่เลือกไปยัง Close Friends ของ Firebase
      await _userService.addCloseFriends(widget.uid!, selectedUsers);

      // อัปเดต Close Friends ในตัวแปร _closeFriends เพื่อให้แสดงผลทันที
      setState(() {
        _closeFriends.addAll(selectedUsers);
        // ลบผู้ใช้ที่เพิ่มไปแล้วจาก _allUsers เพื่อไม่ให้แสดงในรายการอีก
        _allUsers.removeWhere((user) => selectedUsers.contains(user));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Close friends updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding close friends: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddCloseFriendsDialog() {
    List<String> selectedUsers = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Close Friends"),
          content: SingleChildScrollView(
            child: Column(
              children: _allUsers.map((user) {
                return CheckboxListTile(
                  title: Text(user),
                  value: selectedUsers.contains(user),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null) {
                        if (value) {
                          selectedUsers.add(user);
                        } else {
                          selectedUsers.remove(user);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _addToCloseFriends(selectedUsers); // อัปเดต Close Friends
                Navigator.of(context).pop(); // ปิด Dialog
                _loadAllUsers(); // รีเฟรชข้อมูลผู้ใช้ที่ยังไม่ได้เป็น Close Friend
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
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
            // Display image preview if selected
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: kIsWeb
                    ? Image.memory(
                        _imageBytes!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      )
                    : Image.memory(
                        _imageBytes!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
              ),
            const SizedBox(height: 20),
            // Always display the "Pick an Image" button
            ElevatedButton(
              onPressed: _pickImage,
              child: Text(_imageBytes == null ? "Pick an Image" : "Change Image"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: "Caption"),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPrivate = false; // Set to Everyone
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: !_isPrivate ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Center(
                        child: Text(
                          "Everyone",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPrivate = true; // Set to Close Friends
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isPrivate ? Colors.blue : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: const Center(
                        child: Text(
                          "Close Friends",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Display the selected audience text
            Text(
              _isPrivate
                  ? "Only Close Friends can see this post.\n Close Friends: ${_closeFriends.join(', ')}"
                  : "Everyone can see this post.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _createNewPost,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create Post"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddCloseFriendsDialog,
              child: const Text("Add Close Friends"),
            ),
          ],
        ),
      ),
    );
  }
}