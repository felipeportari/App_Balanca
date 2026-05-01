enum Gender { male, female }
enum WeightUnit { kg, lb, jin }

class UserProfile {
  final int heightCm;
  final int ageYears;
  final Gender gender;
  final WeightUnit unit;
  final double? targetWeightKg;

  const UserProfile({
    required this.heightCm,
    required this.ageYears,
    required this.gender,
    this.unit = WeightUnit.kg,
    this.targetWeightKg,
  });

  UserProfile copyWith({
    int? heightCm,
    int? ageYears,
    Gender? gender,
    WeightUnit? unit,
    double? targetWeightKg,
  }) {
    return UserProfile(
      heightCm: heightCm ?? this.heightCm,
      ageYears: ageYears ?? this.ageYears,
      gender: gender ?? this.gender,
      unit: unit ?? this.unit,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    );
  }

  int get genderByte => gender == Gender.male ? 0x01 : 0x00;
  int get unitByte {
    switch (unit) {
      case WeightUnit.kg: return 0x00;
      case WeightUnit.lb: return 0x01;
      case WeightUnit.jin: return 0x02;
    }
  }

  Map<String, dynamic> toMap() => {
    'id': 1,
    'height_cm': heightCm,
    'age_years': ageYears,
    'gender': gender.name,
    'weight_unit': unit.name,
    'target_weight_kg': targetWeightKg,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    heightCm: map['height_cm'] as int,
    ageYears: map['age_years'] as int,
    gender: Gender.values.firstWhere((g) => g.name == map['gender']),
    unit: WeightUnit.values.firstWhere((u) => u.name == map['weight_unit']),
    targetWeightKg: (map['target_weight_kg'] as num?)?.toDouble(),
  );
}
