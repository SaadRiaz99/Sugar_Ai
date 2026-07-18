enum BloodSugarType {
  fasting,
  random,
  beforeMeal,
  afterMeal,
  hba1c,
}

extension BloodSugarTypeExtension on BloodSugarType {
  String get displayName {
    switch (this) {
      case BloodSugarType.fasting:
        return 'Fasting Blood Sugar';
      case BloodSugarType.random:
        return 'Random Blood Sugar';
      case BloodSugarType.beforeMeal:
        return 'Before Meal';
      case BloodSugarType.afterMeal:
        return 'After Meal';
      case BloodSugarType.hba1c:
        return 'HbA1c';
    }
  }

  String get unit {
    switch (this) {
      case BloodSugarType.hba1c:
        return '%';
      default:
        return 'mg/dL';
    }
  }

  double get normalRangeLow {
    switch (this) {
      case BloodSugarType.fasting:
        return 70;
      case BloodSugarType.random:
        return 70;
      case BloodSugarType.beforeMeal:
        return 70;
      case BloodSugarType.afterMeal:
        return 70;
      case BloodSugarType.hba1c:
        return 4.0;
    }
  }

  double get normalRangeHigh {
    switch (this) {
      case BloodSugarType.fasting:
        return 100;
      case BloodSugarType.random:
        return 140;
      case BloodSugarType.beforeMeal:
        return 100;
      case BloodSugarType.afterMeal:
        return 140;
      case BloodSugarType.hba1c:
        return 5.7;
    }
  }
}

class BloodSugarRecord {
  final int? id;
  final int userId;
  final BloodSugarType type;
  final double value;
  final DateTime dateTime;
  final String notes;
  final DateTime createdAt;

  BloodSugarRecord({
    this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.dateTime,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'type': type.index,
      'value': value,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BloodSugarRecord.fromMap(Map<String, dynamic> map) {
    return BloodSugarRecord(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      type: BloodSugarType.values[map['type'] as int],
      value: (map['value'] as num).toDouble(),
      dateTime: DateTime.parse(map['dateTime'] as String),
      notes: map['notes'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
