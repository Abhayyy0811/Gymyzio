import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../utils/phone_utils.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch or initialize user profile in Firestore
  /// Returns a tuple of (UserProfile, bool isNewUser)
  Future<({UserProfile profile, bool isNewUser})> fetchOrInitUserProfile(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // First-time user doc creation (minimal fields)
        final initialProfile = UserProfile(
          uid: user.uid,
          email: user.email,
          phoneNumber: user.phoneNumber != null ? normalizePhoneNumber(user.phoneNumber!) : null,
          name: user.displayName ?? 'Athlete',
          isProfileComplete: false,
        );

        await docRef.set({
          ...initialProfile.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        return (profile: initialProfile, isNewUser: true);
      } else {
        // Returning user: deserialize profile
        final data = docSnap.data()!;
        final rawPhone = user.phoneNumber ?? data['phoneNumber'] as String?;
        final loadedProfile = UserProfile.fromMap(data).copyWith(
          uid: user.uid,
          email: user.email ?? data['email'] as String?,
          phoneNumber: rawPhone != null && rawPhone.isNotEmpty ? normalizePhoneNumber(rawPhone) : null,
        );

        return (
          profile: loadedProfile,
          isNewUser: !loadedProfile.isProfileComplete,
        );
      }
    } catch (e) {
      // Fallback if offline / Firestore rules unconfigured
      final fallbackProfile = UserProfile(
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber != null ? normalizePhoneNumber(user.phoneNumber!) : null,
        name: user.displayName ?? 'Athlete',
        isProfileComplete: false,
      );
      return (profile: fallbackProfile, isNewUser: true);
    }
  }

  /// Save or update full profile details in Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    if (profile.uid == null || profile.uid!.isEmpty) return;
    try {
      final docRef = _firestore.collection('users').doc(profile.uid);
      final profileToSave = profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty
          ? profile.copyWith(phoneNumber: normalizePhoneNumber(profile.phoneNumber!))
          : profile;
      final mapData = profileToSave.toMap();
      await docRef.set(mapData, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('❌ [saveUserProfile] Error saving user profile: $e');
      }
    }
  }

  /// Save a custom user-uploaded photo URL (base64 data URL) in Firestore
  Future<void> saveCustomPhotoUrl(String uid, String dataUrl) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).set(
        {'customPhotoUrl': dataUrl},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [saveCustomPhotoUrl] Error: $e');
      }
    }
  }

  /// Clear the custom user photo URL from Firestore
  Future<void> clearCustomPhotoUrl(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'customPhotoUrl': FieldValue.delete(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ [clearCustomPhotoUrl] Error: $e');
      }
    }
  }

  /// Check if a username is already taken in Firestore (case-insensitive check against username_lowercase)
  Future<bool> isUsernameTaken(String username, {String? excludeUid}) async {
    final cleanLower = username.trim().toLowerCase();
    if (cleanLower.isEmpty) return false;

    try {
      final querySnap = await _firestore
          .collection('users')
          .where('username_lowercase', isEqualTo: cleanLower)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final doc = querySnap.docs.first;
        if (excludeUid != null && doc.id == excludeUid) {
          return false;
        }
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Find registered user email by username in Firestore
  Future<String?> findEmailByUsername(String username) async {
    var cleanLower = username.trim().toLowerCase();
    if (cleanLower.startsWith('@')) {
      cleanLower = cleanLower.substring(1).trim();
    }
    if (cleanLower.isEmpty) return null;

    try {
      final querySnap = await _firestore
          .collection('users')
          .where('username_lowercase', isEqualTo: cleanLower)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        final data = querySnap.docs.first.data();
        final email = data['email'] as String?;
        if (email != null && email.isNotEmpty) return email;
      }
    } catch (_) {}

    return null;
  }

  /// Check if a phone number is already linked to another account in Firestore
  Future<bool> isPhoneNumberTaken(String rawPhone, {String? excludeUid}) async {
    final cleanPhone = normalizePhoneNumber(rawPhone);
    final rawTrimmed = rawPhone.trim();
    if (cleanPhone.isEmpty && rawTrimmed.isEmpty) return false;

    try {
      if (cleanPhone.isNotEmpty) {
        final querySnap = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final doc = querySnap.docs.first;
          if (excludeUid != null && doc.id == excludeUid) {
            return false;
          }
          return true;
        }
      }

      if (rawTrimmed.isNotEmpty && rawTrimmed != cleanPhone) {
        final querySnap = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: rawTrimmed)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final doc = querySnap.docs.first;
          if (excludeUid != null && doc.id == excludeUid) {
            return false;
          }
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Find registered user email by phone number in Firestore
  Future<String?> findEmailByPhoneNumber(String rawPhone) async {
    final cleanPhone = normalizePhoneNumber(rawPhone);
    final rawTrimmed = rawPhone.trim();
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty && rawTrimmed.isEmpty && digitsOnly.isEmpty) return null;

    try {
      // 1. Primary lookup: normalized phone format (e.g. +919876543210)
      if (cleanPhone.isNotEmpty) {
        final querySnap = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final data = querySnap.docs.first.data();
          final email = data['email'] as String?;
          if (email != null && email.isNotEmpty) return email;
        }
      }

      // 2. Lookup by raw input trimmed (e.g. "9876543210" or "+91 9876543210")
      if (rawTrimmed.isNotEmpty && rawTrimmed != cleanPhone) {
        final querySnap = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: rawTrimmed)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final data = querySnap.docs.first.data();
          final email = data['email'] as String?;
          if (email != null && email.isNotEmpty) return email;
        }
      }

      // 3. Fallback for 10-digit input without country calling code: try common country prefixes (+91, +1, etc.)
      if (digitsOnly.length == 10) {
        for (final cc in ['+91', '+1', '+44', '+61', '+971', '+49']) {
          final candidate = '$cc$digitsOnly';
          if (candidate != cleanPhone) {
            final querySnap = await _firestore
                .collection('users')
                .where('phoneNumber', isEqualTo: candidate)
                .limit(1)
                .get();

            if (querySnap.docs.isNotEmpty) {
              final data = querySnap.docs.first.data();
              final email = data['email'] as String?;
              if (email != null && email.isNotEmpty) return email;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [findEmailByPhoneNumber] Error: $e');
      }
    }

    return null;
  }

  /// Delete user profile document and subcollections in Firestore
  Future<void> deleteUserProfile(String uid) async {
    if (uid.isEmpty) return;
    final userDoc = _firestore.collection('users').doc(uid);

    // 1. Safe deletion of subcollections
    final subcollections = ['workouts', 'personalRecords', 'activity', 'badges', 'history', 'settings', 'body_weight_logs'];
    for (final sub in subcollections) {
      try {
        final snapshots = await userDoc.collection(sub).get();
        for (final doc in snapshots.docs) {
          await doc.reference.delete();
        }
      } catch (subErr) {
        if (kDebugMode) {
          print('⚠️ [deleteUserProfile] Subcollection $sub error (ignored): $subErr');
        }
      }
    }

    // 2. Safe deletion of main user document
    try {
      await userDoc.delete();
      if (kDebugMode) {
        print('✅ [deleteUserProfile] Firestore document users/$uid deleted successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [deleteUserProfile] Main doc deletion error: $e');
      }
    }
  }

  /// Administrative: Wipe all user documents and subcollections in Firestore
  Future<void> wipeAllUserDatabase() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      for (final userDoc in usersSnap.docs) {
        await deleteUserProfile(userDoc.id);
      }
      if (kDebugMode) {
        print('✅ [wipeAllUserDatabase] All Firestore user documents wiped successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [wipeAllUserDatabase] Error wiping users collection: $e');
      }
    }
  }

  /// Real-Time Workout History Persistence
  Future<void> saveCompletedWorkout(String uid, CompletedWorkout workout) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .doc(workout.id)
          .set(workout.toMap());
    } catch (e) {
      if (kDebugMode) print('⚠️ [saveCompletedWorkout] Error: $e');
    }
  }

  Stream<List<CompletedWorkout>> streamCompletedWorkouts(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CompletedWorkout.fromMap(doc.data())).toList());
  }

  /// Real-Time Body Weight Log Persistence
  Future<void> logBodyWeight(String uid, double weightKg) async {
    try {
      await _firestore.collection('users').doc(uid).collection('body_weight_logs').add({
        'date': DateTime.now().toIso8601String(),
        'weightKg': weightKg,
      });
    } catch (e) {
      if (kDebugMode) print('⚠️ [logBodyWeight] Error: $e');
    }
  }

  Stream<List<BodyWeightLog>> streamBodyWeightLogs(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('body_weight_logs')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => BodyWeightLog.fromMap(doc.data())).toList());
  }
}
