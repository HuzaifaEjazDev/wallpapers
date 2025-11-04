import 'package:flutter/material.dart';
import '../widgets/cached_image.dart';

class WallpaperDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String category;

  const WallpaperDetailScreen({
    super.key,
    required this.imageUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Stack(
            children: [
              // Full-screen image
              Center(
                child: CachedImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              // Back button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              // Category label
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}