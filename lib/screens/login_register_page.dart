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
    decoration: InputDecoration(labelText: title),
    obscureText: title.toLowerCase() == 'password'
  );
}

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Error: $errorMessage',
      style: TextStyle(color: Colors.red),
    );
  }

  Widget _submitButton() {
  return ElevatedButton(
    onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword, 
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF8AB2A6), // สีครีม
      foregroundColor: Colors.black, // สีข้อความบนปุ่ม
      padding: EdgeInsets.symmetric(vertical: 14), // เพิ่มความสูงของปุ่ม
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      isLogin ? "Login" : "Register",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}

  Widget _googleSignInButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.login, color: Colors.white),
      label: Text("Sign in with Google", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red, // ปรับสีให้เข้ากับ Google
      ),
      onPressed: signInWithGoogle,
    );
  }

  Widget _loginOrRegisterButton() {
  return TextButton(
    onPressed: () {
      setState(() {
        isLogin = !isLogin;
      });
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF8AB2A6), // สีครีม
      foregroundColor: Colors.black, // สีข้อความบนปุ่ม
      padding: EdgeInsets.symmetric(vertical: 14), // เพิ่มความสูงของปุ่ม
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(isLogin ? "Register instead" : "Login instead",
    style: TextStyle(
        fontWeight: FontWeight.bold, // เพิ่มความหนา
        color: Colors.black,          // ทำให้สีเข้มเหมือนปุ่ม login
      ),),
    
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            color: Color(0xFFF6F1DE),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "OUTRAGRAM",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isLogin ? "Login to your account" : "Create a new account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _entryField("Email", _controllerEmail),
                  const SizedBox(height: 12),
                  _entryField("Password", _controllerPassword),
                  const SizedBox(height: 16),
                  _errorMessage(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _submitButton(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("or"),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: _googleSignInButton(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity ,
                  child: _loginOrRegisterButton(),)
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
