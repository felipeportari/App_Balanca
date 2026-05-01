import '../models/user_profile.dart';

// Raw BLE packet parser and command builder.
// Byte layouts marked as TODO will be confirmed after BLE capture with nRF Connect.
// See docs/reverse_engineering/HOW_TO_CAPTURE_BLE.md

enum MeasurementStatus { measuring, stable, impedanceDone, unknown }

class ScalePacket {
  final MeasurementStatus status;
  final double weightKg;
  final int? impedanceOhm;

  const ScalePacket({
    required this.status,
    required this.weightKg,
    this.impedanceOhm,
  });
}

class ScaleProtocol {
  // Parse incoming notify packet from scale.
  // TODO: confirm exact byte layout via BLE capture (nRF Connect log).
  static ScalePacket? parseNotify(List<int> bytes) {
    if (bytes.length < 6) return null;
    if (bytes[0] != 0xFF) return null;

    final statusByte = bytes[1];
    final status = switch (statusByte) {
      0x01 => MeasurementStatus.measuring,
      0x02 => MeasurementStatus.stable,
      0x03 => MeasurementStatus.impedanceDone,
      _ => MeasurementStatus.unknown,
    };

    final weightRaw = (bytes[3] << 8) | bytes[4];
    final weightKg = weightRaw / 10.0;

    int? impedance;
    if (bytes.length >= 8 && (bytes[5] != 0 || bytes[6] != 0)) {
      impedance = (bytes[5] << 8) | bytes[6];
    }

    return ScalePacket(
      status: status,
      weightKg: weightKg,
      impedanceOhm: impedance,
    );
  }

  // Build user profile command to send to scale before measurement.
  // TODO: confirm via BLE capture.
  static List<int> buildUserProfileCmd(UserProfile profile) {
    final bytes = [
      0xFF,
      0x12,
      profile.unitByte,
      profile.heightCm,
      profile.ageYears,
      profile.genderByte,
      0x00, // checksum placeholder
    ];
    // XOR checksum of bytes[1..5]
    bytes[6] = bytes.skip(1).take(5).reduce((a, b) => a ^ b);
    return bytes;
  }
}
