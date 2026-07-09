class MedicationReminder {
  final int? id;
  final int userId;
  final String medicineName;
  final String dosage;
  final String time;
  final String notes;
  final bool isActive;
  final DateTime createdAt;

  MedicationReminder({
    this.id,
    required this.userId,
    required this.medicineName,
    required this.dosage,
    required this.time,
    this.notes = '',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'medicineName': medicineName,
      'dosage': dosage,
      'time': time,
      'notes': notes,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    return MedicationReminder(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      medicineName: map['medicineName'] as String,
      dosage: map['dosage'] as String,
      time: map['time'] as String,
      notes: map['notes'] as String? ?? '',
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  MedicationReminder copyWith({
    int? id,
    int? userId,
    String? medicineName,
    String? dosage,
    String? time,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
