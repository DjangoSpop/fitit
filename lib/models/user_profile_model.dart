class UserProfile {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String fitnessLevel;
  final List<String> goals;
  final List<String> availableEquipment;
  final String personalityType;
  final String notificationPreference;
  final DateTime? createdAt;

  UserProfile({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.fitnessLevel,
    required this.goals,
    required this.availableEquipment,
    this.personalityType = 'balanced',
    this.notificationPreference = 'moderate',
    this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      gender: map['gender'] as String? ?? '',
      height: map['height'] as double? ?? 0.0,
      weight: map['weight'] as double? ?? 0.0,
      fitnessLevel: map['fitness_level'] as String? ?? 'beginner',
      goals: (map['goals'] as String?)?.split(',') ?? [],
      availableEquipment: (map['available_equipment'] as String?)?.split(',') ?? [],
      personalityType: map['personality_type'] as String? ?? 'balanced',
      notificationPreference: map['notification_preference'] as String? ?? 'moderate',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'fitness_level': fitnessLevel,
      'goals': goals.join(','),
      'available_equipment': availableEquipment.join(','),
      'personality_type': personalityType,
      'notification_preference': notificationPreference,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? fitnessLevel,
    List<String>? goals,
    List<String>? availableEquipment,
    String? personalityType,
    String? notificationPreference,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      goals: goals ?? this.goals,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      personalityType: personalityType ?? this.personalityType,
      notificationPreference: notificationPreference ?? this.notificationPreference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
