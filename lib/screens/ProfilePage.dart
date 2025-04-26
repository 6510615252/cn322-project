import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';
import 'package:outstragram/screens/post_detail_page.dart';
import 'package:outstragram/widgets/manage_close_friends_button.dart';

class AppTheme {
  static const Color creamColor = Color(0xFFFDFCFB);
  static const Color navyColor = Color(0xFF607D8B);
  static const Color tealColor = Color(0xFF80CBC4);
  static const Color lightGreenColor = Color(0xFFB4DBA0);
}

class ProfilePage extends StatefulWidget {
  final String? uid;
  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final UserService userService = UserService();
  final PostService postService = PostService();
  bool isEditingBio = false;
  final TextEditingController bioController = TextEditingController();

  late String profileUid;
  bool isFollowing = false;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    profileUid = widget.uid ?? currentUser?.uid ?? '';
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    await fetchUserData();
    await _countPosts();
    setState(() => isLoading = false);
  }

  Future<void> _countPosts() async {
    final count = await userService.countVisiblePosts(profileUid);
    setState(() => postCount = count);
  }

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final data = await userService.fetchUserData(profileUid);
    if (data != null) {
      setState(() => userData = data);
      checkFollowingStatus();
    }
  }

  Future<void> checkFollowingStatus() async {
    if (currentUser != null) {
      bool following =
          await userService.isUserFollowing(profileUid, currentUser!.uid);
      setState(() => isFollowing = following);
    }
  }

  Future<void> toggleFollow() async {
    await userService.toggleFollowUser(profileUid, currentUser!.uid);
    await fetchUserData();
    checkFollowingStatus();
  }

  Future<void> _updateBio() async {
    if (bioController.text != userData?['bio']) {
      try {
        await userService.updateBio(currentUser!.uid, bioController.text);
        await fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bio updated successfully", style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.tealColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating bio: $e", style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => isEditingBio = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyProfile = profileUid == currentUser?.uid;
    return Scaffold(
      backgroundColor: AppTheme.creamColor,
      appBar: AppBar(
        title: Text(userData?['name'] ?? "Profile",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppTheme.navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: isMyProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: "Sign Out",
                  onPressed: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Sign Out", style: GoogleFonts.poppins()),
                        content: Text("Are you sure you want to sign out?", style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text("Cancel", style: GoogleFonts.poppins()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text("Sign Out", style: GoogleFonts.poppins(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true) {
                      await FirebaseAuth.instance.signOut();
                    }
                  },
                ),
              ]
            : [],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.tealColor))
          : userData == null
              ? Center(child: Text("User not found", style: GoogleFonts.poppins()))
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  color: AppTheme.tealColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileHeader(isMyProfile),
                        _buildBioSection(isMyProfile),
                        const SizedBox(height: 16),
                        _buildPostsGrid(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(bool isMyProfile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FutureBuilder<Widget>(
                future: userService.displayUserProfilePic(userData?['user_pic'] ?? "user_pic/UserPicDef.jpg"),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(radius: 45, backgroundColor: Colors.grey[300]);
                  }
                  return CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: ClipOval(child: snapshot.data ?? const Icon(Icons.person, size: 45)),
                  );
                },
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(postCount.toString(), "Posts"),
                    _buildStatColumn((userData?['followers']?.length ?? 0).toString(), "Followers"),
                    _buildStatColumn((userData?['following']?.length ?? 0).toString(), "Following"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMyProfile)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ManageCloseFriendsButton(),
            ),
          if (!isMyProfile)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.white : AppTheme.tealColor,
                  foregroundColor: isFollowing ? AppTheme.tealColor : Colors.white,
                  side: BorderSide(color: isFollowing ? AppTheme.tealColor : Colors.transparent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(isFollowing ? "Unfollow" : "Follow", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(count, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBioSection(bool isMyProfile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(userData?['name'] ?? "", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              if (isMyProfile)
                IconButton(
                  icon: Icon(isEditingBio ? Icons.close : Icons.edit, color: AppTheme.navyColor, size: 20),
                  onPressed: () {
                    setState(() {
                      isEditingBio = !isEditingBio;
                      bioController.text = userData?['bio'] ?? '';
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          isEditingBio
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Write something about yourself",
                        hintStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.tealColor),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => isEditingBio = false),
                          child: Text("Cancel", style: GoogleFonts.poppins()),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _updateBio,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tealColor),
                          child: Text("Save", style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(userData?['bio'] ?? "No bio available", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Posts", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const Divider(height: 1),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: postService.fetchUserPosts(profileUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: AppTheme.tealColor)),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text("No posts yet", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                ),
              );
            }
            final posts = snapshot.data!;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postPicPath = posts[index]['pic'];
                return FutureBuilder<Widget>(
                  future: postService.displayPostPic(postPicPath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.tealColor)));
                    }
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailPage(postPicPath: postPicPath, postData: posts[index]),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'post_${posts[index]['id']}',
                        child: Container(color: Colors.grey[200], child: snapshot.data ?? const Icon(Icons.image)),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
