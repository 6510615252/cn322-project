import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService extends ChangeNotifier {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  // State variables
  List<String> _imgUrls = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // Getters
  List<String> get imgUrls => _imgUrls;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  Future<void> uploadImage(bool isPrivate, String postId) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      Reference ref;
      if (isPrivate) {
        ref = _firebaseStorage.ref('secret_post_pic/$postId');
      } else {
        ref = _firebaseStorage.ref('post_pic/$postId');
      }

      if (kIsWeb) {
        Uint8List imageData = await pickedFile.readAsBytes();
        await ref.putData(imageData);
      } else {
        File file = File(pickedFile.path);
        await ref.putFile(file);
      }

      final String downloadUrl = await ref.getDownloadURL();
      _imgUrls.add(downloadUrl);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Upload Error: $e');
    }
  }
}