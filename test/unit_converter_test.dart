import 'package:flutter_test/flutter_test.dart';
import 'package:gymyzio/utils/unit_converter.dart';

void main() {
  group('UnitConverter Tests', () {
    test('Weight conversion kg to lbs and formatting', () {
      expect(UnitConverter.kgToLbs(75.0), closeTo(165.3465, 0.01));
      expect(UnitConverter.lbsToKg(165.3465), closeTo(75.0, 0.01));
      expect(UnitConverter.formatWeight(75.0, 'Metric'), equals('75 kg'));
      expect(UnitConverter.formatWeight(75.0, 'Imperial'), equals('165.3 lbs'));
    });

    test('Height conversion cm to feet/inches and formatting', () {
      expect(UnitConverter.cmToInches(178.0), closeTo(70.0787, 0.01));
      expect(UnitConverter.inchesToCm(70.0787), closeTo(178.0, 0.01));

      final ftIn = UnitConverter.cmToFeetInches(178.0);
      expect(ftIn.feet, equals(5));
      expect(ftIn.inches, closeTo(10.1, 0.1));

      expect(UnitConverter.formatHeight(178.0, 'Metric'), equals('178 cm'));
      expect(UnitConverter.formatHeight(178.0, 'Imperial'), equals('5 ft 10.1 in'));
    });
  });
}
