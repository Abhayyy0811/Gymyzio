import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAccount {
  final String uid;
  final String? displayName;
  final String identifier; // Email address or phone number
  final String? photoUrl;
  final String signInMethod; // "google" | "phone" | "email"
  final DateTime lastUsedAt;

  const SavedAccount({
    required this.uid,
    this.displayName,
    required this.identifier,
    this.photoUrl,
    required this.signInMethod,
    required this.lastUsedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'identifier': identifier,
      'photoUrl': photoUrl,
      'signInMethod': signInMethod,
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  factory SavedAccount.fromMap(Map<String, dynamic> map) {
    return SavedAccount(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String?,
      identifier: map['identifier'] as String? ?? 'User',
      photoUrl: map['photoUrl'] as String?,
      signInMethod: map['signInMethod'] as String? ?? 'email',
      lastUsedAt: map['lastUsedAt'] != null
          ? DateTime.parse(map['lastUsedAt'] as String)
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedAccount.fromJson(String source) =>
      SavedAccount.fromMap(json.decode(source) as Map<String, dynamic>);

  SavedAccount copyWith({
    String? uid,
    String? displayName,
    String? identifier,
    String? photoUrl,
    String? signInMethod,
    DateTime? lastUsedAt,
  }) {
    return SavedAccount(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      identifier: identifier ?? this.identifier,
      photoUrl: photoUrl ?? this.photoUrl,
      signInMethod: signInMethod ?? this.signInMethod,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

class AccountRegistryService {
  static const String _storageKey = 'saved_accounts_v1';

  /// Save a new account or update lastUsedAt if uid already exists
  Future<void> saveOrUpdateAccount(SavedAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getSavedAccounts();

      final existingIndex = accounts.indexWhere((a) => a.uid == account.uid);
      if (existingIndex >= 0) {
        // Update existing record
        accounts[existingIndex] = account.copyWith(lastUsedAt: DateTime.now());
      } else {
        // Add new record
        accounts.add(account);
      }

      // Sort descending by lastUsedAt
      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));

      final jsonList = accounts.map((a) => a.toMap()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      // Ignore or log storage errors safely
    }
  }

  /// Get all stored accounts sorted by lastUsedAt descending
  Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson == null || rawJson.isEmpty) return [];

      final List<dynamic> decodedList = json.decode(rawJson) as List<dynamic>;
      final accounts = decodedList
          .map((item) => SavedAccount.fromMap(item as Map<String, dynamic>))
          .toList();

      accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
      return accounts;
    } catch (e) {
      return [];
    }
  }

  /// Remove account from stored device list by uid
  Future<void> removeAccount(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getSavedAccounts();

      accounts.removeWhere((a) => a.uid == uid);

      final jsonList = accounts.map((a) => a.toMap()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      // Ignore or log storage errors safely
    }
  }

  /// Clear all saved device accounts and wipe shared preferences
  Future<void> clearAllAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.clear();
    } catch (_) {}
  }
}

final accountRegistryServiceProvider = Provider<AccountRegistryService>((ref) {
  return AccountRegistryService();
});
