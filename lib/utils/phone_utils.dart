library;

/// Phone number utility functions for normalizing and validating phone numbers.

String normalizePhoneNumber(String rawPhone) {
  final trimmed = rawPhone.trim();
  if (trimmed.isEmpty) return '';

  // 1. Remove all spaces, dashes, parentheses, dots
  String cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
  if (cleaned.isEmpty) return '';

  // 2. If it starts with '+', preserve '+' and remove non-digit characters
  if (cleaned.startsWith('+')) {
    final digits = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
    return '+$digits';
  }

  // 3. Extract digits only
  String digits = cleaned.replaceAll(RegExp(r'\D'), '');

  // Strip leading zeros (e.g., 09876543210 -> 9876543210)
  while (digits.startsWith('0')) {
    digits = digits.substring(1);
  }

  if (digits.isEmpty) return '';

  // 4. Default to +91 prefix for 10-digit Indian numbers (or if length is 10)
  if (digits.length == 10) {
    return '+91$digits';
  } else if (digits.length == 12 && digits.startsWith('91')) {
    return '+$digits';
  } else {
    return '+$digits';
  }
}
