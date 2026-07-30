import 'package:flutter_test/flutter_test.dart';
import 'package:gymyzio/utils/body_metrics_calculator.dart';

void main() {
  group('BodyMetricsCalculator Tests', () {
    test('BMI Calculation from standard metric values', () {
      final bmi = BodyMetricsCalculator.calculateBMI(height: 178.0, weight: 75.0, unitSystem: 'Metric');
      expect(bmi, equals(23.7));
      expect(BodyMetricsCalculator.getBmiCategory(bmi), equals('Normal Weight (Healthy)'));
    });

    test('Body Fat Calculation (Deurenberg Formula)', () {
      final bodyFat = BodyMetricsCalculator.calculateBodyFat(bmi: 23.7, age: 24, isMale: true);
      expect(bodyFat, equals(17.8));
      expect(BodyMetricsCalculator.getBodyFatCategory(bodyFat, isMale: true), equals('Fitness Level'));
    });

    test('US Navy Body Fat Calculation', () {
      final bf = BodyMetricsCalculator.calculateNavyBodyFat(
        heightCm: 178.0,
        waistCm: 85.0,
        neckCm: 38.0,
        isMale: true,
      );
      expect(bf, greaterThan(10.0));
      expect(bf, lessThan(25.0));
    });
  });
}
