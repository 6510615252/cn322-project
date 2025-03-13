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

  /// Fetches all images from Firebase Storage
  Future<void> fetchImages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final ListResult result = await _firebaseStorage.ref('uploads').listAll();
      _imgUrls.clear();
      for (var ref in result.items) {
        final url = await ref.getDownloadURL();
        _imgUrls.add(url);
      }
    } catch (e) {
      debugPrint('Error fetching images: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      Reference ref = _firebaseStorage.ref('posts_pic/${DateTime.now().millisecondsSinceEpoch}');

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

  /// Deletes an image from Firebase Storage
  Future<void> deleteImage(String url) async {
    try {
      _imgUrls.remove(url);

      final String path = _extractPathFromUrl(url);
      await _firebaseStorage.ref(path).delete();
    } catch (e) {
      print("❌ Error deleting image: $e");
    }

    notifyListeners();
  }

  /// Uploads an image to Firebase Storage
  

  /// Extracts the file path from a Firebase Storage URL
  String _extractPathFromUrl(String url) {
    Uri uri = Uri.parse(url);
    return Uri.decodeComponent(uri.pathSegments.last);
  }
}