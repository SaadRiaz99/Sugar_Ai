import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/blood_sugar_record.dart';
import 'auth_provider.dart';

class BloodSugarState {
  final bool isLoading;
  final List<BloodSugarRecord> records;
  final String? error;

  const BloodSugarState({
    this.isLoading = false,
    this.records = const [],
    this.error,
  });

  BloodSugarState copyWith({
    bool? isLoading,
    List<BloodSugarRecord>? records,
    String? error,
  }) {
    return BloodSugarState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      error: error,
    );
  }
}

class BloodSugarNotifier extends StateNotifier<BloodSugarState> {
  final Ref _ref;
  final DatabaseHelper _db = DatabaseHelper();

  BloodSugarNotifier(this._ref) : super(const BloodSugarState());

  int get _userId => _ref.read(authProvider).user?.id ?? 0;

  Future<void> loadRecords() async {
    if (_userId == 0) return;
    state = state.copyWith(isLoading: true);
    try {
      final maps = await _db.queryAll(
        'blood_sugar_records',
        where: 'userId = ?',
        whereArgs: [_userId],
        orderBy: 'dateTime DESC',
      );
      final records =
          maps.map((map) => BloodSugarRecord.fromMap(map)).toList();
      state = state.copyWith(isLoading: false, records: records);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> addRecord(BloodSugarRecord record) async {
    try {
      final id = await _db.insert(
          'blood_sugar_records', record.toMap());
      if (id > 0) {
        await loadRecords();
        return null;
      }
      return 'Failed to save record';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String?> deleteRecord(int id) async {
    try {
      await _db.delete('blood_sugar_records', id);
      await loadRecords();
      return null;
    } catch (e) {
      return 'Error: $e';
    }
  }

  List<BloodSugarRecord> getRecordsByType(BloodSugarType type) {
    return state.records
        .where((r) => r.type == type)
        .toList();
  }

  List<BloodSugarRecord> getRecordsForPeriod(DateTime start, DateTime end) {
    return state.records
        .where((r) =>
            r.dateTime.isAfter(start) && r.dateTime.isBefore(end))
        .toList();
  }

  double getAverageForType(BloodSugarType type) {
    final records = getRecordsByType(type);
    if (records.isEmpty) return 0;
    return records.fold(0.0, (sum, r) => sum + r.value) /
        records.length;
  }
}

final bloodSugarProvider =
    StateNotifierProvider<BloodSugarNotifier, BloodSugarState>((ref) {
  return BloodSugarNotifier(ref);
});
