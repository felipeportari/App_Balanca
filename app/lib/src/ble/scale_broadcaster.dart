import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Protocol decoded from nRF Connect CSV broadcast capture.
// Raw AD example: 10 FF C0 06 21 48 17 70 0A 01 25 80 F4 16 97 B5 0A
// Company ID: 0x06C0 (bytes C0 06 in raw AD, little-endian)
// Manufacturer payload (13 bytes after company ID):
//   [0..1]   = weight, big-endian, divide by 100 → kg  (e.g. 0x2148 = 85.2 kg)
//   [2..3]   = impedance, big-endian, divide by 10 → Ω (0 while measuring)
//   [4]      = 0x0A (constant)
//   [5]      = 0x01 (constant)
//   [6]      = flags: 0x25 = stable+impedance, 0x24 = measuring
//   [7..12]  = MAC address bytes

const _companyId = 0x06C0;

class BroadcastMeasurement {
  final double weightKg;
  final double? impedanceOhm;
  final bool isStable;
  final int rssi;
  final String deviceId;

  const BroadcastMeasurement({
    required this.weightKg,
    required this.isStable,
    required this.rssi,
    required this.deviceId,
    this.impedanceOhm,
  });

  String get weightDisplay => weightKg.toStringAsFixed(2);
}

class ScaleBroadcaster {
  static BroadcastMeasurement? parse(ScanResult result) {
    final mfData = result.advertisementData.manufacturerData[_companyId];
    if (mfData == null || mfData.length < 7) return null;

    final weightRaw = ((mfData[0] & 0xFF) << 8) | (mfData[1] & 0xFF);
    if (weightRaw == 0) return null;

    final impRaw = ((mfData[2] & 0xFF) << 8) | (mfData[3] & 0xFF);
    final flags = mfData[6] & 0xFF;
    final isStable = (flags & 0x01) != 0; // bit 0 = stable

    return BroadcastMeasurement(
      weightKg: weightRaw / 100.0,
      impedanceOhm: impRaw > 0 ? impRaw / 10.0 : null,
      isStable: isStable,
      rssi: result.rssi,
      deviceId: result.device.remoteId.str,
    );
  }
}
