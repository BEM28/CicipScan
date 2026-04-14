import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cicipscan/core/themes/app_themes.dart';
import 'package:cicipscan/features/camera/providers/crop_provider.dart';
import 'package:cicipscan/features/camera/providers/live_detection_provider.dart';
import 'package:cicipscan/features/camera/screens/crop_screen.dart';

class CameraViewScreen extends StatefulWidget {
  const CameraViewScreen({super.key});

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveDetectionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LiveDetectionProvider>();

    if (!provider.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                provider.error ?? 'Initializing Camera...',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CameraPreview(provider.controller!)),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              child: _LiveDetectionBanner(
                result: provider.liveResult,
                confidence: provider.liveConfidence,
              ),
            ),

            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    heroTag: 'back',
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  _ControlButton(
                    heroTag: 'gallery',
                    icon: Icons.photo_library_rounded,
                    onPressed: () => _onPickGallery(context),
                  ),
                  _ControlButton(
                    heroTag: 'capture',
                    icon: Icons.camera_rounded,
                    size: 64,
                    isPrimary: true,
                    onPressed: () => _onCapture(context),
                  ),
                  _ControlButton(
                    heroTag: 'switch_camera',
                    icon: Icons.flip_camera_ios_rounded,
                    onPressed: () {
                      context.read<LiveDetectionProvider>().switchCamera();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCapture(BuildContext context) async {
    final navigator = Navigator.of(context);
    final liveProvider = context.read<LiveDetectionProvider>();

    final photo = await liveProvider.capturePhoto();
    if (photo != null && mounted) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => CropProvider(),
            child: CropScreen(imageFile: photo),
          ),
        ),
      );
    }
  }

  Future<void> _onPickGallery(BuildContext context) async {
    final liveProvider = context.read<LiveDetectionProvider>();
    final navigator = Navigator.of(context);

    try {
      if (liveProvider.controller?.value.isStreamingImages ?? false) {
        await liveProvider.controller?.stopImageStream();
      }
    } catch (_) {}

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null && mounted) {
      final imageFile = File(pickedFile.path);
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => CropProvider(),
            child: CropScreen(imageFile: imageFile),
          ),
        ),
      );
    } else {
      if (mounted) {
        try {
          liveProvider.controller?.startImageStream((_) {});
        } catch (_) {}
      }
    }
  }
}

class _LiveDetectionBanner extends StatelessWidget {
  final String result;
  final double confidence;

  const _LiveDetectionBanner({required this.result, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toStringAsFixed(1);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Confidence: $pct%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isPrimary;

  const _ControlButton({
    required this.heroTag,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: heroTag,
        backgroundColor: isPrimary
            ? AppTheme.primary
            : Colors.black.withValues(alpha: 0.5),
        onPressed: onPressed,
        child: Icon(icon, color: Colors.white, size: isPrimary ? 30 : 22),
      ),
    );
  }
}
