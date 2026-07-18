import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/water_reminder.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class WaterReminderState {
  final bool isLoading;
  final List<WaterReminder> reminders;
  final String? error;

  const WaterReminderState({
    this.isLoading = false,
    this.reminders = const [],
    this.error,
  });

  WaterReminderState copyWith({
    bool? isLoading,
    List<WaterReminder>? reminders,
    String? error,
  }) {
    return WaterReminderState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
      error: error,
    );
  }
}

class WaterReminderNotifier extends StateNotifier<WaterReminderState> {
  final Ref _ref;
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  WaterReminderNotifier(this._ref) : super(const WaterReminderState());

  int get _userId => _ref.read(authProvider).user?.id ?? 0;

  Future<void> loadReminders() async {
    if (_userId == 0) return;
    state = state.copyWith(isLoading: true);
    try {
      final maps = await _db.queryAll(
        'water_reminders',
        where: 'userId = ?',
        whereArgs: [_userId],
      );
      final reminders =
          maps.map((map) => WaterReminder.fromMap(map)).toList();
      state = state.copyWith(isLoading: false, reminders: reminders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> addReminder(WaterReminder reminder) async {
    try {
      final id = await _db.insert('water_reminders', reminder.toMap());
      if (id > 0) {
        await loadReminders();
        return null;
      }
      return 'Failed to save reminder';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> updateReminder(WaterReminder reminder) async {
    try {
      await _db.update('water_reminders', reminder.toMap(), reminder.id!);
      await loadReminders();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> deleteReminder(int id) async {
    try {
      await _db.delete('water_reminders', id);
      await _notifService.cancelNotification(id + 1000);
      await loadReminders();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> toggleReminder(int id, bool isActive) async {
    try {
      await _db.update('water_reminders', {'isActive': isActive ? 1 : 0}, id);
      await loadReminders();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }
}

final waterReminderProvider =
    StateNotifierProvider<WaterReminderNotifier, WaterReminderState>((ref) {
  return WaterReminderNotifier(ref);
});
