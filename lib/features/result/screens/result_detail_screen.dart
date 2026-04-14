import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cicipscan/core/constants/app_images.dart';
import 'package:cicipscan/core/themes/app_themes.dart';
import 'package:cicipscan/data/models/food_detail_model.dart';
import 'package:cicipscan/data/models/scan_result_model.dart';
import 'package:cicipscan/features/camera/providers/image_capture_provider.dart';
import 'package:cicipscan/features/result/providers/result_provider.dart';
import 'package:cicipscan/core/constants/app_lotties.dart';
import 'package:lottie/lottie.dart';

class ResultDetailScreen extends StatefulWidget {
  final ScanResultModel? scanResult;
  const ResultDetailScreen({super.key, this.scanResult});

  @override
  State<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends State<ResultDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final resultProvider = context.read<ResultProvider>();
    final imageProvider = context.read<ImageCaptureProvider>();

    if (widget.scanResult != null) {
      resultProvider.fetchFoodDetail(widget.scanResult!.title);
    } else {
      final displayTitle = imageProvider.detectionResult ?? 'Unknown Identity';
      resultProvider.fetchFoodDetail(
        displayTitle,
        preloadedData: imageProvider.foodDetail,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultProvider = context.watch<ResultProvider>();
    final imageProvider = context.watch<ImageCaptureProvider>();
    final int selectedTabIndex = resultProvider.selectedTabIndex;
    final theme = Theme.of(context);

    if (widget.scanResult == null && imageProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              Text('Analyzing Food...', style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
      );
    }

    final displayImage = widget.scanResult != null
        ? FileImage(File(widget.scanResult!.imagePath)) as ImageProvider
        : (imageProvider.image != null
              ? FileImage(imageProvider.image!) as ImageProvider
              : const AssetImage(AppImages.logo));

    final String displayScore = widget.scanResult != null
        ? widget.scanResult!.score
        : '${((imageProvider.confidenceScore ?? 0) * 100).toStringAsFixed(1)}/100';

    final String displayTitle = widget.scanResult != null
        ? widget.scanResult!.title
        : (imageProvider.detectionResult ?? 'Unknown Identity');

    final bool isNoMatch =
        displayTitle == 'Unlisted Food' ||
        displayTitle == 'No identity detected';

    if (isNoMatch) {
      return _buildNoMatchView(context, displayTitle, theme);
    }

    if (resultProvider.isLoading || resultProvider.foodDetail == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
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
            ],
          ),
        ),
      );
    }

    final foodDetail = resultProvider.foodDetail!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageHeader(
                displayImage: displayImage,
                displayScore: displayScore,
                theme: theme,
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (foodDetail.area != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              foodDetail.area!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (foodDetail.category != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        foodDetail.category!.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      foodDetail.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTabItem(context, 'Overview', 0, selectedTabIndex),
                    _buildTabItem(context, 'Ingredients', 1, selectedTabIndex),
                    _buildTabItem(context, 'Instructions', 2, selectedTabIndex),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildTabContent(selectedTabIndex, context, foodDetail),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoMatchView(
    BuildContext context,
    String displayTitle,
    ThemeData theme,
  ) {
    final bool isUnlisted = displayTitle == 'Unlisted Food';
    final String headline = isUnlisted
        ? 'Oops! Food not recognized'
        : 'Unable to analyze';
    final String body = isUnlisted
        ? 'We could not identify this food.\n'
              'Please try again or scan another food.'
        : 'Confidence is too low.\n'
              'Try again with better lighting or a closer view.';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(AppLotties.noData, width: 250, height: 250),
              const SizedBox(height: 24),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    String title,
    int index,
    int selectedIndex,
  ) {
    final bool active = selectedIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        context.read<ResultProvider>().setTabIndex(index);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: active ? AppTheme.primary : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    int selectedIndex,
    BuildContext context,
    FoodDetailModel detail,
  ) {
    switch (selectedIndex) {
      case 0:
        return _OverviewTab(detail: detail);
      case 1:
        return _IngredientsTab(detail: detail);
      case 2:
        return _InstructionsTab(detail: detail);
      default:
        return _OverviewTab(detail: detail);
    }
  }
}

// ───────────────────────────────────────────────────
// EXTRACTED WIDGETS
// ───────────────────────────────────────────────────

class _ImageHeader extends StatelessWidget {
  final ImageProvider displayImage;
  final String displayScore;
  final ThemeData theme;

  const _ImageHeader({
    required this.displayImage,
    required this.displayScore,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            image: DecorationImage(image: displayImage, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          bottom: 25,
          right: 25,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONFIDENCE', style: theme.textTheme.bodySmall),
                    Text(displayScore, style: theme.textTheme.bodyLarge),
                  ],
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppTheme.whiteScaffold,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final FoodDetailModel detail;

  const _OverviewTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _EnergyCard(detail: detail),
        ),

        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MacroCard(
                      label: 'PROTEIN',
                      value: detail.protein,
                      icon: Icons.fitness_center_rounded,
                      bgColor: const Color(0xFFE8F5E9),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MacroCard(
                      label: 'CARBS',
                      value: detail.carbs,
                      icon: Icons.grain_rounded,
                      bgColor: const Color(0xFFF1F8E9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MacroCard(
                      label: 'FAT',
                      value: detail.fat,
                      icon: Icons.water_drop_rounded,
                      bgColor: const Color(0xFFFCE4EC),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MacroCard(
                      label: 'FIBER',
                      value: detail.fiber,
                      icon: Icons.eco_rounded,
                      bgColor: const Color(0xFFF1F8E9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Vitamins & Minerals
        if (detail.vitamins.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Vitamins & Minerals',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: detail.vitamins
                  .map(
                    (v) => _VitaminChip(name: v.name, percentage: v.percentage),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 40),
        ],

        // Health Insight Card
        if (detail.healthInsight.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HealthInsightCard(insight: detail.healthInsight),
          ),
      ],
    );
  }
}

class _EnergyCard extends StatelessWidget {
  final FoodDetailModel detail;

  const _EnergyCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'TOTAL ENERGY',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${detail.calories}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.orange.withValues(alpha: 0.15),
                size: 70,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${detail.dailyIntakePercent}%'
            ' OF YOUR DAILY INTAKE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bgColor;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.primary, size: 26),
          ),
          const SizedBox(height: 18),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _VitaminChip extends StatelessWidget {
  final String name;
  final String percentage;

  const _VitaminChip({required this.name, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            percentage,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthInsightCard extends StatelessWidget {
  final String insight;

  const _HealthInsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health Insight',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.6,
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

class _IngredientsTab extends StatelessWidget {
  final FoodDetailModel detail;

  const _IngredientsTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredients = detail.ingredients;

    if (ingredients.isEmpty) {
      return Padding(
        key: const ValueKey(1),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No ingredient data available.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Ingredients List',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: ingredients.length,
          separatorBuilder: (_, _) =>
              Divider(color: Colors.grey[100], height: 1),
          itemBuilder: (_, index) {
            final item = ingredients[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item.amount,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InstructionsTab extends StatelessWidget {
  final FoodDetailModel detail;

  const _InstructionsTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = detail.instructions;

    if (steps.isEmpty) {
      return Padding(
        key: const ValueKey(2),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No instructions available.',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Preparation Steps',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: steps.length,
          itemBuilder: (_, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[400],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          steps[index],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
