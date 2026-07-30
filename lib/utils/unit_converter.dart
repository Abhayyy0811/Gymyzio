class UnitConverter {
  static const double kgToLbsMultiplier = 2.20462;
  static const double cmToInchesDivider = 2.54;

  /// Convert kg to lbs
  static double kgToLbs(double kg) => kg * kgToLbsMultiplier;

  /// Convert lbs to kg
  static double lbsToKg(double lbs) => lbs / kgToLbsMultiplier;

  /// Convert cm to total inches
  static double cmToInches(double cm) => cm / cmToInchesDivider;

  /// Convert inches to cm
  static double inchesToCm(double inches) => inches * cmToInchesDivider;

  /// Convert feet & inches to cm
  static double feetInchesToCm(int feet, double inches) {
    final totalInches = (feet * 12.0) + inches;
    return inchesToCm(totalInches);
  }

  /// Convert cm to feet and inches
  static ({int feet, double inches}) cmToFeetInches(double cm) {
    if (cm <= 0) return (feet: 0, inches: 0.0);
    final totalInches = cmToInches(cm);
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return (feet: feet, inches: double.parse(inches.toStringAsFixed(1)));
  }

  /// Converts weight value (stored in kg) to the target unit system ('Metric' or 'Imperial')
  static double convertWeight(double weightKg, String unitSystem) {
    if (unitSystem == 'Imperial') {
      return kgToLbs(weightKg);
    }
    return weightKg;
  }

  /// Converts height value (stored in cm) to total inches if Imperial, or cm if Metric
  static double convertHeight(double heightCm, String unitSystem) {
    if (unitSystem == 'Imperial') {
      return cmToInches(heightCm);
    }
    return heightCm;
  }

  /// Formats weight with unit label (e.g., "75 kg", "75.5 kg" or "165.3 lbs")
  static String formatWeight(
    double weightKg,
    String unitSystem, {
    int decimals = 1,
    bool includeUnit = true,
  }) {
    if (weightKg <= 0) return includeUnit ? (unitSystem == 'Imperial' ? '0 lbs' : '0 kg') : '0';
    final val = convertWeight(weightKg, unitSystem);
    String formattedVal;
    if (val % 1 == 0) {
      formattedVal = val.toInt().toString();
    } else {
      formattedVal = val.toStringAsFixed(decimals);
      if (formattedVal.endsWith('.0')) {
        formattedVal = formattedVal.substring(0, formattedVal.length - 2);
      }
    }
    if (!includeUnit) return formattedVal;
    final unitLabel = weightUnit(unitSystem);
    return '$formattedVal $unitLabel';
  }

  /// Formats height with unit label (e.g., "178 cm" or "5 ft 10 in")
  static String formatHeight(
    double heightCm,
    String unitSystem, {
    bool includeUnit = true,
  }) {
    if (heightCm <= 0) return includeUnit ? (unitSystem == 'Imperial' ? '0 ft 0 in' : '0 cm') : '0';
    if (unitSystem == 'Imperial') {
      final ftIn = cmToFeetInches(heightCm);
      final inchesStr = ftIn.inches % 1 == 0 ? ftIn.inches.toInt().toString() : ftIn.inches.toStringAsFixed(1);
      if (!includeUnit) return '${ftIn.feet}\' $inchesStr"';
      return '${ftIn.feet} ft $inchesStr in';
    }
    final valStr = heightCm % 1 == 0 ? heightCm.toInt().toString() : heightCm.toStringAsFixed(1);
    if (!includeUnit) return valStr;
    return '$valStr cm';
  }

  /// Returns unit label for weight ('kg' vs 'lbs')
  static String weightUnit(String unitSystem) => unitSystem == 'Imperial' ? 'lbs' : 'kg';

  /// Returns unit label for height ('cm' vs 'in')
  static String heightUnit(String unitSystem) => unitSystem == 'Imperial' ? 'in' : 'cm';
}
