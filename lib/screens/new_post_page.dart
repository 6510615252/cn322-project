import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:outstragram/services/storage_service.dart';
import 'package:provider/provider.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StorageService>().fetchImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageService>(
      builder: (context, storageService, child) {
        final List<String> imageUrls = storageService.imgUrls;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              try {
                await storageService.uploadImage();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Icon(Icons.add),
          ),
          body: storageService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final String imageUrl = imageUrls[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.network(imageUrl),
                    );
                  },
                ),
        );
      },
    );
  }
}
