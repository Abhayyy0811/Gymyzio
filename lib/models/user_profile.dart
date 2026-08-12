import '../utils/unit_converter.dart';

class UserProfile {
  final String? uid;
  final String? email;
  final String? phoneNumber;
  final String? usernameDisplay;
  final String? usernameLowercase;
  final String language; // "English", "हिंदी"
  final String unitSystem; // "Metric", "Imperial"
  final String name;
  final int age;
  final double weight; // Stored in kg (base metric)
  final double height; // Stored in cm (base metric)
  final String goal; // "Strength", "Cardio", "Both"
  final String experienceLevel; // "Beginner", "Intermediate", "Advanced"
  final bool isProfileComplete;

  const UserProfile({
    this.uid,
    this.email,
    this.phoneNumber,
    this.usernameDisplay,
    this.usernameLowercase,
    this.language = 'English',
    this.unitSystem = 'Metric',
    this.name = 'Athlete',
    this.age = 0,
    this.weight = 0.0,
    this.height = 0.0,
    this.goal = '',
    this.experienceLevel = '',
    this.isProfileComplete = false,
  });

  /// Formatted Age e.g. "24 years"
  String get ageFormatted => '$age years';

  /// Formatted Weight e.g. "75 kg" or "165.3 lbs" based on unitSystem
  String get weightFormatted => UnitConverter.formatWeight(weight, unitSystem);

  /// Formatted Height e.g. "178 cm" or "5 ft 10 in" based on unitSystem
  String get heightFormatted => UnitConverter.formatHeight(height, unitSystem);

  /// Strict validation whether profile setup has been completely filled out manually by user.
  bool get isFullyCompleted {
    return isProfileComplete &&
        name.trim().isNotEmpty &&
        name.trim() != 'Athlete' &&
        phoneNumber != null &&
        phoneNumber!.trim().isNotEmpty &&
        age > 0 &&
        weight > 0 &&
        height > 0;
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? usernameDisplay,
    String? usernameLowercase,
    String? language,
    String? unitSystem,
    String? name,
    int? age,
    double? weight,
    double? height,
    String? goal,
    String? experienceLevel,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      usernameDisplay: usernameDisplay ?? this.usernameDisplay,
      usernameLowercase: usernameLowercase ?? this.usernameLowercase,
      language: language ?? this.language,
      unitSystem: unitSystem ?? this.unitSystem,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'username_display': usernameDisplay,
      'username_lowercase': usernameLowercase ?? usernameDisplay?.toLowerCase(),
      'language': language,
      'unitSystem': unitSystem,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
      'experienceLevel': experienceLevel,
      'isProfileComplete': isProfileComplete,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final rawDisplay = (map['username_display'] as String?) ?? (map['username'] as String?);
    final rawLower = (map['username_lowercase'] as String?) ?? rawDisplay?.toLowerCase();
    final unitSystem = (map['unitSystem'] as String?) ?? 'Metric';

    double rawWeight = (map['weight'] as num?)?.toDouble() ?? 75.0;
    double rawHeight = (map['height'] as num?)?.toDouble() ?? 178.0;

    // Normalization / migration logic for legacy Firestore profiles:
    // If height was saved in inches (< 100), convert to cm.
    if (rawHeight > 0 && rawHeight < 100) {
      rawHeight = UnitConverter.inchesToCm(rawHeight);
    }
    // If weight was stored as lbs (> 130 and unitSystem is Imperial), convert to kg.
    if (unitSystem == 'Imperial' && rawWeight > 130 && rawWeight < 500) {
      rawWeight = UnitConverter.lbsToKg(rawWeight);
    }

    return UserProfile(
      uid: map['uid'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      usernameDisplay: rawDisplay,
      usernameLowercase: rawLower,
      language: (map['language'] as String?) ?? 'English',
      unitSystem: unitSystem,
      name: (map['name'] as String?) ?? (map['displayName'] as String?) ?? 'Athlete',
      age: (map['age'] as num?)?.toInt() ?? 24,
      weight: rawWeight,
      height: rawHeight,
      goal: (map['goal'] as String?) ?? 'Strength',
      experienceLevel: (map['experienceLevel'] as String?) ?? 'Intermediate',
      isProfileComplete: (map['isProfileComplete'] as bool?) ?? false,
    );
  }
}
