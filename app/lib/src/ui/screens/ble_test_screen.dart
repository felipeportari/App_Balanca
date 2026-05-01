import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../ble/scale_broadcaster.dart';

const _scaleServices = [
  '0000fff0-0000-1000-8000-00805f9b34fb',
  'd618d000-6000-1000-8000-000000000000',
  '0000faa0-0000-1000-8000-00805f9b34fb',
  '0000a602-0000-1000-8000-00805f9b34fb',
  '0000ffe0-0000-1000-8000-00805f9b34fb',
  '0000ffa0-0000-1000-8000-00805f9b34fb',
];

class BleTestScreen extends StatefulWidget {
  const BleTestScreen({super.key});

  @override
  State<BleTestScreen> createState() => _BleTestScreenState();
}

class _BleTestScreenState extends State<BleTestScreen> {
  final List<ScanResult> _devices = [];
  final List<_LogEntry> _log = [];
  BluetoothDevice? _connected;
  bool _scanning = false;
  BroadcastMeasurement? _lastBroadcast;
  StreamSubscription? _scanSub;
  StreamSubscription? _scanStateSub;
  StreamSubscription? _notifySub;

  @override
  void dispose() {
    _scanSub?.cancel();
    _scanStateSub?.cancel();
    _notifySub?.cancel();
    _connected?.disconnect();
    super.dispose();
  }

  void _addLog(String msg, {Color color = Colors.white}) {
    setState(() {
      _log.insert(0, _LogEntry(msg, color));
      if (_log.length > 200) _log.removeLast();
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _lastBroadcast = null;
      _scanning = true;
    });
    _addLog('Procurando balanças BLE...', color: Colors.blue);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      setState(() {
        _devices.clear();
        _devices.addAll(results);
      });

      for (final r in results) {
        final m = ScaleBroadcaster.parse(r);
        if (m != null) {
          final prev = _lastBroadcast;
          if (prev == null ||
              m.weightKg != prev.weightKg ||
              m.isStable != prev.isStable ||
              m.impedanceOhm != prev.impedanceOhm) {
            setState(() => _lastBroadcast = m);
            _addLog(
              'BROADCAST ${m.deviceId}  ${m.weightDisplay} kg'
              '${m.isStable ? " ✓ ESTÁVEL" : " ..."}'
              '${m.impedanceOhm != null ? "  imp=${m.impedanceOhm!.toStringAsFixed(1)} Ω" : ""}'
              '  rssi=${m.rssi} dBm',
              color: m.isStable ? Colors.greenAccent : Colors.yellow,
            );
          }
        }
      }
    });

    _scanStateSub?.cancel();
    _scanStateSub = FlutterBluePlus.isScanning.listen((v) {
      if (!v && mounted) {
        setState(() => _scanning = false);
        _addLog(
          'Scan finalizado — ${_devices.length} dispositivo(s)',
          color: Colors.blue,
        );
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    _addLog(
      'Conectando em ${device.platformName.isEmpty ? device.remoteId : device.platformName}...',
      color: Colors.orange,
    );

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      setState(() => _connected = device);
      _addLog('Conectado!', color: Colors.green);

      await device.discoverServices();
      final services = device.servicesList;
      _addLog('${services.length} serviço(s) GATT encontrado(s):', color: Colors.cyan);

      for (final svc in services) {
        final uuid = svc.serviceUuid.str128.toLowerCase();
        final isScale = _scaleServices.contains(uuid);
        _addLog(
          '  SVC ${svc.serviceUuid.str}${isScale ? " ← BALANÇA ✓" : ""}',
          color: isScale ? Colors.greenAccent : Colors.white54,
        );

        for (final ch in svc.characteristics) {
          final props = [
            if (ch.properties.read) 'R',
            if (ch.properties.write) 'W',
            if (ch.properties.notify) 'N',
            if (ch.properties.indicate) 'I',
          ].join('|');
          _addLog('    CHAR ${ch.characteristicUuid.str} [$props]', color: Colors.white70);

          if (ch.properties.notify) {
            _addLog('    → Ativando notificações...', color: Colors.yellow);
            await ch.setNotifyValue(true);
            _notifySub = ch.onValueReceived.listen((bytes) => _onData(ch, bytes));
            _addLog('    → Notificações ativas!', color: Colors.greenAccent);
          }
        }
      }
    } catch (e) {
      _addLog('Erro: $e', color: Colors.red);
    }
  }

  void _onData(BluetoothCharacteristic ch, List<int> bytes) {
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
    final header =
        bytes.isNotEmpty ? '0x${bytes[0].toRadixString(16).toUpperCase().padLeft(2, '0')}' : '?';
    final isScale = header == '0xCA';

    _addLog(
      '◀ ${ch.characteristicUuid.str.substring(4, 8).toUpperCase()}: $hex'
      '${isScale ? " ← frame 0xCA ✓" : ""}',
      color: isScale ? Colors.greenAccent : Colors.white,
    );

    if (isScale && bytes.length >= 6) {
      _parseAndLog(bytes);
    }
  }

  void _parseAndLog(List<int> b) {
    final version = b[1];
    if (version == 0x10 || version == 0x11) {
      final raw = (b[5] << 8) | b[6];
      final kg = raw / 10.0;
      _addLog('  → PESO: ${kg.toStringAsFixed(1)} kg (raw=$raw)', color: Colors.yellowAccent);

      if (version == 0x10 && b.length >= 8) {
        final cmdId = b[4] >> 4;
        _addLog(
          '  → cmdId=$cmdId${cmdId > 0 ? " (composição corporal disponível)" : " (medindo...)"}',
          color: Colors.white70,
        );
      }
      if (version == 0x11) {
        final lock = b[3];
        _addLog(
          '  → lockFlag=$lock${lock == 1 ? " (ESTÁVEL)" : " (medindo...)"}',
          color: Colors.white70,
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _notifySub?.cancel();
    await _connected?.disconnect();
    setState(() {
      _connected = null;
      _devices.clear();
    });
    _addLog('Desconectado.', color: Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_connected == null ? 'Teste BLE — Scan' : 'Teste BLE — Conectado'),
        actions: [
          if (_connected != null)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnect,
              tooltip: 'Desconectar',
            ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _log.map((e) => e.msg).join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Log copiado!')),
              );
            },
            tooltip: 'Copiar log',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Broadcast weight card (always visible while scanning) ──
          if (_lastBroadcast != null) _BroadcastCard(m: _lastBroadcast!),

          // ── Scan button / device list ──
          if (_connected == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _scanning ? null : _startScan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(_scanning ? 'Procurando...' : 'Buscar balança'),
                ),
              ),
            ),
            if (_devices.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (_, i) {
                    final r = _devices[i];
                    final name =
                        r.device.platformName.isEmpty ? '(sem nome)' : r.device.platformName;
                    final uuids =
                        r.advertisementData.serviceUuids.map((u) => u.str128.toLowerCase()).toList();
                    final isScale = uuids.any(_scaleServices.contains);
                    final hasBroadcast =
                        ScaleBroadcaster.parse(r) != null;
                    return ListTile(
                      leading: Icon(
                        Icons.monitor_weight,
                        color: isScale || hasBroadcast ? Colors.greenAccent : Colors.white38,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isScale || hasBroadcast ? Colors.greenAccent : null,
                        ),
                      ),
                      subtitle: Text(
                        '${r.device.remoteId}  •  ${r.rssi} dBm'
                        '${hasBroadcast ? "  • broadcast ativo" : ""}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: (isScale || hasBroadcast)
                          ? Chip(
                              label: Text(hasBroadcast ? 'BROADCAST' : 'BALANÇA'),
                              backgroundColor:
                                  hasBroadcast ? Colors.teal : Colors.green,
                            )
                          : null,
                      onTap: () => _connect(r.device),
                    );
                  },
                ),
              ),
          ],

          // ── Log ──
          Expanded(
            child: Container(
              color: Colors.black87,
              child: _log.isEmpty
                  ? const Center(
                      child: Text('Log aparece aqui...', style: TextStyle(color: Colors.white38)),
                    )
                  : ListView.builder(
                      itemCount: _log.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        child: Text(
                          _log[i].msg,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: _log[i].color,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  final BroadcastMeasurement m;
  const _BroadcastCard({required this.m});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: m.isStable ? const Color(0xFF1B3A2F) : const Color(0xFF2A2A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: m.isStable ? Colors.greenAccent : Colors.yellow,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.monitor_weight_outlined,
            size: 40,
            color: m.isStable ? Colors.greenAccent : Colors.yellow,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${m.weightDisplay} kg',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: m.isStable ? Colors.greenAccent : Colors.yellow,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text(
                        m.isStable ? 'ESTÁVEL' : 'MEDINDO...',
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: m.isStable ? Colors.green : Colors.orange,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (m.impedanceOhm != null)
                  Text(
                    'Impedância: ${m.impedanceOhm!.toStringAsFixed(1)} Ω',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                Text(
                  '${m.deviceId}  •  ${m.rssi} dBm',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String msg;
  final Color color;
  _LogEntry(this.msg, this.color);
}
