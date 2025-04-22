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

// ธีมสีที่กำหนด
class AppTheme {
  static const Color creamColor = Color(0xFFF5F0DC);
  static const Color navyColor = Color(0xFF363B5C);
  static const Color tealColor = Color(0xFF8BB3A8);
  static const Color lightGreenColor = Color(0xFFB4DBA0);
}

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
  }

  Future<void> _loadCloseFriends() async {
    try {
      List<String> closeFriends =
          await _userService.getCloseFriendsName(widget.uid!);
      setState(() {
        _closeFriends = closeFriends;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading close friends: $e")),
        );
      }
    }
  }

  void _loadAllUsers() async {
    List<String> allUsers =
        await _userService.getNotCloseFriendsUser(widget.uid!);
    if (mounted) {
      setState(() {
        _allUsers = allUsers;
      });
    }
  }

  Future<void> _addToCloseFriends(List<String> selectedUsers) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.addCloseFriends(widget.uid!, selectedUsers);

      setState(() {
        _closeFriends.addAll(selectedUsers);
        _allUsers.removeWhere((user) => selectedUsers.contains(user));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Close friends updated successfully!"),
          backgroundColor: AppTheme.navyColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding close friends: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddCloseFriendsDialog() async {
    List<String> selectedUsers = [];

    // คืนค่าผู้ใช้ที่เราได้ติดตาม
    List<String> followingUsers =
        await _userService.getFollowingUsers(widget.uid);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.creamColor,
              title: Row(
                children: [
                  Icon(Icons.people_alt, color: AppTheme.tealColor),
                  const SizedBox(width: 10),
                  const Text("Add Close Friends"),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: followingUsers.isEmpty
                    ? const Center(
                        child: Text("You are not following any users."),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: followingUsers.map((user) {
                            return CheckboxListTile(
                              title: Text(user),
                              value: selectedUsers.contains(user),
                              onChanged: (bool? value) {
                                setStateDialog(() {
                                  if (value != null) {
                                    if (value) {
                                      selectedUsers.add(user);
                                    } else {
                                      selectedUsers.remove(user);
                                    }
                                  }
                                });
                              },
                              activeColor: AppTheme.tealColor,
                              checkColor: Colors.white,
                            );
                          }).toList(),
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.navyColor,
                  ),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addToCloseFriends(selectedUsers);
                    Navigator.of(context).pop();
                    _loadAllUsers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Done"),
                ),
              ],
            );
          },
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
        SnackBar(
          content: const Text("Please enter a caption"),
          backgroundColor: AppTheme.navyColor,
        ),
      );
      return;
    }

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select an image for the post"),
          backgroundColor: AppTheme.navyColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String postId = '${DateTime.now().millisecondsSinceEpoch}_${widget.uid}';

      final String imageUrl = await _postService.uploadPostPic(
        _imageBytes!,
        postId,
        _isPrivate,
      );

      await _postService.addPost(
        postId: postId,
        picName: '$postId',
        context: _captionController.text.trim(),
        isPrivate: _isPrivate,
      );

      await _postService.updateUserPost(uId: widget.uid!, postId: postId, isPrivate: _isPrivate);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => WidgetTree()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating post: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamColor,
      appBar: AppBar(
        title: const Text("Create New Post"),
        backgroundColor: AppTheme.navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.creamColor,
                  title: const Text("Post Privacy"),
                  content: const Text(
                      "Everyone: All users can see your post.\n\nClose Friends: Only users you've added as close friends can see your post."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.navyColor,
                      ),
                      child: const Text("Got it"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.navyColor,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "Post Image",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_imageBytes != null)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.navyColor.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: kIsWeb
                                      ? Image.memory(
                                          _imageBytes!,
                                          width: 250,
                                          height: 250,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.memory(
                                          _imageBytes!,
                                          width: 250,
                                          height: 250,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(_imageBytes == null
                                  ? Icons.add_photo_alternate
                                  : Icons.edit),
                              label: Text(_imageBytes == null
                                  ? "Select Image"
                                  : "Change Image"),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                foregroundColor: Colors.white,
                                backgroundColor: AppTheme.tealColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Caption Section
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Caption",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _captionController,
                              decoration: InputDecoration(
                                hintText: "What's on your mind?",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppTheme.tealColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppTheme.tealColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.creamColor.withOpacity(0.5),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Privacy Section
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.visibility,
                                    color: AppTheme.tealColor),
                                const SizedBox(width: 10),
                                Text(
                                  "Privacy Settings",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navyColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                                        color: !_isPrivate
                                            ? AppTheme.navyColor
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: !_isPrivate
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.navyColor
                                                      .withOpacity(0.3),
                                                  spreadRadius: 1,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.public,
                                              color: !_isPrivate
                                                  ? Colors.white
                                                  : Colors.black54,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Everyone",
                                              style: TextStyle(
                                                color: !_isPrivate
                                                    ? Colors.white
                                                    : Colors.black54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isPrivate =
                                            true; // Set to Close Friends
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isPrivate
                                            ? AppTheme.lightGreenColor
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _isPrivate
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme
                                                      .lightGreenColor
                                                      .withOpacity(0.3),
                                                  spreadRadius: 1,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.group,
                                              color: _isPrivate
                                                  ? AppTheme.navyColor
                                                  : Colors.black54,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Close Friends",
                                              style: TextStyle(
                                                color: _isPrivate
                                                    ? AppTheme.navyColor
                                                    : Colors.black54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isPrivate
                                    ? AppTheme.lightGreenColor.withOpacity(0.2)
                                    : AppTheme.navyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isPrivate
                                      ? AppTheme.lightGreenColor
                                      : AppTheme.navyColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isPrivate
                                        ? Icons.check_circle
                                        : Icons.info,
                                    color: _isPrivate
                                        ? AppTheme.lightGreenColor
                                        : AppTheme.navyColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isPrivate
                                          ? _closeFriends.isNotEmpty
                                              ? "Only your close friends will see this post (${_closeFriends.toSet().length} friends)"
                                              : "Only your close friends will see this post. You haven't added any close friends yet."
                                          : "Everyone will be able to see this post",
                                      style: TextStyle(
                                        color: _isPrivate
                                            ? AppTheme.navyColor
                                            : AppTheme.navyColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isPrivate)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, bottom: 8.0),
                                child: TextButton.icon(
                                  onPressed: _showAddCloseFriendsDialog,
                                  icon: Icon(Icons.person_add,
                                      color: AppTheme.tealColor),
                                  label: Text("Manage Close Friends",
                                      style:
                                          TextStyle(color: AppTheme.tealColor)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Create Post Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createNewPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              AppTheme.navyColor.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.post_add, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Create Post",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
