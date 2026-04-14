import 'dart:io';
import 'package:cicipscan/core/themes/app_themes.dart';
import 'package:cicipscan/features/result/providers/result_provider.dart';
import 'package:cicipscan/features/result/screens/result_detail_screen.dart';
import 'package:cicipscan/data/models/scan_result_model.dart';
import 'package:cicipscan/domain/usecases/get_food_detail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecentScanCard extends StatelessWidget {
  final String title;
  final String time;
  final String imagePath;
  final String score;
  final ScanResultModel? scanResult;

  const RecentScanCard({
    super.key,
    required this.title,
    required this.time,
    required this.imagePath,
    required this.score,
    this.scanResult,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ChangeNotifierProvider(
              create: (_) {
                final getFoodDetail = context.read<GetFoodDetail>();
                return ResultProvider(getFoodDetail: getFoodDetail);
              },
              child: ResultDetailScreen(scanResult: scanResult),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Food Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: imagePath.startsWith('assets/')
                        ? AssetImage(imagePath) as ImageProvider
                        : FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Score Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  score,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
