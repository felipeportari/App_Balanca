import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// BLE UUIDs extracted from OKOK International APK (com.chipsea.btcontrol)
// Multiple protocol variants — the scale will advertise one of these services.

class ScaleUuids {
  // Protocol D618D — primary ChipSea protocol (newer devices)
  static final serviceD618D    = Guid('D618D000-6000-1000-8000-000000000000');
  static final writeD618D      = Guid('D618D001-6000-1000-8000-000000000000');
  static final notifyD618D     = Guid('D618D002-6000-1000-8000-000000000000');

  // Protocol FFF0 — legacy / most common on cheap BLE scales
  static final serviceFff0     = Guid('0000FFF0-0000-1000-8000-00805F9B34FB');
  static final writeFff1       = Guid('0000FFF1-0000-1000-8000-00805F9B34FB');
  static final notifyFff2      = Guid('0000FFF2-0000-1000-8000-00805F9B34FB');

  // Protocol FFE0
  static final serviceFfe0     = Guid('0000FFE0-0000-1000-8000-00805F9B34FB');
  static final notifyFfe4      = Guid('0000FFE4-0000-1000-8000-00805F9B34FB');

  // Protocol FAA0
  static final serviceFaa0     = Guid('0000FAA0-0000-1000-8000-00805F9B34FB');
  static final writeFaa1       = Guid('0000FAA1-0000-1000-8000-00805F9B34FB');
  static final notifyFaa2      = Guid('0000FAA2-0000-1000-8000-00805F9B34FB');

  // Protocol A620 (body composition)
  static final serviceA602     = Guid('0000A602-0000-1000-8000-00805F9B34FB');
  static final writeA620       = Guid('0000A620-0000-1000-8000-00805F9B34FB');
  static final notifyA621      = Guid('0000A621-0000-1000-8000-00805F9B34FB');

  // Protocol FFA0
  static final serviceFfa0     = Guid('0000FFA0-0000-1000-8000-00805F9B34FB');
  static final writeFfa1       = Guid('0000FFA1-0000-1000-8000-00805F9B34FB');
  static final notifyFfa2      = Guid('0000FFA2-0000-1000-8000-00805F9B34FB');

  // Standard BLE descriptors
  static final cccd            = Guid('00002902-0000-1000-8000-00805F9B34FB');

  // All known scale service UUIDs (for scan filtering)
  static final knownServices = [
    serviceD618D, serviceFff0, serviceFfe0,
    serviceFaa0, serviceA602, serviceFfa0,
  ];
}
