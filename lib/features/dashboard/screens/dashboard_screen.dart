import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cicipscan/core/constants/app_images.dart';
import 'package:cicipscan/core/themes/app_themes.dart';
import 'package:cicipscan/core/widgets/recent_scan_card.dart';
import 'package:cicipscan/data/models/scan_result_model.dart';
import 'package:cicipscan/data/services/database_service.dart';
import 'package:cicipscan/data/services/theme_service.dart';
import 'package:cicipscan/features/camera/providers/live_detection_provider.dart';
import 'package:cicipscan/features/camera/screens/camera_view_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<ScanResultModel> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final scans = await _databaseService.getScanResults();
    if (mounted) {
      setState(() {
        _recentScans = scans;
      });
    }
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} mins ago';
    } else {
      return 'Just now';
    }
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LiveDetectionProvider(),
          child: const CameraViewScreen(),
        ),
      ),
    ).then((_) {
      _loadRecentScans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = context.watch<ThemeService>();
    final bool isDark = themeService.isDark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1B261C), const Color(0xFF121212)]
                    : [const Color(0xFFF0F8F1), Colors.white],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    // Logo Section
                    Center(
                      child: Image.asset(AppImages.logo, fit: BoxFit.contain),
                    ),
                    // Title
                    Center(
                      child: Text(
                        'Cicip Scan!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium,
                      ),
                    ),
                    // Subtitle
                    Center(
                      child: Text(
                        'Scan your food instantly',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Button — directly opens live camera
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () => _openScanner(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppTheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: const Text(
                            'Start Scanning',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Recent Scans Section
                    Text(
                      'Recent Scans',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Recent Scans List
                    _recentScans.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No recent scans.'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentScans.length,
                            itemBuilder: (context, index) {
                              final scan = _recentScans[index];
                              return RecentScanCard(
                                title: scan.title,
                                time: _formatTime(scan.timestamp),
                                imagePath: scan.imagePath,
                                score: scan.score,
                                scanResult: scan,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
          // Theme Toggle Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: GestureDetector(
              onTap: () => context.read<ThemeService>().toggleTheme(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? Colors.orangeAccent : Colors.indigoAccent,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
