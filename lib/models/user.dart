class User {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final double bmi;
  final bool familyHistory;
  final String smokingStatus;
  final String exerciseFrequency;
  final String currentMedications;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.familyHistory,
    required this.smokingStatus,
    required this.exerciseFrequency,
    required this.currentMedications,
    required this.email,
    required this.passwordHash,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'familyHistory': familyHistory ? 1 : 0,
      'smokingStatus': smokingStatus,
      'exerciseFrequency': exerciseFrequency,
      'currentMedications': currentMedications,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      familyHistory: (map['familyHistory'] as int) == 1,
      smokingStatus: map['smokingStatus'] as String,
      exerciseFrequency: map['exerciseFrequency'] as String,
      currentMedications: map['currentMedications'] as String,
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  User copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? bmi,
    bool? familyHistory,
    String? smokingStatus,
    String? exerciseFrequency,
    String? currentMedications,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      familyHistory: familyHistory ?? this.familyHistory,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      exerciseFrequency: exerciseFrequency ?? this.exerciseFrequency,
      currentMedications: currentMedications ?? this.currentMedications,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
