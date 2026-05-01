import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../ble/scale_uuids.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final List<ScanResult> _results = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _results.clear();
      _scanning = true;
    });

    FlutterBluePlus.startScan(
      withServices: ScaleUuids.knownServices,
      timeout: const Duration(seconds: 15),
    );

    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) setState(() => _results
        ..clear()
        ..addAll(results));
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _scanning = scanning);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procurar balança'),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(onPressed: _startScan, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bluetooth_searching, size: 64),
                  const SizedBox(height: 16),
                  Text(_scanning ? 'Procurando...' : 'Nenhuma balança encontrada'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final r = _results[i];
                final name = r.device.platformName.isEmpty ? 'Balança BLE' : r.device.platformName;
                return ListTile(
                  leading: const Icon(Icons.monitor_weight),
                  title: Text(name),
                  subtitle: Text(r.device.remoteId.str),
                  trailing: Text('${r.rssi} dBm'),
                  onTap: () {
                    FlutterBluePlus.stopScan();
                    // TODO: navigate to measurement screen
                  },
                );
              },
            ),
    );
  }
}
