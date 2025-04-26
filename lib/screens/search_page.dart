import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:outstragram/services/userService.dart';
import 'ProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppTheme {
  static const Color creamColor = Color(0xFFFDFCFB);
  static const Color navyColor = Color(0xFF607D8B);
  static const Color tealColor = Color(0xFF80CBC4);
  static const Color lightGreenColor = Color(0xFFB4DBA0);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserService userService = UserService();
  List<Map<String, dynamic>> searchResults = [];

  void updateSearchResults(List<Map<String, dynamic>> results) {
    setState(() {
      searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamColor,
      appBar: AppBar(
        backgroundColor: AppTheme.navyColor,
        elevation: 0,
        title: Text(
          "Search User",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.navyColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                userService.searchUsers(query, updateSearchResults);
              },
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: "Search by name",
                hintStyle: GoogleFonts.poppins(
                    color: AppTheme.navyColor.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.creamColor,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppTheme.tealColor, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.tealColor),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear,
                      color: AppTheme.navyColor.withOpacity(0.5)),
                  onPressed: () {
                    _searchController.clear();
                    updateSearchResults([]);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 60,
                          color: AppTheme.navyColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Search for users",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppTheme.navyColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final user = searchResults[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.navyColor.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            user['name'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.navyColor,
                            ),
                          ),
                          leading: FutureBuilder<Widget>(
                            future: userService.displayUserProfilePic(
                                user['user_pic'] ??
                                    "user_pic/UserPicDef.jpg"),
                            builder: (context, profilePicSnapshot) {
                              if (profilePicSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      AppTheme.tealColor.withOpacity(0.2),
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.tealColor),
                                    ),
                                  ),
                                );
                              }
                              return CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    AppTheme.tealColor.withOpacity(0.2),
                                child: ClipOval(child: profilePicSnapshot.data),
                              );
                            },
                          ),
                          subtitle: FutureBuilder<String>(
                            future:
                                userService.getUserBioByUid(user['uid']),
                            builder: (context, bioSnapshot) {
                              if (bioSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text(
                                  'Loading bio...',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.navyColor.withOpacity(0.4),
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return Text(
                                bioSnapshot.data ?? 'No bio available',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.navyColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.tealColor,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfilePage(uid: user['uid']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
