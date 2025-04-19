import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/services/userService.dart';


class AppTheme {
  static const Color creamColor = Color(0xFFF5F0DC);
  static const Color navyColor = Color(0xFF363B5C);
  static const Color tealColor = Color(0xFF8BB3A8);
  static const Color lightGreenColor = Color(0xFFB4DBA0);
}
class ManageCloseFriendsButton extends StatefulWidget {
  final String? uid;

   ManageCloseFriendsButton({super.key, String? uid})
      : uid = uid ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  _ManageCloseFriendsButtonState createState() => _ManageCloseFriendsButtonState();
  
}

class _ManageCloseFriendsButtonState extends State<ManageCloseFriendsButton> {
  final UserService _userService = UserService();
  List<String> _closeFriends = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCloseFriends();
  }

  Future<void> _loadCloseFriends() async {
    try {
      List<String> closeFriends =
          await _userService.getCloseFriends(widget.uid!);
      if (mounted) {
        setState(() {
          _closeFriends = closeFriends;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading close friends: $e")),
        );
      }
    }
  }

  Future<void> _addToCloseFriends(List<String> selectedUsers) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.addCloseFriends(widget.uid!, selectedUsers);
      if (mounted) {
        setState(() {
          _closeFriends.addAll(selectedUsers);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Close friends updated successfully!"),
            backgroundColor: AppTheme.navyColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding close friends: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddCloseFriendsDialog() async {
    List<String> selectedUsers = [];

    List<String> followingUsers =
        await _userService.getFollowingUsers(widget.uid);

    if (!mounted) return; // Check if the widget is still in the tree

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
                    _loadCloseFriends();
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showAddCloseFriendsDialog,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.tealColor),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group, color: AppTheme.tealColor),
            const SizedBox(width: 8),
            const Text(
              "Manage Close Friends",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.tealColor,
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tealColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}