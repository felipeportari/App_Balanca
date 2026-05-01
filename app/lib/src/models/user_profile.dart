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

  // Byte encoding for scale BLE command (to be confirmed via BLE capture)
  int get genderByte => gender == Gender.male ? 0x01 : 0x00;
  int get unitByte {
    switch (unit) {
      case WeightUnit.kg: return 0x00;
      case WeightUnit.lb: return 0x01;
      case WeightUnit.jin: return 0x02;
    }
  }
}
