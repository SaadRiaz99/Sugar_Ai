import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/risk_prediction.dart';
import '../ai/risk_predictor.dart';
import 'auth_provider.dart';

class RiskPredictionState {
  final bool isLoading;
  final List<RiskPrediction> predictions;
  final RiskPrediction? lastPrediction;
  final String? error;

  const RiskPredictionState({
    this.isLoading = false,
    this.predictions = const [],
    this.lastPrediction,
    this.error,
  });

  RiskPredictionState copyWith({
    bool? isLoading,
    List<RiskPrediction>? predictions,
    RiskPrediction? lastPrediction,
    String? error,
  }) {
    return RiskPredictionState(
      isLoading: isLoading ?? this.isLoading,
      predictions: predictions ?? this.predictions,
      lastPrediction: lastPrediction ?? this.lastPrediction,
      error: error,
    );
  }
}

class RiskPredictionNotifier extends StateNotifier<RiskPredictionState> {
  final Ref _ref;
  final DatabaseHelper _db = DatabaseHelper();
  final RiskPredictor _predictor = RiskPredictor();

  RiskPredictionNotifier(this._ref) : super(const RiskPredictionState());

  int get _userId => _ref.read(authProvider).user?.id ?? 0;

  Future<void> loadPredictions() async {
    if (_userId == 0) return;
    state = state.copyWith(isLoading: true);
    try {
      final maps = await _db.queryAll(
        'risk_predictions',
        where: 'userId = ?',
        whereArgs: [_userId],
        orderBy: 'createdAt DESC',
      );
      final predictions =
          maps.map((map) => RiskPrediction.fromMap(map)).toList();
      state = state.copyWith(
        isLoading: false,
        predictions: predictions,
        lastPrediction: predictions.isNotEmpty ? predictions.first : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> predict({
    required double age,
    required double bmi,
    required double bloodSugar,
    required double hba1c,
    required int exerciseFrequency,
    required bool familyHistory,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _predictor.predict(
        age: age,
        bmi: bmi,
        bloodSugar: bloodSugar,
        hba1c: hba1c,
        exerciseFrequency: exerciseFrequency,
        familyHistory: familyHistory,
      );

      final prediction = RiskPrediction(
        userId: _userId,
        age: age,
        bmi: bmi,
        bloodSugar: bloodSugar,
        hba1c: hba1c,
        exerciseFrequency: exerciseFrequency,
        familyHistory: familyHistory,
        riskLevel: result.riskLevel,
        confidenceScore: result.confidenceScore,
        lifestyleSuggestions: result.lifestyleSuggestions,
      );

      final id = await _db.insert('risk_predictions', prediction.toMap());
      await loadPredictions();

      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return 'Prediction failed: $e';
    }
  }
}

final riskPredictionProvider =
    StateNotifierProvider<RiskPredictionNotifier, RiskPredictionState>((ref) {
  return RiskPredictionNotifier(ref);
});
