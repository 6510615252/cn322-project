import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/services/postService.dart';
import 'package:outstragram/services/userService.dart';
import 'package:outstragram/screens/post_detail_page.dart';
import 'package:outstragram/widgets/manage_close_friends_button.dart';

// Define app theme colors for consistency
class AppTheme {
  static const Color creamColor = Color(0xFFF5F0DC);
  static const Color navyColor = Color(0xFF363B5C);
  static const Color tealColor = Color(0xFF8BB3A8);
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
    setState(() {
      isLoading = true;
    });

    await fetchUserData();
    await _countPosts();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _countPosts() async {
    final count = await userService.countVisiblePosts(profileUid);
    setState(() {
      postCount = count;
    });
  }

  @override
  void dispose() {
    bioController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final data = await userService.fetchUserData(profileUid);
    if (data != null) {
      setState(() {
        userData = data;
      });
      checkFollowingStatus();
    }
  }

  Future<void> checkFollowingStatus() async {
    if (currentUser != null) {
      bool following =
          await userService.isUserFollowing(profileUid, currentUser!.uid);
      setState(() {
        isFollowing = following;
      });
    }
  }

  Future<void> toggleFollow() async {
    await userService.toggleFollowUser(profileUid, currentUser!.uid);
    await fetchUserData(); // Refresh data to update counts
    checkFollowingStatus();
  }

  Future<void> _updateBio() async {
    if (bioController.text != userData?['bio']) {
      try {
        await userService.updateBio(currentUser!.uid, bioController.text);
        await fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bio updated successfully"),
            backgroundColor: AppTheme.tealColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating bio: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      isEditingBio = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyProfile = profileUid == currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          userData?['name'] ?? "Profile",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
                    // Confirm logout dialog
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Sign Out"),
                        content:
                            const Text("Are you sure you want to sign out?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Sign Out",
                                style: TextStyle(color: Colors.red)),
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
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.tealColor))
          : userData == null
              ? const Center(child: Text("User not found"))
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
              // Profile picture
              FutureBuilder<Widget>(
                future: userService.displayUserProfilePic(
                    userData?['user_pic'] ?? "user_pic/UserPicDef.jpg"),
                builder: (context, profilePicSnapshot) {
                  if (profilePicSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.tealColor,
                        ),
                      ),
                    );
                  }

                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.tealColor,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: profilePicSnapshot.data ??
                          Image.asset('assets/default_profile.png',
                              fit: BoxFit.cover),
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              // Stats column
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(postCount.toString(), "Posts"),
                    _buildStatColumn(
                        (userData?['followers']?.length ?? 0).toString(),
                        "Followers"),
                    _buildStatColumn(
                        (userData?['following']?.length ?? 0).toString(),
                        "Following"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Follow/Unfollow button
          if (isMyProfile) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ManageCloseFriendsButton(),
            ),
          ],
          if (!isMyProfile)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFollowing ? Colors.white : AppTheme.tealColor,
                  foregroundColor:
                      isFollowing ? AppTheme.tealColor : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color:
                          isFollowing ? AppTheme.tealColor : Colors.transparent,
                    ),
                  ),
                  elevation: isFollowing ? 0 : 2,
                ),
                child: Text(
                  isFollowing ? "Unfollow" : "Follow",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
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
              Text(
                userData?['name'] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (isMyProfile)
                IconButton(
                  icon: Icon(
                    isEditingBio ? Icons.close : Icons.edit,
                    color: AppTheme.navyColor,
                    size: 20,
                  ),
                  onPressed: () {
                    if (isEditingBio) {
                      setState(() {
                        isEditingBio = false;
                      });
                    } else {
                      setState(() {
                        isEditingBio = true;
                        bioController.text = userData?['bio'] ?? '';
                      });
                    }
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
                      maxLength: 150,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "Write something about yourself",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppTheme.tealColor),
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
                          onPressed: () {
                            setState(() {
                              isEditingBio = false;
                            });
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _updateBio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tealColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(
                  userData?['bio'] ?? "No bio available",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Posts",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(height: 1),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: postService.fetchUserPosts(profileUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.tealColor),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "No posts yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
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
                  builder: (context, postPicSnapshot) {
                    if (postPicSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.tealColor,
                            ),
                          ),
                        ),
                      );
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailPage(
                              postPicPath: postPicPath,
                              postData: posts[index],
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'post_${posts[index]['id']}',
                        child: Container(
                          color: Colors.grey[200],
                          child: postPicSnapshot.data ??
                              const Center(child: Icon(Icons.error)),
                        ),
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
