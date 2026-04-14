class IngredientItem {
  final String name;
  final String amount;

  const IngredientItem({required this.name, required this.amount});
}

class VitaminItem {
  final String name;
  final String percentage;

  const VitaminItem({required this.name, required this.percentage});
}

class FoodDetailModel {
  final String name;
  final String description;

  final int calories;
  final int dailyIntakePercent;
  final String protein;
  final String carbs;
  final String fat;
  final String fiber;

  final List<VitaminItem> vitamins;

  final String healthInsight;

  final List<IngredientItem> ingredients;

  final List<String> instructions;

  final String? category;
  final String? area;
  final String? imageUrl;
  final String? youtubeUrl;

  const FoodDetailModel({
    required this.name,
    required this.description,
    required this.calories,
    required this.dailyIntakePercent,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.vitamins,
    required this.healthInsight,
    required this.ingredients,
    required this.instructions,
    this.category,
    this.area,
    this.imageUrl,
    this.youtubeUrl,
  });
}
