class WeightMeasurement {
  final DateTime timestamp;
  final double weightKg;
  final int? impedanceOhm;
  final BodyComposition? bodyComposition;

  const WeightMeasurement({
    required this.timestamp,
    required this.weightKg,
    this.impedanceOhm,
    this.bodyComposition,
  });

  double get weightLb => weightKg * 2.20462;
  double get weightJin => weightKg * 2.0;

  Map<String, dynamic> toMap() => {
    'timestamp': timestamp.millisecondsSinceEpoch,
    'weight_kg': weightKg,
    'impedance_ohm': impedanceOhm,
    'body_fat_pct': bodyComposition?.bodyFatPct,
    'muscle_pct': bodyComposition?.musclePct,
    'bone_kg': bodyComposition?.boneKg,
    'water_pct': bodyComposition?.waterPct,
    'bmi': bodyComposition?.bmi,
    'bmr': bodyComposition?.bmr,
    'visceral_fat': bodyComposition?.visceralFat,
  };

  factory WeightMeasurement.fromMap(Map<String, dynamic> map) {
    return WeightMeasurement(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      weightKg: (map['weight_kg'] as num).toDouble(),
      impedanceOhm: map['impedance_ohm'] as int?,
      bodyComposition: map['body_fat_pct'] != null
          ? BodyComposition(
              bodyFatPct: (map['body_fat_pct'] as num).toDouble(),
              musclePct: (map['muscle_pct'] as num).toDouble(),
              boneKg: (map['bone_kg'] as num).toDouble(),
              waterPct: (map['water_pct'] as num).toDouble(),
              bmi: (map['bmi'] as num).toDouble(),
              bmr: (map['bmr'] as num).toDouble(),
              visceralFat: (map['visceral_fat'] as num).toDouble(),
            )
          : null,
    );
  }
}

class BodyComposition {
  final double bodyFatPct;
  final double musclePct;
  final double boneKg;
  final double waterPct;
  final double bmi;
  final double bmr;
  final double visceralFat;

  const BodyComposition({
    required this.bodyFatPct,
    required this.musclePct,
    required this.boneKg,
    required this.waterPct,
    required this.bmi,
    required this.bmr,
    required this.visceralFat,
  });
}
