import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ExerciseCategory { strength, cardio }

class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final String muscleGroup;
  final String equipment;
  final String difficulty;
  final List<String> instructions;
  final List<String> commonMistakes;
  final Color themeColor;
  final IconData icon;
  final String? gifUrl;
  final String? assetPath;
  final String? target;
  final List<String> secondaryMuscles;
  final String? bodyPart;
  final String? videoPath;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    required this.instructions,
    required this.commonMistakes,
    required this.themeColor,
    required this.icon,
    this.gifUrl,
    this.assetPath,
    this.target,
    this.secondaryMuscles = const [],
    this.bodyPart,
    this.videoPath,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    final rawBodyPart = (map['bodyPart'] as String?)?.trim() ?? 'General';
    final rawTarget = (map['target'] as String?)?.trim() ?? '';
    final rawEquipment = (map['equipment'] as String?)?.trim() ?? 'Body Weight';
    final rawCategory = (map['category'] as String?)?.toLowerCase() ?? '';

    final isCardio = rawCategory == 'cardio' ||
        rawBodyPart.toLowerCase() == 'cardio' ||
        rawTarget.toLowerCase() == 'cardio' ||
        rawEquipment.toLowerCase().contains('bike') ||
        rawEquipment.toLowerCase().contains('treadmill') ||
        rawEquipment.toLowerCase().contains('elliptical') ||
        rawEquipment.toLowerCase().contains('rope') ||
        rawEquipment.toLowerCase().contains('stepper') ||
        rawEquipment.toLowerCase().contains('rower') ||
        rawEquipment.toLowerCase().contains('ergometer');

    final category = isCardio ? ExerciseCategory.cardio : ExerciseCategory.strength;

    String muscleGroupStr;
    final bpLower = rawBodyPart.toLowerCase();
    if (isCardio) {
      muscleGroupStr = 'Cardio';
    } else if (bpLower == 'waist' || rawTarget.toLowerCase().contains('abs') || bpLower == 'abs') {
      muscleGroupStr = 'Core';
    } else if (bpLower.contains('arms') || bpLower == 'biceps' || bpLower == 'triceps' || bpLower.contains('upper arms') || bpLower.contains('lower arms')) {
      muscleGroupStr = 'Arms';
    } else if (bpLower.contains('legs') || bpLower == 'calves' || bpLower.contains('upper legs') || bpLower.contains('lower legs')) {
      muscleGroupStr = 'Legs';
    } else if (bpLower == 'chest') {
      muscleGroupStr = 'Chest';
    } else if (bpLower == 'back') {
      muscleGroupStr = 'Back';
    } else if (bpLower == 'shoulders') {
      muscleGroupStr = 'Shoulders';
    } else if (bpLower == 'neck') {
      muscleGroupStr = 'Neck';
    } else {
      muscleGroupStr = _formatTitle(rawBodyPart.isNotEmpty ? rawBodyPart : (rawTarget.isNotEmpty ? rawTarget : 'General'));
    }

    final rawInstructions = map['instructions'] as List<dynamic>?;
    final instructionsList = rawInstructions != null
        ? rawInstructions.map((e) => e.toString()).toList()
        : <String>[];

    final rawSecondary = map['secondaryMuscles'] as List<dynamic>?;
    final secondaryList = rawSecondary != null
        ? rawSecondary.map((e) => e.toString()).toList()
        : <String>[];

    final rawDiff = (map['difficulty'] as String?)?.trim();
    String diffStr = isCardio ? 'Beginner' : 'Intermediate';
    if (rawDiff != null && rawDiff.isNotEmpty) {
      diffStr = _formatTitle(rawDiff);
    }

    final assetP = (map['assetPath'] as String?)?.trim();

    return Exercise(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _formatTitle(map['name'] as String? ?? 'Exercise'),
      category: category,
      muscleGroup: muscleGroupStr,
      equipment: _formatTitle(rawEquipment),
      difficulty: diffStr,
      instructions: instructionsList.isNotEmpty
          ? instructionsList
          : ['Maintain good posture throughout the movement.', 'Control the movement and breathe regularly.'],
      commonMistakes: const [
        'Rushing the reps without proper form',
        'Inadequate range of motion',
        'Holding your breath during exertion',
      ],
      themeColor: isCardio ? AppColors.accent : AppColors.primary,
      icon: isCardio ? Icons.directions_run_rounded : Icons.fitness_center_rounded,
      gifUrl: (map['gifUrl'] ?? map['gif']) as String?,
      assetPath: assetP,
      target: rawTarget.isNotEmpty ? rawTarget : null,
      secondaryMuscles: secondaryList,
      bodyPart: rawBodyPart,
    );
  }

  factory Exercise.fromWorkoutXMap(Map<String, dynamic> map) => Exercise.fromMap(map);
  factory Exercise.fromExerciseDbMap(Map<String, dynamic> map) => Exercise.fromMap(map);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'instructions': instructions,
      'commonMistakes': commonMistakes,
      'gifUrl': gifUrl,
      'assetPath': assetPath,
      'target': target,
      'secondaryMuscles': secondaryMuscles,
      'bodyPart': bodyPart,
    };
  }

  String toJson() => json.encode(toMap());
  factory Exercise.fromJson(String source) => Exercise.fromMap(json.decode(source) as Map<String, dynamic>);

  static String _formatTitle(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
