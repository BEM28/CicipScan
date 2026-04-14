import 'package:flutter/material.dart';
import 'package:cicipscan/data/models/food_detail_model.dart';
import 'package:cicipscan/domain/usecases/get_food_detail.dart';

class ResultProvider extends ChangeNotifier {
  final GetFoodDetail _getFoodDetail;

  int _selectedTabIndex = 0;
  bool _isLoading = false;
  String? _error;
  FoodDetailModel? _foodDetail;

  ResultProvider({required GetFoodDetail getFoodDetail})
    : _getFoodDetail = getFoodDetail;

  int get selectedTabIndex => _selectedTabIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  FoodDetailModel? get foodDetail => _foodDetail;

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  Future<void> fetchFoodDetail(
    String label, {
    FoodDetailModel? preloadedData,
  }) async {
    // If preloaded data exists from previous screen (like ImageCapture), use it directly.
    if (preloadedData != null) {
      _foodDetail = preloadedData;
      notifyListeners();
      return;
    }

    // Otherwise, fetch it.
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _foodDetail = await _getFoodDetail.execute(label);
    } catch (e) {
      _error = 'Failed to load details. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
