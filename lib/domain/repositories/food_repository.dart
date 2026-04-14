import 'package:cicipscan/data/models/food_detail_model.dart';

abstract class FoodRepository {
  Future<FoodDetailModel> getFoodDetailByLabel(String label);
}
