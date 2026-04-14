import 'package:cicipscan/data/models/food_detail_model.dart';
import 'package:cicipscan/domain/repositories/food_repository.dart';

class GetFoodDetail {
  final FoodRepository repository;

  GetFoodDetail(this.repository);

  Future<FoodDetailModel> execute(String label) {
    return repository.getFoodDetailByLabel(label);
  }
}
