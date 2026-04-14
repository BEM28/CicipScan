import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cicipscan/core/themes/app_themes.dart';
import 'package:cicipscan/data/datasources/food_remote_data_source.dart';
import 'package:cicipscan/data/ml/ml_service.dart';
import 'package:cicipscan/data/repositories/food_repository_impl.dart';
import 'package:cicipscan/data/services/database_service.dart';
import 'package:cicipscan/data/services/image_picker_service.dart';
import 'package:cicipscan/data/services/theme_service.dart';
import 'package:cicipscan/domain/usecases/get_food_detail.dart';
import 'package:cicipscan/features/camera/providers/image_capture_provider.dart';
import 'package:cicipscan/features/dashboard/screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mlService = MLService();
    final databaseService = DatabaseService();
    final imagePickerService = ImagePickerService();

    final foodRemoteDataSource = FoodRemoteDataSourceImpl(
      geminiApiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
    );

    final foodRepository = FoodRepositoryImpl(
      remoteDataSource: foodRemoteDataSource,
    );

    final getFoodDetailUseCase = GetFoodDetail(foodRepository);

    return MultiProvider(
      providers: [
        Provider<GetFoodDetail>.value(value: getFoodDetailUseCase),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(
          create: (_) => ImageCaptureProvider(
            pickerService: imagePickerService,
            mlService: mlService,
            databaseService: databaseService,
            getFoodDetail: getFoodDetailUseCase,
          ),
        ),
      ],
      child: const _App(),
    );
  }
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDark;

    return MaterialApp(
      title: 'CicipScan!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const DashboardScreen(),
    );
  }
}
