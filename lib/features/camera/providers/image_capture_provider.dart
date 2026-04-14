import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:cicipscan/data/ml/ml_service.dart';
import 'package:cicipscan/data/models/food_detail_model.dart';
import 'package:cicipscan/data/models/scan_result_model.dart';
import 'package:cicipscan/data/services/database_service.dart';
import 'package:cicipscan/data/services/image_picker_service.dart';
import 'package:cicipscan/domain/usecases/get_food_detail.dart';

class ImageCaptureProvider with ChangeNotifier {
  final ImagePickerService _pickerService;
  final MLService _mlService;
  final DatabaseService _databaseService;
  final GetFoodDetail _getFoodDetail;

  File? _image;
  bool _isLoading = false;
  String? _error;
  String? _detectionResult;
  double? _confidenceScore;
  FoodDetailModel? _foodDetail;

  File? get image => _image;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get detectionResult => _detectionResult;
  double? get confidenceScore => _confidenceScore;
  FoodDetailModel? get foodDetail => _foodDetail;

  ImageCaptureProvider({
    required ImagePickerService pickerService,
    required MLService mlService,
    required DatabaseService databaseService,
    required GetFoodDetail getFoodDetail,
  }) : _pickerService = pickerService,
       _mlService = mlService,
       _databaseService = databaseService,
       _getFoodDetail = getFoodDetail {
    _initML();
  }

  Future<void> _initML() async {
    try {
      await _mlService.init();
    } catch (e) {
      _error = "Failed to initialize ML models: $e";
      notifyListeners();
    }
  }

  Future<File?> pickImage(ImageSource source) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    File? file;
    try {
      final pickedFile = await _pickerService.pickImage(source);
      if (pickedFile != null) {
        file = File(pickedFile.path);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return file;
  }

  Future<void> setImage(File image) async {
    _image = image;
    _isLoading = true;
    _foodDetail = null;
    _error = null;
    notifyListeners();

    try {
      // Ensure ML service is ready
      if (!_mlService.isInitialized) {
        await _mlService.init();
      }

      final result = await _mlService.runInference(_image!);
      _detectionResult = result.label;
      _confidenceScore = result.confidence;

      // Look up the full food detail data using Clean Architecture UseCase
      _foodDetail = await _getFoodDetail.execute(result.label);

      final scanResult = ScanResultModel(
        title: _detectionResult ?? 'Unknown',
        score: _confidenceScore != null
            ? '${(_confidenceScore! * 100).toStringAsFixed(0)}/100'
            : '0/100',
        imagePath: _image!.path,
        timestamp: DateTime.now(),
      );
      if (_detectionResult != 'Unlisted Food' &&
          _detectionResult != 'No identity detected') {
        await _databaseService.insertScanResult(scanResult);
      }
    } catch (e, stackTrace) {
      debugPrint('ML Inference Error: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = e.toString();
      _detectionResult = 'Error: $e';
      _confidenceScore = 0.0;
      _foodDetail = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
