import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/medication_reminder.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class MedicationState {
  final bool isLoading;
  final List<MedicationReminder> reminders;
  final String? error;

  const MedicationState({
    this.isLoading = false,
    this.reminders = const [],
    this.error,
  });

  MedicationState copyWith({
    bool? isLoading,
    List<MedicationReminder>? reminders,
    String? error,
  }) {
    return MedicationState(
      isLoading: isLoading ?? this.isLoading,
      reminders: reminders ?? this.reminders,
      error: error,
    );
  }
}

class MedicationNotifier extends StateNotifier<MedicationState> {
  final Ref _ref;
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notifService = NotificationService();

  MedicationNotifier(this._ref) : super(const MedicationState());

  int get _userId => _ref.read(authProvider).user?.id ?? 0;

  Future<void> loadReminders() async {
    if (_userId == 0) return;
    state = state.copyWith(isLoading: true);
    try {
      final maps = await _db.queryAll(
        'medication_reminders',
        where: 'userId = ?',
        whereArgs: [_userId],
        orderBy: 'time ASC',
      );
      final reminders = maps
          .map((map) => MedicationReminder.fromMap(map))
          .toList();
      state = state.copyWith(isLoading: false, reminders: reminders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> addReminder(MedicationReminder reminder) async {
    try {
      final id = await _db.insert(
          'medication_reminders', reminder.toMap());
      if (id > 0) {
        await loadReminders();
        return null;
      }
      return 'Failed to save reminder';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> updateReminder(MedicationReminder reminder) async {
    try {
      await _db.update(
          'medication_reminders', reminder.toMap(), reminder.id!);
      await loadReminders();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> deleteReminder(int id) async {
    try {
      await _db.delete('medication_reminders', id);
      await _notifService.cancelNotification(id);
      await loadReminders();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> toggleReminder(int id, bool isActive) async {
    try {
      await _db.update('medication_reminders', {'isActive': isActive ? 1 : 0}, id);
      await loadReminders();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }
}

final medicationProvider =
    StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  return MedicationNotifier(ref);
});
