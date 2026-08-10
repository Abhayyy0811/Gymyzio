import 'package:flutter/material.dart';

enum BadgeTier { low, moderate, high, legendary }

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int requiredStreak;
  final Color color;
  final BadgeTier tier;
  final String category; // 'streak', 'strength', 'cardio', 'consistency', 'exploration'

  const BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredStreak,
    required this.color,
    required this.tier,
    required this.category,
  });

  String get tierName {
    switch (tier) {
      case BadgeTier.low:
        return 'Low';
      case BadgeTier.moderate:
        return 'Moderate';
      case BadgeTier.high:
        return 'High';
      case BadgeTier.legendary:
        return 'Legendary';
    }
  }

  Color get tierColor {
    switch (tier) {
      case BadgeTier.low:
        return const Color(0xFF00E676); // Green
      case BadgeTier.moderate:
        return const Color(0xFFFF9100); // Orange
      case BadgeTier.high:
        return const Color(0xFFFF1744); // Red
      case BadgeTier.legendary:
        return const Color(0xFFFFD700); // Gold
    }
  }
}
