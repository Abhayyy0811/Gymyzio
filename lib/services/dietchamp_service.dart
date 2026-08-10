import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/dietchamp_model.dart';

class DietChampService {
  static const String _assetPath = 'assets/data/dietchamp_plans.json';
  static Map<String, dynamic>? _cachedJson;

  /// Loads and parses local JSON asset offline
  static Future<DietPlan> fetchDietPlan({
    required String preference,
    required double weightKg,
    required String goal,
  }) async {
    try {
      if (_cachedJson == null) {
        final jsonString = await rootBundle.loadString(_assetPath);
        _cachedJson = jsonDecode(jsonString) as Map<String, dynamic>?;
      }

      final weightCategory = _calculateWeightCategory(weightKg);
      final key = '${preference}_${weightCategory}_$goal';

      final plansMap = _cachedJson?['plans'] as Map<String, dynamic>?;
      if (plansMap != null && plansMap.containsKey(key)) {
        return DietPlan.fromJson(plansMap[key] as Map<String, dynamic>);
      }

      // If exact key is not pre-configured in JSON, dynamically synthesize a smart fallback plan
      return _generateDynamicFallbackPlan(preference, weightKg, weightCategory, goal);
    } catch (e) {
      // Safe fallback on any IO/parsing error
      final weightCategory = _calculateWeightCategory(weightKg);
      return _generateDynamicFallbackPlan(preference, weightKg, weightCategory, goal);
    }
  }

  static String _calculateWeightCategory(double weightKg) {
    if (weightKg < 55.0) return 'W1';
    if (weightKg <= 70.0) return 'W2';
    if (weightKg <= 85.0) return 'W3';
    return 'W4';
  }

  static DietPlan _generateDynamicFallbackPlan(
    String preference,
    double weightKg,
    String weightCategory,
    String goal,
  ) {
    int baseCal = 1800;
    if (weightCategory == 'W1') baseCal = 1500;
    if (weightCategory == 'W2') baseCal = 1800;
    if (weightCategory == 'W3') baseCal = 2150;
    if (weightCategory == 'W4') baseCal = 2450;

    if (goal == 'Fat Loss') baseCal = (baseCal * 0.85).round();
    if (goal == 'Muscle Gain') baseCal = (baseCal * 1.20).round();

    final proteinGrams = (weightKg * (goal == 'Muscle Gain' ? 2.0 : 1.6)).round();
    final fatsGrams = (weightKg * 0.8).round();
    final carbsGrams = ((baseCal - (proteinGrams * 4) - (fatsGrams * 9)) / 4).round().clamp(100, 400);

    final isNonVeg = preference == 'Non-Veg';
    final isEgg = preference == 'Eggetarian';
    final isVegan = preference == 'Vegan';

    return DietPlan(
      preference: preference,
      weightCategory: weightCategory,
      goal: goal,
      description: 'Customized $preference $goal meal strategy for $weightCategory category ($weightKg kg).',
      meals: {
        'breakfast': DietMeal(
          title: isNonVeg
              ? 'Egg White Omelette & Toast 🍳'
              : (isVegan ? 'Tofu Scramble & Oats 🍳' : 'High Protein Oats & Berries 🍳'),
          items: [
            DietMealItem(
              name: isNonVeg
                  ? '3 Egg Whites + 1 Whole Egg Scramble'
                  : (isVegan ? '120g Turmeric Tofu Scramble' : '120g Low-Fat Paneer Bhurji'),
              calories: (baseCal * 0.14).round(),
              protein: (proteinGrams * 0.16).round(),
              carbs: 4,
              fats: 6,
            ),
            DietMealItem(
              name: '2 Slices Whole Grain Toast',
              calories: (baseCal * 0.08).round(),
              protein: (proteinGrams * 0.06).round(),
              carbs: (carbsGrams * 0.18).round(),
              fats: 2,
            ),
            DietMealItem(
              name: '1 Cup Black Coffee or Herbal Tea',
              calories: 5,
              protein: 0,
              carbs: 1,
              fats: 0,
            ),
            DietMealItem(
              name: '5 Roasted Almonds',
              calories: 35,
              protein: 1.5,
              carbs: 1,
              fats: 3,
            ),
          ],
        ),
        'lunch': DietMeal(
          title: isNonVeg
              ? 'Grilled Chicken Breast & Brown Rice 🥣'
              : (isVegan ? 'Soya & Quinoa Bowl 🥣' : 'Paneer & Dal Power Bowl 🥣'),
          items: [
            DietMealItem(
              name: isNonVeg
                  ? '150g Grilled Chicken Breast'
                  : (isVegan ? '60g Soya Chunks Curry' : '150g Low-Fat Paneer Cubes'),
              calories: (baseCal * 0.20).round(),
              protein: (proteinGrams * 0.25).round(),
              carbs: 6,
              fats: 6,
            ),
            DietMealItem(
              name: '1 Cup Steamed Brown Rice or Quinoa',
              calories: (baseCal * 0.10).round(),
              protein: 4,
              carbs: (carbsGrams * 0.25).round(),
              fats: 2,
            ),
            DietMealItem(
              name: '1 Bowl Yellow Lentils (Dal)',
              calories: (baseCal * 0.04).round(),
              protein: (proteinGrams * 0.05).round(),
              carbs: 14,
              fats: 2,
            ),
            DietMealItem(
              name: 'Mixed Green Salad with Lemon Dressing',
              calories: 30,
              protein: 1,
              carbs: 5,
              fats: 1,
            ),
          ],
        ),
        'snack': DietMeal(
          title: isNonVeg || isEgg
              ? 'Boiled Egg Whites & Green Tea ☕'
              : 'Roasted Chana & Sprouts ☕',
          items: [
            DietMealItem(
              name: isNonVeg || isEgg ? '3 Hard Boiled Egg Whites' : '50g Roasted Black Chana',
              calories: (baseCal * 0.08).round(),
              protein: (proteinGrams * 0.10).round(),
              carbs: isNonVeg || isEgg ? 1 : 22,
              fats: isNonVeg || isEgg ? 0 : 2,
            ),
            DietMealItem(
              name: '1 Cup Green Tea with Lemon',
              calories: 5,
              protein: 0,
              carbs: 1,
              fats: 0,
            ),
            DietMealItem(
              name: '10 Mixed Roasted Nuts',
              calories: (baseCal * 0.06).round(),
              protein: 3,
              carbs: 3,
              fats: (fatsGrams * 0.12).round(),
            ),
          ],
        ),
        'dinner': DietMeal(
          title: isNonVeg
              ? 'Baked Fish / Chicken Salad & Phulka 🥗'
              : (isVegan ? 'Tofu Stir-fry & Multigrain Roti 🥗' : 'Moong Dal & Vegetable Roti 🥗'),
          items: [
            DietMealItem(
              name: isNonVeg
                  ? '150g Baked Fish or Chicken Breast'
                  : (isVegan ? '100g Sauteed Tofu with Broccoli' : '1 Bowl Moong Dal Sprouts Curry'),
              calories: (baseCal * 0.14).round(),
              protein: (proteinGrams * 0.18).round(),
              carbs: 6,
              fats: 4,
            ),
            DietMealItem(
              name: '1-2 Multigrain Rotis',
              calories: (baseCal * 0.08).round(),
              protein: 4,
              carbs: (carbsGrams * 0.20).round(),
              fats: 2,
            ),
            DietMealItem(
              name: '1 Bowl Clear Vegetable Soup',
              calories: 45,
              protein: 2,
              carbs: 8,
              fats: 0.5,
            ),
            DietMealItem(
              name: 'Cucumber & Carrot Salad',
              calories: 25,
              protein: 1,
              carbs: 5,
              fats: 0,
            ),
          ],
        ),
      },
    );
  }
}
