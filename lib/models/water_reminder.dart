class WaterReminder {
  final int? id;
  final int userId;
  final int intervalMinutes;
  final bool isActive;
  final DateTime createdAt;

  WaterReminder({
    this.id,
    required this.userId,
    required this.intervalMinutes,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'intervalMinutes': intervalMinutes,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WaterReminder.fromMap(Map<String, dynamic> map) {
    return WaterReminder(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      intervalMinutes: map['intervalMinutes'] as int,
      isActive: (map['isActive'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  WaterReminder copyWith({
    int? id,
    int? userId,
    int? intervalMinutes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WaterReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
