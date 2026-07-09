enum RiskLevel {
  low,
  moderate,
  high,
}

extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }
}

class RiskPrediction {
  final int? id;
  final int userId;
  final double age;
  final double bmi;
  final double bloodSugar;
  final double hba1c;
  final int exerciseFrequency;
  final bool familyHistory;
  final RiskLevel riskLevel;
  final double confidenceScore;
  final String lifestyleSuggestions;
  final DateTime createdAt;

  RiskPrediction({
    this.id,
    required this.userId,
    required this.age,
    required this.bmi,
    required this.bloodSugar,
    required this.hba1c,
    required this.exerciseFrequency,
    required this.familyHistory,
    required this.riskLevel,
    required this.confidenceScore,
    this.lifestyleSuggestions = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'age': age,
      'bmi': bmi,
      'bloodSugar': bloodSugar,
      'hba1c': hba1c,
      'exerciseFrequency': exerciseFrequency,
      'familyHistory': familyHistory ? 1 : 0,
      'riskLevel': riskLevel.index,
      'confidenceScore': confidenceScore,
      'lifestyleSuggestions': lifestyleSuggestions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RiskPrediction.fromMap(Map<String, dynamic> map) {
    return RiskPrediction(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      age: (map['age'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      bloodSugar: (map['bloodSugar'] as num).toDouble(),
      hba1c: (map['hba1c'] as num).toDouble(),
      exerciseFrequency: map['exerciseFrequency'] as int,
      familyHistory: (map['familyHistory'] as int) == 1,
      riskLevel: RiskLevel.values[map['riskLevel'] as int],
      confidenceScore: (map['confidenceScore'] as num).toDouble(),
      lifestyleSuggestions: map['lifestyleSuggestions'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
