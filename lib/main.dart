import 'package:flutter/material.dart';
import 'package:outstragram/feed.dart';



void main() {
  var app = MaterialApp(
    title: "My title",
    home: Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 200, 255),
      appBar: AppBar(
        title: const Text("Outragram"),
      ),
      body: Feed(),
    )
  );
  runApp(app);
}

