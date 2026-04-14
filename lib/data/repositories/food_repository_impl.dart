import 'package:cicipscan/data/models/food_detail_model.dart';
import 'package:cicipscan/domain/repositories/food_repository.dart';
import 'package:cicipscan/data/datasources/food_remote_data_source.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodRemoteDataSource remoteDataSource;

  FoodRepositoryImpl({required this.remoteDataSource});

  @override
  Future<FoodDetailModel> getFoodDetailByLabel(String label) async {
    return await remoteDataSource.fetchFoodDetail(label);
  }
}
