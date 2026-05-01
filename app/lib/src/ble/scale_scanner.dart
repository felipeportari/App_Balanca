import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'scale_uuids.dart';

class ScaleScanner {
  static Stream<List<ScanResult>> scan({Duration timeout = const Duration(seconds: 15)}) {
    FlutterBluePlus.startScan(
      withServices: ScaleUuids.knownServices,
      timeout: timeout,
    );
    return FlutterBluePlus.scanResults;
  }

  static Future<void> stop() => FlutterBluePlus.stopScan();

  // Detect which protocol variant a discovered device uses
  static _ScaleProtocol? detectProtocol(BluetoothDevice device, List<ScanResult> results) {
    final result = results.firstWhere(
      (r) => r.device.remoteId == device.remoteId,
      orElse: () => throw StateError('Device not in scan results'),
    );
    final uuids = result.advertisementData.serviceUuids.map((u) => u.str128.toLowerCase()).toSet();

    if (uuids.contains(ScaleUuids.serviceD618D.str128.toLowerCase())) {
      return _ScaleProtocol(
        service: ScaleUuids.serviceD618D,
        write: ScaleUuids.writeD618D,
        notify: ScaleUuids.notifyD618D,
      );
    }
    if (uuids.contains(ScaleUuids.serviceFff0.str128.toLowerCase())) {
      return _ScaleProtocol(
        service: ScaleUuids.serviceFff0,
        write: ScaleUuids.writeFff1,
        notify: ScaleUuids.notifyFff2,
      );
    }
    if (uuids.contains(ScaleUuids.serviceFfe0.str128.toLowerCase())) {
      return _ScaleProtocol(
        service: ScaleUuids.serviceFfe0,
        write: ScaleUuids.notifyFfe4,
        notify: ScaleUuids.notifyFfe4,
      );
    }
    if (uuids.contains(ScaleUuids.serviceFaa0.str128.toLowerCase())) {
      return _ScaleProtocol(
        service: ScaleUuids.serviceFaa0,
        write: ScaleUuids.writeFaa1,
        notify: ScaleUuids.notifyFaa2,
      );
    }
    return null;
  }
}

class _ScaleProtocol {
  final Guid service;
  final Guid write;
  final Guid notify;
  const _ScaleProtocol({required this.service, required this.write, required this.notify});
}
