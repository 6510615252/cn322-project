import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/authService.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();


  Future<void> signInWithEmailAndPassword() async {
    try {
      await Authservice().signInWithEmailAndPassword(
        email: _controllerEmail.text, 
        password: _controllerPassword.text
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Authservice().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    final userCredential = await Authservice().signInWithGoogle();
    if (userCredential == null) {
      setState(() {
        errorMessage = "Google Sign-In failed.";
      });
    }
  }

  Widget _title() {
    return const Text("Firebase Auth");
  }

  Widget _entryField(String title, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: title,
        labelStyle: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF8AB2A6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF8AB2A6), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      obscureText: title.toLowerCase() == 'password'
    );
  }

  Widget _errorMessage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Text(
        errorMessage == '' ? '' : 'Error: $errorMessage',
        style: TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword, 
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF8AB2A6),
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: Color(0x668AB2A6),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        isLogin ? "Login" : "Register",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _googleSignInButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.login, color: Colors.white, size: 20),
      label: Text(
        "Sign in with Google", 
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.w600,
          fontSize: 15,
        )
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.redAccent.withOpacity(0.4),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: signInWithGoogle,
    );
  }

  Widget _loginOrRegisterButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
          // เคลียร์ค่า error message เมื่อสลับโหมด
          errorMessage = '';
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Color(0xFF8AB2A6), width: 1.5),
        ),
      ),
      child: Text(
        isLogin ? "Register instead" : "Login instead",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              shadowColor: Colors.black26,
              color: Color(0xFFF6F1DE),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF8AB2A6).withOpacity(0.2),
                      ),
                      child: Icon(Icons.photo_camera, 
                        size: 50, 
                        color: Color(0xFF8AB2A6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "OUTRAGRAM",
                      style: TextStyle(
                        fontSize: 34, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isLogin ? "Login to your account" : "Create a new account",
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _entryField("Email", _controllerEmail),
                    const SizedBox(height: 16),
                    _entryField("Password", _controllerPassword),
                    const SizedBox(height: 16),
                    _errorMessage(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _submitButton(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(child: Divider(thickness: 1.5, color: Colors.black38)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            "or",
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(thickness: 1.5, color: Colors.black38)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _googleSignInButton(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _loginOrRegisterButton(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}