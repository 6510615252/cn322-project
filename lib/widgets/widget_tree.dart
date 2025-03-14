import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:outstragram/main.dart';
import 'package:outstragram/screens/home_page.dart';
import 'package:outstragram/services/authService.dart';
import 'package:outstragram/services/userService.dart';
import 'package:outstragram/screens/login_register_page.dart';
import 'package:outstragram/screens/profile_setup_page.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Authservice().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final User user = snapshot.data!; // ดึง user object

          return FutureBuilder<Map<String, dynamic>?>(
            future: UserService().fetchUserData(user.uid), // ดึงข้อมูลผู้ใช้จาก Firestore
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator()); // แสดง Loading ระหว่างโหลดข้อมูล
              }

              if (userSnapshot.hasData) {
                final userData = userSnapshot.data!;
                final username = userData['name'] ?? 'Unknown User';

                // ถ้า username เป็น 'Unknown User' หรือยังไม่มีข้อมูลใน Firestore
                if (username == 'Unknown User') {
                  return ProfileSetupPage(user: user); // ไปหน้า Profile Setup
                }

                return MainScreen(); // ถ้ามี user อยู่แล้วให้ไปหน้า main
              } else {
                return HomePage();
              }
            },
          );
        } else {
          return const LoginPage(); // ถ้ายังไม่มีผู้ใช้ให้ไปหน้า Login
        }
      },
    );
  }
}
