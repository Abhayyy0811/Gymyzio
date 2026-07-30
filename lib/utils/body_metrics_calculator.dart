import 'dart:math' as math;
import 'unit_converter.dart';

class BodyMetricsResult {
  final double bmi;
  final String bmiCategory;
  final double bodyFatPercentage;
  final String bodyFatCategory;

  const BodyMetricsResult({
    required this.bmi,
    required this.bmiCategory,
    required this.bodyFatPercentage,
    required this.bodyFatCategory,
  });
}

class BodyMetricsCalculator {
  /// Calculate BMI from height (cm) and weight (kg)
  static double calculateBMI({
    required double height,
    required double weight,
    String unitSystem = 'Metric',
  }) {
    if (height <= 0 || weight <= 0) return 0.0;

    double heightCm = height;
    double weightKg = weight;

    // Backward compatibility for legacy inputs:
    if (unitSystem == 'Imperial') {
      if (height < 100) {
        heightCm = UnitConverter.inchesToCm(height);
      }
      if (weight > 130 && weight < 500) {
        weightKg = UnitConverter.lbsToKg(weight);
      }
    }

    final heightMeter = heightCm / 100.0;
    if (heightMeter <= 0) return 0.0;
    final bmi = weightKg / (heightMeter * heightMeter);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Get BMI Category
  static String getBmiCategory(double bmi) {
    if (bmi <= 0) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal Weight (Healthy)';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Calculate Body Fat % using Deurenberg Formula based on BMI, Age, Gender
  static double calculateBodyFat({
    required double bmi,
    required int age,
    bool isMale = true,
  }) {
    if (bmi <= 0 || age <= 0) return 0.0;
    final genderFactor = isMale ? 1.0 : 0.0;
    final bodyFat = (1.20 * bmi) + (0.23 * age) - (10.8 * genderFactor) - 5.4;
    return double.parse(bodyFat.clamp(3.0, 60.0).toStringAsFixed(1));
  }

  /// Calculate Body Fat % using US Navy Method (Waist, Neck, Height in cm, Hip for Females)
  static double calculateNavyBodyFat({
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double hipCm = 0.0,
    bool isMale = true,
  }) {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return 0.0;
    double bf = 0.0;
    if (isMale) {
      final diff = waistCm - neckCm;
      if (diff <= 0) return 0.0;
      bf = 86.010 * (math.log(diff) / math.ln10) - 70.041 * (math.log(heightCm) / math.ln10) + 36.76;
    } else {
      final sum = waistCm + hipCm - neckCm;
      if (sum <= 0) return 0.0;
      bf = 163.205 * (math.log(sum) / math.ln10) - 97.684 * (math.log(heightCm) / math.ln10) - 78.387;
    }
    return double.parse(bf.clamp(3.0, 60.0).toStringAsFixed(1));
  }

  /// Get Body Fat Category (ACE Standards)
  static String getBodyFatCategory(double bodyFat, {bool isMale = true}) {
    if (bodyFat <= 0) return 'Unknown';
    if (isMale) {
      if (bodyFat < 6.0) return 'Essential Fat (Low)';
      if (bodyFat < 14.0) return 'Athletes Level';
      if (bodyFat < 18.0) return 'Fitness Level';
      if (bodyFat < 25.0) return 'Average / Acceptable';
      return 'Obese / High Fat';
    } else {
      if (bodyFat < 14.0) return 'Essential Fat (Low)';
      if (bodyFat < 21.0) return 'Athletes Level';
      if (bodyFat < 25.0) return 'Fitness Level';
      if (bodyFat < 32.0) return 'Average / Acceptable';
      return 'Obese / High Fat';
    }
  }
}
