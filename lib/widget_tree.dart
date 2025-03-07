import 'package:flutter/material.dart';
import 'package:outstragram/auth.dart';
import 'package:outstragram/main.dart';
import 'package:outstragram/pages/home_page.dart';
import 'package:outstragram/pages/login_register_page.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}