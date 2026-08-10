import 'package:intl/intl.dart';

class DietMealItem {
  final String id;
  final String name;
  final num calories;
  final num protein;
  final num carbs;
  final num fats;

  DietMealItem({
    String? id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  }) : id = id ?? name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();

  factory DietMealItem.fromJson(dynamic json, [String? mealKey]) {
    if (json is String) {
      final generatedId = '${mealKey ?? 'meal'}_${json.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}';
      return DietMealItem(
        id: generatedId,
        name: json,
        calories: 0,
        protein: 0,
        carbs: 0,
        fats: 0,
      );
    }
    if (json is Map<String, dynamic>) {
      final name = json['name'] as String? ?? 'Food item';
      final generatedId = json['id'] as String? ??
          '${mealKey ?? 'meal'}_${name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}';
      return DietMealItem(
        id: generatedId,
        name: name,
        calories: (json['calories'] as num?) ?? 0,
        protein: (json['protein'] as num?) ?? 0,
        carbs: (json['carbs'] as num?) ?? 0,
        fats: (json['fats'] as num?) ?? 0,
      );
    }
    return DietMealItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: json.toString(),
      calories: 0,
      protein: 0,
      carbs: 0,
      fats: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}

class DietMeal {
  final String title;
  final List<DietMealItem> items;

  DietMeal({
    required this.title,
    required this.items,
  });

  /// Dynamically computes total calories as the exact sum of sub-meal items
  int get calories {
    if (items.isEmpty) return 0;
    return items.fold<num>(0, (sum, item) => sum + item.calories).round();
  }

  /// Dynamically computes total protein as the exact sum of sub-meal items
  num get protein {
    if (items.isEmpty) return 0;
    return items.fold<num>(0, (sum, item) => sum + item.protein);
  }

  /// Dynamically computes total carbs as the exact sum of sub-meal items
  num get carbs {
    if (items.isEmpty) return 0;
    return items.fold<num>(0, (sum, item) => sum + item.carbs);
  }

  /// Dynamically computes total fats as the exact sum of sub-meal items
  num get fats {
    if (items.isEmpty) return 0;
    return items.fold<num>(0, (sum, item) => sum + item.fats);
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory DietMeal.fromJson(Map<String, dynamic> json, [String? mealKey]) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final parsedItems = rawItems.map((e) => DietMealItem.fromJson(e, mealKey)).toList();

    return DietMeal(
      title: json['title'] as String? ?? 'Healthy Meal',
      items: parsedItems,
    );
  }
}

class DietPlan {
  final String preference;
  final String weightCategory;
  final String goal;
  final String description;
  final Map<String, DietMeal> meals;

  DietPlan({
    required this.preference,
    required this.weightCategory,
    required this.goal,
    required this.description,
    required this.meals,
  });

  /// Dynamically computes target daily calories as exact sum of all meals
  int get targetCalories {
    if (meals.isEmpty) return 2000;
    return meals.values.fold<int>(0, (sum, meal) => sum + meal.calories);
  }

  /// Dynamically computes target protein as exact sum of all meals
  int get proteinGrams {
    if (meals.isEmpty) return 120;
    return meals.values.fold<num>(0, (sum, meal) => sum + meal.protein).round();
  }

  /// Dynamically computes target carbs as exact sum of all meals
  int get carbsGrams {
    if (meals.isEmpty) return 200;
    return meals.values.fold<num>(0, (sum, meal) => sum + meal.carbs).round();
  }

  /// Dynamically computes target fats as exact sum of all meals
  int get fatsGrams {
    if (meals.isEmpty) return 55;
    return meals.values.fold<num>(0, (sum, meal) => sum + meal.fats).round();
  }

  Map<String, dynamic> toJson() {
    final mealsJson = <String, dynamic>{};
    meals.forEach((key, value) {
      mealsJson[key] = value.toJson();
    });
    return {
      'preference': preference,
      'weight_category': weightCategory,
      'goal': goal,
      'description': description,
      'meals': mealsJson,
    };
  }

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    final rawMeals = json['meals'] as Map<String, dynamic>? ?? {};
    final parsedMeals = <String, DietMeal>{};
    rawMeals.forEach((key, value) {
      parsedMeals[key] = DietMeal.fromJson(value as Map<String, dynamic>, key);
    });

    return DietPlan(
      preference: json['preference'] as String? ?? 'Veg',
      weightCategory: json['weight_category'] as String? ?? 'W2',
      goal: json['goal'] as String? ?? 'Maintenance',
      description: json['description'] as String? ?? 'Balanced daily nutrition chart.',
      meals: parsedMeals,
    );
  }
}

class EatenMealLog {
  final String itemId;
  final String mealCategory;
  final String name;
  final num calories;
  final num protein;
  final num carbs;
  final num fats;
  final DateTime eatenAt;

  EatenMealLog({
    required this.itemId,
    required this.mealCategory,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.eatenAt,
  });

  String get formattedTime => DateFormat('h:mm a').format(eatenAt);

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'mealCategory': mealCategory,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'eatenAt': eatenAt.toIso8601String(),
    };
  }

  factory EatenMealLog.fromJson(Map<String, dynamic> json) {
    return EatenMealLog(
      itemId: json['itemId'] as String? ?? '',
      mealCategory: json['mealCategory'] as String? ?? 'Meal',
      name: json['name'] as String? ?? 'Food item',
      calories: (json['calories'] as num?) ?? 0,
      protein: (json['protein'] as num?) ?? 0,
      carbs: (json['carbs'] as num?) ?? 0,
      fats: (json['fats'] as num?) ?? 0,
      eatenAt: json['eatenAt'] != null
          ? DateTime.parse(json['eatenAt'] as String)
          : DateTime.now(),
    );
  }
}

class DietChampUserPrefs {
  final String preference; // Veg, Non-Veg, Eggetarian, Vegan
  final double weightKg;
  final String goal; // Fat Loss, Muscle Gain, Maintenance

  DietChampUserPrefs({
    required this.preference,
    required this.weightKg,
    required this.goal,
  });

  String get weightCategory {
    if (weightKg < 55.0) return 'W1';
    if (weightKg <= 70.0) return 'W2';
    if (weightKg <= 85.0) return 'W3';
    return 'W4';
  }

  String get weightCategoryLabel {
    switch (weightCategory) {
      case 'W1':
        return 'W1 (< 55 kg)';
      case 'W2':
        return 'W2 (55 - 70 kg)';
      case 'W3':
        return 'W3 (70 - 85 kg)';
      case 'W4':
        return 'W4 (> 85 kg)';
      default:
        return 'W2 (55 - 70 kg)';
    }
  }

  DietChampUserPrefs copyWith({
    String? preference,
    double? weightKg,
    String? goal,
  }) {
    return DietChampUserPrefs(
      preference: preference ?? this.preference,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
    );
  }
}
