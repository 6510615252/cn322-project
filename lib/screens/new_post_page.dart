// new_post_page.dart (แก้ไขแล้วให้เข้ากับธีม LoginPage)
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';
import 'package:outstragram/widgets/manage_close_friends_button.dart';
import 'package:outstragram/widgets/widget_tree.dart';

class AppTheme {
  static const Color creamColor = Color(0xFFFDFCFB);
  static const Color navyColor = Color(0xFF607D8B);
  static const Color tealColor = Color(0xFF80CBC4);
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
      final String postId =
          '${DateTime.now().millisecondsSinceEpoch}_${widget.uid}';

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

      await _postService.updateUserPost(
          uId: widget.uid!, postId: postId, isPrivate: _isPrivate);

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
        title: Text(
          "Create New Post",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.navyColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.creamColor,
                  title: Text("Post Privacy",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  content: Text(
                    "Everyone: All users can see your post.\n\nClose Friends: Only users you've added as close friends can see your post.",
                    style: GoogleFonts.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.navyColor),
                      child: Text("Got it", style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.navyColor))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker Section
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text("Post Image",
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navyColor)),
                            const SizedBox(height: 16),
                            if (_imageBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.memory(_imageBytes!,
                                    height: 250, width: 250, fit: BoxFit.cover),
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(_imageBytes == null
                                  ? Icons.add_photo_alternate
                                  : Icons.edit),
                              label: Text(
                                  _imageBytes == null
                                      ? "Select Image"
                                      : "Change Image",
                                  style: GoogleFonts.poppins()),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                foregroundColor: Colors.white,
                                backgroundColor: AppTheme.tealColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
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
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Caption",
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navyColor)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _captionController,
                              decoration: InputDecoration(
                                hintText: "What's on your mind?",
                                hintStyle: GoogleFonts.poppins(),
                                filled: true,
                                fillColor: AppTheme.creamColor.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: AppTheme.tealColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: AppTheme.tealColor, width: 2),
                                ),
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
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.visibility,
                                    color: AppTheme.tealColor),
                                const SizedBox(width: 10),
                                Text("Privacy Settings",
                                    style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navyColor)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isPrivate = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      decoration: BoxDecoration(
                                        color: !_isPrivate
                                            ? AppTheme.navyColor
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text("Everyone",
                                            style: GoogleFonts.poppins(
                                                color: !_isPrivate
                                                    ? Colors.white
                                                    : Colors.black54)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _isPrivate = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      decoration: BoxDecoration(
                                        color: _isPrivate
                                            ? AppTheme.lightGreenColor
                                            : Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text("Close Friends",
                                            style: GoogleFonts.poppins(
                                                color: _isPrivate
                                                    ? AppTheme.navyColor
                                                    : Colors.black54)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isPrivate
                                    ? AppTheme.lightGreenColor.withOpacity(0.2)
                                    : AppTheme.navyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _isPrivate
                                        ? AppTheme.lightGreenColor
                                        : AppTheme.navyColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                _isPrivate
                                    ? "Only your close friends will see this post (${_closeFriends.length})"
                                    : "Everyone will be able to see this post",
                                style: GoogleFonts.poppins(
                                    color: AppTheme.navyColor),
                              ),
                            ),
                            if (_isPrivate) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                  width: double.infinity,
                                  child: ManageCloseFriendsButton()),
                            ]
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createNewPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor:
                              AppTheme.navyColor.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.post_add, size: 20),
                                  const SizedBox(width: 8),
                                  Text("Create Post",
                                      style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
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