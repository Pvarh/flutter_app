import 'package:flutter/material.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart'; // Import knižnice photo_view

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PhotoView(
        // Oprava: pristupujeme priamo k 'imagePath', nie 'widget.imagePath'
        imageProvider: FileImage(File(imagePath)), // <--- OPRAVENÉ TU

        backgroundDecoration: const BoxDecoration(color: Colors.black),

        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),

        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
        ),

        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2.5,
        enableRotation: false,
      ),
    );
  }
}