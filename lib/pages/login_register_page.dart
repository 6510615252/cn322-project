import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';

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
  final TextEditingController _controllerUsername = TextEditingController();


  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
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
    await Auth().createUserWithEmailAndPassword(
      email: _controllerEmail.text,
      password: _controllerPassword.text,
      username: _controllerUsername.text, // เพิ่ม username
    );
  } on FirebaseAuthException catch (e) {
    setState(() {
      errorMessage = e.message;
    });
  }
}

  Future<void> signInWithGoogle() async {
    final userCredential = await Auth().signInWithGoogle();
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
      child: Text(isLogin ? "Login" : "Register"),
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
      child: Text(isLogin ? "Register instead" : "Login instead"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!isLogin) _entryField("Username", _controllerUsername),
            _entryField("email", _controllerEmail),
            _entryField("password", _controllerPassword),
            _errorMessage(),
            _submitButton(),
            _googleSignInButton(), 
            _loginOrRegisterButton(),
          ],
        )
      ),
    );
  }
}
