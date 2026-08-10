library;

import 'dart:math';

/// Reserved words blocklist that cannot be registered as usernames
const Set<String> reservedUsernameBlocklist = {
  'admin',
  'administrator',
  'support',
  'root',
  'system',
  'moderator',
  'mod',
  'official',
  'gymyzio',
  'help',
  'superuser',
  'null',
  'undefined',
  'guest',
  'owner',
  'test',
  'staff',
  'security',
  'billing',
  'api',
  'privacy',
  'terms',
  'about',
  'contact',
};

/// Validate username syntax rules.
/// Returns null if valid, or a descriptive error message if invalid.
String? validateUsernameSyntax(String rawUsername) {
  final username = rawUsername.trim();

  if (username.isEmpty) {
    return 'Please enter a username';
  }
  if (username.length < 3) {
    return 'Username must be at least 3 characters long';
  }
  if (username.length > 20) {
    return 'Username cannot exceed 20 characters';
  }
  if (!RegExp(r'^[a-zA-Z]').hasMatch(username)) {
    return 'Username must start with a letter';
  }
  if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(username)) {
    return 'Only letters, numbers, underscores (_), and dots (.) are allowed';
  }
  if (RegExp(r'(__|\.\.|\._|_\.)').hasMatch(username)) {
    return 'Consecutive dots or underscores are not allowed';
  }
  if (RegExp(r'[_.]+$').hasMatch(username)) {
    return 'Username cannot end with a dot or underscore';
  }
  if (reservedUsernameBlocklist.contains(username.toLowerCase())) {
    return 'This username is reserved and cannot be used';
  }

  return null;
}

/// Auto-generate 3-4 distinct username suggestions based on user's Full Name.
List<String> generateUsernameSuggestions(String fullName) {
  final cleanStr = fullName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  if (cleanStr.isEmpty) {
    final rand = Random().nextInt(899) + 100;
    return ['athlete_$rand', 'athlete.$rand', 'gym_athlete$rand', 'athlete_user$rand'];
  }

  final parts = cleanStr.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final suggestions = <String>{};
  final rng = Random();

  if (parts.length >= 2) {
    final first = parts.first.toLowerCase();
    final last = parts.last.toLowerCase();
    final initial = first[0];

    // Suggestion 1: plain combined (e.g., "abhaysharma")
    final s1 = '$first$last';
    if (validateUsernameSyntax(s1) == null) suggestions.add(s1);

    // Suggestion 2: underscore separated (e.g., "abhay_sharma")
    final s2 = '${first}_$last';
    if (validateUsernameSyntax(s2) == null) suggestions.add(s2);

    // Suggestion 3: dot separated + random two-digit num (e.g., "abhay.sharma08")
    final num2 = (rng.nextInt(89) + 10).toString().padLeft(2, '0');
    final s3 = '$first.$last$num2';
    if (validateUsernameSyntax(s3) == null) suggestions.add(s3);

    // Suggestion 4: initial + last + random 3-digit num (e.g., "asharma123")
    final num3 = rng.nextInt(899) + 100;
    final s4 = '$initial$last$num3';
    if (validateUsernameSyntax(s4) == null) suggestions.add(s4);

    // Backup if needed
    final s5 = '${first}_fit${rng.nextInt(89) + 10}';
    if (validateUsernameSyntax(s5) == null) suggestions.add(s5);
  } else {
    final name = parts.first.toLowerCase();
    final rng = Random();
    final n1 = (rng.nextInt(89) + 10).toString();
    final n2 = (rng.nextInt(899) + 100).toString();

    final s1 = name;
    if (validateUsernameSyntax(s1) == null && s1.length >= 3) suggestions.add(s1);

    final s2Alt = '${name}_fit';
    if (validateUsernameSyntax(s2Alt) == null) suggestions.add(s2Alt);

    final s3 = '$name.$n1';
    if (validateUsernameSyntax(s3) == null) suggestions.add(s3);

    final s4 = '$name$n2';
    if (validateUsernameSyntax(s4) == null) suggestions.add(s4);
  }

  return suggestions.take(4).toList();
}
