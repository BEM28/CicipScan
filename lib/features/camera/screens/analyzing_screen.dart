import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:cicipscan/core/constants/app_lotties.dart';
import 'package:cicipscan/core/themes/app_themes.dart';
import 'package:cicipscan/domain/usecases/get_food_detail.dart';
import 'package:cicipscan/features/camera/providers/image_capture_provider.dart';
import 'package:cicipscan/features/result/providers/result_provider.dart';
import 'package:cicipscan/features/result/screens/result_detail_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  final File imageFile;

  const AnalyzingScreen({super.key, required this.imageFile});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage();
    });
  }

  Future<void> _processImage() async {
    final captureProvider = context.read<ImageCaptureProvider>();
    final getFoodDetail = context.read<GetFoodDetail>();

    // Start ML and API process
    await captureProvider.setImage(widget.imageFile);

    if (mounted) {
      // Navigate to result
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => ResultProvider(getFoodDetail: getFoodDetail),
            child: const ResultDetailScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AppLotties.loading,
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            Text(
              'Analyzing Food...',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Identifying ingredients and nutritional value',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
