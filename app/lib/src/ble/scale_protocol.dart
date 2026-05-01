import '../models/user_profile.dart';

// Protocol implementation extracted from chipseaStraightFrame.java and syncChipseaInstruction.java
// Frame header: 0xCA (-54 in signed Java byte)

const _frameHeader = 0xCA;

enum MeasurementStatus { measuring, stable, complete, unknown }

class ScalePacket {
  final MeasurementStatus status;
  final double weightKg;
  final String weightDisplay;
  final BodyData? bodyData;

  const ScalePacket({
    required this.status,
    required this.weightKg,
    required this.weightDisplay,
    this.bodyData,
  });
}

class BodyData {
  final int bodyFatRaw;   // divide by 10 for %
  final int waterRaw;     // divide by 10 for %
  final int muscleRaw;    // already as % * 10 after scale's calculation
  final int bmr;          // kcal
  final int visceralFat;  // index 1–50
  final int boneRaw;      // divide by 10 for kg

  double get bodyFatPct  => bodyFatRaw / 10.0;
  double get waterPct    => waterRaw / 10.0;
  double get musclePct   => muscleRaw / 10.0;
  double get boneKg      => boneRaw / 10.0;

  const BodyData({
    required this.bodyFatRaw,
    required this.waterRaw,
    required this.muscleRaw,
    required this.bmr,
    required this.visceralFat,
    required this.boneRaw,
  });
}

class ScaleProtocol {
  // Parse notify packet from scale.
  // Handles version 0x10 (with body composition) and 0x11 (weight only).
  static ScalePacket? parseNotify(List<int> bytes) {
    if (bytes.length < 6) return null;
    if ((bytes[0] & 0xFF) != _frameHeader) return null;

    final version = bytes[1] & 0xFF;

    if (version == 0x10 && bytes.length >= 8) {
      return _parseV10(bytes);
    } else if (version == 0x11 && bytes.length >= 7) {
      return _parseV11(bytes);
    }
    return null;
  }

  static ScalePacket _parseV10(List<int> bytes) {
    final scaleProperty = bytes[4] & 0xFF;
    final cmdId = _getCmdId(scaleProperty);
    final weight = _parseWeight(bytes[5], bytes[6], scaleProperty);

    BodyData? bodyData;
    if (cmdId > 0 && bytes.length >= 18) {
      bodyData = BodyData(
        bodyFatRaw:  _bytesToInt(bytes[7],  bytes[8]),
        waterRaw:    _bytesToInt(bytes[9],  bytes[10]),
        muscleRaw:   _bytesToInt(bytes[11], bytes[12]),
        bmr:         _bytesToInt(bytes[13], bytes[14]),
        visceralFat: _bytesToInt(bytes[15], bytes[16]),
        boneRaw:     bytes[17] & 0xFF,
      );
    }

    return ScalePacket(
      status: cmdId > 0 ? MeasurementStatus.complete : MeasurementStatus.measuring,
      weightKg: weight.$1,
      weightDisplay: weight.$2,
      bodyData: bodyData,
    );
  }

  static ScalePacket _parseV11(List<int> bytes) {
    final lockFlag = bytes[3] & 0xFF;
    final scaleProperty = bytes.length > 11 ? bytes[11] & 0xFF : 0;
    final weight = _parseWeight(bytes[5], bytes[6], scaleProperty);

    return ScalePacket(
      status: lockFlag == 1 ? MeasurementStatus.stable : MeasurementStatus.measuring,
      weightKg: weight.$1,
      weightDisplay: weight.$2,
    );
  }

  // Build user profile command — version 0x11, single user
  static List<int> buildUserProfileCmd({
    required int userId,
    required UserProfile profile,
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final bytes = List<int>.filled(20, 0);

    bytes[0] = _frameHeader;
    bytes[1] = 0x11;
    bytes[2] = 0x10;
    bytes[3] = 0x10;
    bytes[4] = 0x11; // package field: packet 1 of 1

    // timestamp (int32 big-endian)
    bytes[5] = (ts >> 24) & 0xFF;
    bytes[6] = (ts >> 16) & 0xFF;
    bytes[7] = (ts >> 8)  & 0xFF;
    bytes[8] = ts & 0xFF;

    bytes[9]  = 0;
    bytes[10] = 0;

    // userId (int32 big-endian)
    bytes[11] = (userId >> 24) & 0xFF;
    bytes[12] = (userId >> 16) & 0xFF;
    bytes[13] = (userId >> 8)  & 0xFF;
    bytes[14] = userId & 0xFF;

    // sex+age: male → age|0x80, female → age&0x7F
    final sexAge = profile.gender == Gender.male
        ? (profile.ageYears | 0x80) & 0xFF
        : profile.ageYears & 0x7F;
    bytes[15] = sexAge;
    bytes[16] = profile.heightCm;

    // target weight as short (0 if unknown)
    bytes[17] = 0;
    bytes[18] = 0;

    // XOR checksum of bytes[1..18]
    bytes[19] = _xorChecksum(bytes, 1, 18);
    return bytes;
  }

  // Build user profile command — version 0x10 (legacy)
  static List<int> buildUserProfileCmdV10({
    required int userId,
    required UserProfile profile,
  }) {
    final now = DateTime.now();
    final bytes = List<int>.filled(20, 0);

    bytes[0]  = _frameHeader;
    bytes[1]  = 0x10;
    bytes[2]  = 0x0E;
    bytes[3]  = 0x01;
    bytes[4]  = now.year % 100;
    bytes[5]  = now.month;
    bytes[6]  = now.day;
    bytes[7]  = now.hour;
    bytes[8]  = now.minute;
    bytes[9]  = now.second;

    bytes[10] = (userId >> 24) & 0xFF;
    bytes[11] = (userId >> 16) & 0xFF;
    bytes[12] = (userId >> 8)  & 0xFF;
    bytes[13] = userId & 0xFF;

    bytes[14] = profile.genderByte;
    bytes[15] = profile.ageYears;
    bytes[16] = profile.heightCm;
    bytes[17] = _xorChecksum(bytes, 1, 16);

    return bytes;
  }

  static List<int> buildSelectUserCmd(int userId) {
    final bytes = List<int>.filled(9, 0);
    bytes[0] = _frameHeader;
    bytes[1] = 0x11;
    bytes[2] = 0x05;
    bytes[3] = 0x15;
    bytes[4] = (userId >> 24) & 0xFF;
    bytes[5] = (userId >> 16) & 0xFF;
    bytes[6] = (userId >> 8)  & 0xFF;
    bytes[7] = userId & 0xFF;
    bytes[8] = _xorChecksum(bytes, 1, 7);
    return bytes;
  }

  static List<int> buildRetrieveHistoryCmd() {
    final bytes = List<int>.filled(20, 0);
    bytes[0] = _frameHeader;
    bytes[1] = 0x11;
    bytes[2] = 0x02;
    bytes[3] = 0x11;
    bytes[4] = 0x01;
    bytes[5] = _xorChecksum(bytes, 1, 4);
    return bytes;
  }

  // weight parser — replicates WeightUnitUtil.Parser()
  static (double kg, String display) _parseWeight(int hi, int lo, int scaleProperty) {
    final raw = _bytesToInt(hi, lo);
    final unit = _getUnit(scaleProperty);
    final digit = _getDigit(scaleProperty);

    double displayValue;
    String displayStr;

    if (digit == 1) {
      displayValue = raw / 10.0;
      displayStr = displayValue.toStringAsFixed(1);
    } else if (digit == 2) {
      displayValue = raw / 100.0;
      displayStr = displayValue.toStringAsFixed(2);
    } else {
      displayValue = raw.toDouble();
      displayStr = raw.toString();
    }

    double kgValue;
    switch (unit) {
      case _WeightUnit.jin:
        kgValue = displayValue * 0.5;
      case _WeightUnit.lb:
        kgValue = displayValue * 0.4535924;
      case _WeightUnit.st:
        // stone:  hi byte = stones, lo byte = lb * 10
        kgValue = ((hi * 14) + lo / 10.0) * 0.4535924;
        displayStr = '$hi:${(lo / 10.0).toStringAsFixed(1)}';
      case _WeightUnit.kg:
        kgValue = displayValue;
    }

    return (kgValue, displayStr);
  }

  static int _bytesToInt(int hi, int lo) => ((hi & 0xFF) << 8) | (lo & 0xFF);

  static int _getCmdId(int scaleProperty) => scaleProperty >> 4;

  static _WeightUnit _getUnit(int scaleProperty) {
    switch (scaleProperty & 0x0F) {
      case 1: return _WeightUnit.lb;
      case 2: return _WeightUnit.jin;
      case 3: return _WeightUnit.st;
      default: return _WeightUnit.kg;
    }
  }

  static int _getDigit(int scaleProperty) {
    final flag = (scaleProperty >> 2) & 0x03;
    if (flag == 1) return 2; // TWO decimal places
    return 1;                // ONE decimal place (default)
  }

  static int _xorChecksum(List<int> bytes, int start, int length) {
    int xor = 0;
    for (int i = start; i < start + length; i++) {
      xor ^= bytes[i] & 0xFF;
    }
    return xor;
  }
}

enum _WeightUnit { kg, lb, jin, st }
