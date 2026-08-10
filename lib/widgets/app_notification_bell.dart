import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class AppNotificationBell extends ConsumerStatefulWidget {
  const AppNotificationBell({super.key});

  @override
  ConsumerState<AppNotificationBell> createState() => _AppNotificationBellState();
}

class _AppNotificationBellState extends ConsumerState<AppNotificationBell> {
  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return AppBouncyTap(
      onTap: () => _showNotificationCenter(context, ref),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 21,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppColors.softGlow(AppColors.accent, opacity: 0.4, blur: 6),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    '+$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ).animate().scale(duration: 250.ms, curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  void _showNotificationCenter(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return const NotificationCenterModal();
      },
    );
  }
}

class NotificationCenterModal extends ConsumerStatefulWidget {
  const NotificationCenterModal({super.key});

  @override
  ConsumerState<NotificationCenterModal> createState() => _NotificationCenterModalState();
}

class _NotificationCenterModalState extends ConsumerState<NotificationCenterModal> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectAll(List<AppNotification> notifications) {
    setState(() {
      if (_selectedIds.length == notifications.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(notifications.map((n) => n.id));
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Container(
        width: 520,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Modal Header: Title, Unread Tag, 3-Dots Menu & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+$unreadCount New',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                Row(
                  children: [
                    // 3-Dots Vertical Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
                      tooltip: 'Notification Options',
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onSelected: (value) {
                        if (value == 'select_multiple' || value == 'cancel_selection') {
                          setState(() {
                            _isSelectionMode = !_isSelectionMode;
                            if (!_isSelectionMode) {
                              _selectedIds.clear();
                            }
                          });
                        } else if (value == 'mark_all_read') {
                          ref.read(notificationProvider.notifier).markAllAsRead();
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        } else if (value == 'delete_all') {
                          ref.read(notificationProvider.notifier).deleteAll();
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: _isSelectionMode ? 'cancel_selection' : 'select_multiple',
                          child: Row(
                            children: [
                              Icon(
                                _isSelectionMode ? Icons.close_rounded : Icons.checklist_rounded,
                                size: 18,
                                color: _isSelectionMode ? Colors.redAccent : AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(_isSelectionMode ? 'Cancel Selection' : 'Select Multiple'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              Icon(Icons.done_all_rounded, size: 18, color: AppColors.secondary),
                              SizedBox(width: 10),
                              Text('Mark All as Read'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                              SizedBox(width: 10),
                              Text('Delete All'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Notification Cards List
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No notifications yet',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Unlock badges & log workouts to see alerts here!',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final isSelected = _selectedIds.contains(item.id);
                        final formattedTime = DateFormat('MMM d, h:mm a').format(item.timestamp);

                        return AppBouncyTap(
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelect(item.id);
                            } else {
                              _showDetailDialog(context, ref, item);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isRead ? AppColors.surfaceLight.withValues(alpha: 0.5) : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (item.isRead
                                        ? AppColors.border
                                        : AppColors.primary.withValues(alpha: 0.35)),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: item.isRead
                                  ? null
                                  : AppColors.softGlow(AppColors.primary, opacity: 0.08, blur: 8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Selection Checkbox
                                if (_isSelectionMode) ...[
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) => _toggleSelect(item.id),
                                  ),
                                  const SizedBox(width: 8),
                                ],

                                // Status Dot Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: item.isRead
                                        ? AppColors.surfaceLight
                                        : AppColors.accent.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.type == 'badge'
                                        ? Icons.emoji_events_rounded
                                        : Icons.fitness_center_rounded,
                                    color: item.isRead ? AppColors.textMuted : AppColors.accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Title, Message & Timestamp
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                                fontSize: 13.5,
                                                color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            formattedTime,
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // Individual Actions: Mark as Read & Delete
                                      if (!_isSelectionMode) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (!item.isRead) ...[
                                              InkWell(
                                                onTap: () => ref.read(notificationProvider.notifier).markAsRead(item.id),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Mark Read',
                                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            InkWell(
                                              onTap: () => ref.read(notificationProvider.notifier).deleteNotification(item.id),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Selection Mode Bottom Bar (Tabs: Mark Selected Read | Delete Selected)
            if (_isSelectionMode && notifications.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: _selectedIds.length == notifications.length ? 'Deselect All' : 'Select All',
                      icon: Icon(
                        _selectedIds.length == notifications.length ? Icons.deselect_rounded : Icons.select_all_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      onPressed: () => _toggleSelectAll(notifications),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () {
                                ref.read(notificationProvider.notifier).markMultipleAsRead(_selectedIds.toList());
                                setState(() {
                                  _selectedIds.clear();
                                  _isSelectionMode = false;
                                });
                              },
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: Text(
                          'Mark Read (${_selectedIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () {
                                ref.read(notificationProvider.notifier).deleteMultiple(_selectedIds.toList());
                                setState(() {
                                  _selectedIds.clear();
                                  _isSelectionMode = false;
                                });
                              },
                        icon: const Icon(Icons.delete_rounded, size: 16),
                        label: Text(
                          'Delete Selected (${_selectedIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, WidgetRef ref, AppNotification item) {
    if (!item.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(item.id);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.message,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 14),
            Text(
              'Received on ${DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(item.timestamp)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
