import 'dart:io';
import 'package:flutter/material.dart';
import 'package:crop_image/crop_image.dart';
import 'package:provider/provider.dart';
import 'package:cicipscan/core/themes/app_themes.dart';
import 'package:cicipscan/features/camera/providers/crop_provider.dart';
import 'package:cicipscan/features/camera/screens/analyzing_screen.dart';

class CropScreen extends StatelessWidget {
  final File imageFile;

  const CropScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    final cropProvider = context.watch<CropProvider>();
    final bool isProcessing = cropProvider.isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!isProcessing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _handleCrop(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(20.0),
                child: CropImage(
                  controller: cropProvider.controller,
                  image: Image.file(imageFile),
                  paddingSize: 20.0,
                  alwaysMove: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isProcessing
                  ? const CircularProgressIndicator(color: AppTheme.primary)
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _handleCrop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Crop and Save',
                          style: TextStyle(
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
    );
  }

  Future<void> _handleCrop(BuildContext context) async {
    final cropProvider = context.read<CropProvider>();
    final navigator = Navigator.of(context);

    final croppedFile = await cropProvider.cropImage();

    if (croppedFile != null) {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnalyzingScreen(imageFile: croppedFile),
        ),
      );
    } else {
      debugPrint('Cropping failed — no file returned.');
    }
  }
}
