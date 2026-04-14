import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cicipscan/data/models/food_detail_model.dart';
import 'package:cicipscan/data/services/gemini_service.dart';

abstract class FoodRemoteDataSource {
  Future<FoodDetailModel> fetchFoodDetail(String label);
}

class FoodRemoteDataSourceImpl implements FoodRemoteDataSource {
  final String _geminiApiKey;

  FoodRemoteDataSourceImpl({required String geminiApiKey})
    : _geminiApiKey = geminiApiKey;

  static const _systemInstruction = '''
# Gemini API Prompt Instruction
**Role**: You are an expert nutritionist and professional chef. Your task is to provide comprehensive data for a specific food item detected by an AI scanner.
**Input**: The name/label of a food item.
**Output Format**: Strictly return a single JSON object. Do not include any markdown formatting, preamble, or explanation.
**Requirement**: Populate the following fields with accurate information based on a standard serving size:
```json
{
  "name": "[Input Label]",
  "description": "A concise, appetizing description of the dish (max 2 sentences).",
  "calories": [integer value, total calories],
  "dailyIntakePercent": [integer value, percentage of 2000kcal RDA],
  "protein": "[string with 'g' unit, e.g., '15g']",
  "carbs": "[string with 'g' unit]",
  "fat": "[string with 'g' unit]",
  "fiber": "[string with 'g' unit]",
  "vitamins": [
    {
      "name": "[Vitamin or Mineral Name, capitalized]",
      "percentage": "[Daily Value percentage, e.g., '15%']"
    }
  ],
  "healthInsight": "A brief health benefit or interesting nutritional fact (max 2 sentences).",
  "ingredients": [
    {
      "name": "[Ingredient name]",
      "amount": "[Quantity with unit, e.g. '100g' or '1 unit']"
    }
  ],
  "instructions": [
    "Step 1...",
    "Step 2..."
  ]
}
```

**Constraints**:
- Ensure `calories` and `dailyIntakePercent` are integers.
- Ensure all other numerical values are strings with units (g, %, etc.).
- Provide at least 3 vitamins/minerals and at least 5 ingredients.
- Keep instructions clear and numbered.
''';

  static final model = dotenv.env['GEMINI_MODEL'] ?? '';
  @override
  Future<FoodDetailModel> fetchFoodDetail(String label) async {
    String? category;
    String? area;
    String? imageUrl;
    String? youtubeUrl;
    String? mealName;
    List<IngredientItem>? mealDbIngredients;
    List<String>? mealDbInstructions;

    // 1. Fetch from MealDB
    try {
      final url = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=$label',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
          final meal = data['meals'][0];

          mealName = meal['strMeal'];
          category = meal['strCategory'];
          area = meal['strArea'];
          imageUrl = meal['strMealThumb'];
          youtubeUrl = meal['strYoutube'];

          List<IngredientItem> ingredients = [];
          for (int i = 1; i <= 20; i++) {
            final ingredient = meal['strIngredient$i'];
            final measure = meal['strMeasure$i'];
            if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
              ingredients.add(
                IngredientItem(
                  name: ingredient.toString().trim(),
                  amount: measure?.toString().trim() ?? '',
                ),
              );
            }
          }
          if (ingredients.isNotEmpty) mealDbIngredients = ingredients;

          if (meal['strInstructions'] != null) {
            mealDbInstructions = meal['strInstructions']
                .toString()
                .split(RegExp(r'\r\n|\n'))
                .where((line) => line.trim().isNotEmpty)
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching from MealDB: $e');
    }

    // 2. Fetch from Gemini
    try {
      final geminiResponse = await GeminiService.callGeminiApi(label, {
        'key': _geminiApiKey,
        'model': model,
        'instructions': _systemInstruction,
      });

      if (geminiResponse != null && geminiResponse != 'ERROR_LIMIT_REACHED') {
        final startIndex = geminiResponse.indexOf('{');
        final endIndex = geminiResponse.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
          final cleanJson = geminiResponse.substring(startIndex, endIndex + 1);
          final Map<String, dynamic> aiData = json.decode(cleanJson);

          final aiVitamins =
              (aiData['vitamins'] as List?)?.map((v) {
                return VitaminItem(
                  name: v['name']?.toString() ?? '',
                  percentage: v['percentage']?.toString() ?? '',
                );
              }).toList() ??
              [];

          final aiIngredients =
              (aiData['ingredients'] as List?)?.map((i) {
                return IngredientItem(
                  name: i['name']?.toString() ?? '',
                  amount: i['amount']?.toString() ?? '',
                );
              }).toList() ??
              [];

          final aiInstructions =
              (aiData['instructions'] as List?)
                  ?.map((i) => i.toString())
                  .toList() ??
              [];

          return FoodDetailModel(
            name: mealName ?? aiData['name'] ?? label,
            description:
                aiData['description'] ??
                'A freshly prepared serving of $label.',
            calories: (aiData['calories'] as num?)?.toInt() ?? 0,
            dailyIntakePercent:
                (aiData['dailyIntakePercent'] as num?)?.toInt() ?? 0,
            protein: aiData['protein']?.toString() ?? '-',
            carbs: aiData['carbs']?.toString() ?? '-',
            fat: aiData['fat']?.toString() ?? '-',
            fiber: aiData['fiber']?.toString() ?? '-',
            vitamins: aiVitamins.isNotEmpty
                ? aiVitamins
                : const [
                    VitaminItem(name: 'VITAMIN A', percentage: '15%'),
                    VitaminItem(name: 'VITAMIN C', percentage: '10%'),
                    VitaminItem(name: 'CALCIUM', percentage: '8%'),
                  ],
            healthInsight:
                aiData['healthInsight'] ??
                'This food contains essential nutrients beneficial for a balanced diet.',
            ingredients:
                mealDbIngredients ??
                (aiIngredients.isNotEmpty
                    ? aiIngredients
                    : [IngredientItem(name: '$label base', amount: '200g')]),
            instructions:
                mealDbInstructions ??
                (aiInstructions.isNotEmpty
                    ? aiInstructions
                    : ['Prepare all fresh ingredients for $label.']),
            category: category,
            area: area,
            imageUrl: imageUrl,
            youtubeUrl: youtubeUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching from Gemini: $e');
    }

    // 3. Ultimate Fallback
    return FoodDetailModel(
      name: mealName ?? label,
      description:
          'A freshly prepared serving of $label. This description is generated as dummy data.',
      calories: 320,
      dailyIntakePercent: 16,
      protein: '14g',
      carbs: '38g',
      fat: '12g',
      fiber: '5g',
      vitamins: const [
        VitaminItem(name: 'VITAMIN A', percentage: '15%'),
        VitaminItem(name: 'VITAMIN C', percentage: '10%'),
        VitaminItem(name: 'CALCIUM', percentage: '8%'),
      ],
      healthInsight:
          'This $label contains essential nutrients beneficial for a balanced diet.',
      ingredients:
          mealDbIngredients ??
          [
            IngredientItem(name: '$label base', amount: '200g'),
            IngredientItem(name: 'Seasonings', amount: 'to taste'),
            IngredientItem(name: 'Garnish', amount: '10g'),
          ],
      instructions:
          mealDbInstructions ??
          [
            'Prepare all fresh ingredients for $label.',
            'Follow traditional cooking methods for best flavor.',
            'Serve warm with your favorite side dish.',
          ],
      category: category,
      area: area,
      imageUrl: imageUrl,
      youtubeUrl: youtubeUrl,
    );
  }
}
