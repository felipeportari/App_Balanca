import '../models/user_profile.dart';
import '../models/weight_measurement.dart';

// Body composition formulas used by ChipSea / most BLE scales.
// These are calculated CLIENT-SIDE from weight + impedance + user profile.
// The scale hardware only provides weight and raw impedance (ohms).
class BodyCompositionCalculator {
  static BodyComposition? calculate({
    required double weightKg,
    required int impedanceOhm,
    required UserProfile profile,
  }) {
    if (impedanceOhm <= 0) return null;

    final h = profile.heightCm.toDouble();
    final w = weightKg;
    final age = profile.ageYears.toDouble();
    final isMale = profile.gender == Gender.male;
    final imp = impedanceOhm.toDouble();

    final bmi = _bmi(w, h);
    final lbm = _leanBodyMass(h, w, imp, isMale);
    final bodyFatKg = w - lbm;
    final bodyFatPct = (bodyFatKg / w) * 100;
    final musclePct = (lbm / w) * 100 - 7.5;
    final waterPct = lbm * 0.73 / w * 100;
    final boneKg = _boneWeight(lbm);
    final bmr = _bmr(w, h, age, isMale);
    final visceralFat = _visceralFat(w, h, age, isMale);

    return BodyComposition(
      bodyFatPct: bodyFatPct.clamp(0, 60),
      musclePct: musclePct.clamp(0, 100),
      boneKg: boneKg,
      waterPct: waterPct.clamp(0, 100),
      bmi: bmi,
      bmr: bmr,
      visceralFat: visceralFat,
    );
  }

  static double _bmi(double weightKg, double heightCm) {
    final hm = heightCm / 100;
    return weightKg / (hm * hm);
  }

  // Lean Body Mass via Boer formula adjusted with impedance
  static double _leanBodyMass(double h, double w, double imp, bool isMale) {
    if (isMale) {
      return (0.407 * w) + (0.267 * h) - (0.049 * imp) - 18.1;
    } else {
      return (0.252 * w) + (0.473 * h) - (0.048 * imp) - 48.3;
    }
  }

  static double _boneWeight(double lbm) {
    if (lbm < 22) return 1.7;
    if (lbm < 55) return 2.2;
    return 2.8;
  }

  // Mifflin–St Jeor BMR
  static double _bmr(double w, double h, double age, bool isMale) {
    final base = 10 * w + 6.25 * h - 5 * age;
    return isMale ? base + 5 : base - 161;
  }

  // Simplified visceral fat index
  static double _visceralFat(double w, double h, double age, bool isMale) {
    final bmi = _bmi(w, h);
    if (isMale) {
      return (bmi * 0.6 + age * 0.1 - 10).clamp(1, 50);
    } else {
      return (bmi * 0.5 + age * 0.15 - 12).clamp(1, 50);
    }
  }
}
