import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/app_notification.dart';

class NotificationStateNotifier extends StateNotifier<List<AppNotification>> {
  NotificationStateNotifier() : super([]) {
    _initNotifications();
  }

  /// Initialize notifications from local storage and sync initial welcome/badge notifications
  Future<void> _initNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasInitializedBefore = prefs.getBool('notifications_initialized') ?? false;
      final String? rawJson = prefs.getString('user_notifications');

      if (rawJson != null) {
        final List<dynamic> list = jsonDecode(rawJson) as List<dynamic>;
        state = list.map((e) => AppNotification.fromMap(e as Map<String, dynamic>)).toList();
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final docSnap = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (docSnap.exists && docSnap.data() != null) {
          final data = docSnap.data()!;
          if (data['notifications'] != null && rawJson == null) {
            // Only load from Firestore if local storage is completely uninitialized
            final List<dynamic> remoteList = data['notifications'] as List<dynamic>;
            state = remoteList.map((e) => AppNotification.fromMap(e as Map<String, dynamic>)).toList();
            await _saveToStorage();
          }
        }
      }

      // Add default welcome notification ONLY once on brand new app install
      if (!hasInitializedBefore && state.isEmpty) {
        await prefs.setBool('notifications_initialized', true);
        addNotification(
          title: 'Welcome to Gymyzio! 💪',
          message: 'Explore exercises, log workouts, and unlock achievement badges as you level up your fitness journey!',
          type: 'welcome',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [_initNotifications] Error loading notifications: $e');
      }
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_initialized', true);
      final rawJson = jsonEncode(state.map((n) => n.toMap()).toList());
      await prefs.setString('user_notifications', rawJson);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(
          {
            'notifications': state.map((n) => n.toMap()).toList(),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [_saveToStorage] Error saving notifications: $e');
      }
    }
  }

  /// Add a new notification
  void addNotification({
    required String title,
    required String message,
    String? badgeId,
    String type = 'badge',
  }) {
    final notif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      badgeId: badgeId,
      type: type,
    );

    state = [notif, ...state];
    _saveToStorage();
  }

  /// Mark single notification as read
  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    _saveToStorage();
  }

  /// Delete single notification
  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _saveToStorage();
  }

  /// Mark multiple selected notifications as read
  void markMultipleAsRead(List<String> ids) {
    final idSet = ids.toSet();
    state = state.map((n) {
      if (idSet.contains(n.id)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    _saveToStorage();
  }

  /// Delete multiple selected notifications
  void deleteMultiple(List<String> ids) {
    final idSet = ids.toSet();
    state = state.where((n) => !idSet.contains(n.id)).toList();
    _saveToStorage();
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    _saveToStorage();
  }

  /// Delete all notifications permanently
  void deleteAll() {
    state = [];
    _saveToStorage();
  }
}

final notificationProvider = StateNotifierProvider<NotificationStateNotifier, List<AppNotification>>((ref) {
  return NotificationStateNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationProvider);
  return notifs.where((n) => !n.isRead).length;
});
