import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../ble/scale_broadcaster.dart';
import '../../models/user_profile.dart';
import '../../models/weight_measurement.dart';
import '../../services/body_composition_calculator.dart';
import '../../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  BroadcastMeasurement? _last;
  BroadcastMeasurement? _lastStable; // preserved even when scale sends non-stable packets after
  bool _scanning = false;
  bool _saved = false;
  StreamSubscription? _scanSub;
  StreamSubscription? _stateSub;
  Timer? _ageTimer;
  DateTime? _lastSeen;
  int _secondsAgo = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startScan();
    _ageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_lastSeen != null && mounted) {
        setState(() {
          _secondsAgo = DateTime.now().difference(_lastSeen!).inSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanSub?.cancel();
    _stateSub?.cancel();
    _ageTimer?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _startScan();
    if (state == AppLifecycleState.paused) {
      _scanSub?.cancel();
      _stateSub?.cancel();
      FlutterBluePlus.stopScan();
    }
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    _scanSub?.cancel();
    _stateSub?.cancel();
    setState(() => _scanning = true);

    await FlutterBluePlus.startScan(androidScanMode: AndroidScanMode.lowLatency);

    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final m = ScaleBroadcaster.parse(r);
        if (m != null) {
          setState(() {
            final prevStable = _lastStable;
            _last = m;
            _lastSeen = DateTime.now();
            _secondsAgo = 0;
            if (m.isStable) {
              final weightChanged = prevStable == null ||
                  (m.weightKg - prevStable.weightKg).abs() > 0.1;
              if (weightChanged) _saved = false;
              _lastStable = m;
            }
          });
        }
      }
    });

    _stateSub = FlutterBluePlus.isScanning.listen((active) {
      if (!active && mounted) {
        setState(() => _scanning = false);
        Future.delayed(const Duration(seconds: 2), _startScan);
      }
    });
  }

  BodyComposition? get _composition {
    final m = _lastStable ?? _last;
    if (m == null || m.impedanceOhm == null) return null;
    return BodyCompositionCalculator.calculate(
      weightKg: m.weightKg,
      impedanceOhm: m.impedanceOhm!.round(),
      profile: widget.profile,
    );
  }

  Future<void> _saveMeasurement() async {
    final m = _lastStable;
    if (m == null) return;
    final measurement = WeightMeasurement(
      timestamp: DateTime.now(),
      weightKg: m.weightKg,
      impedanceOhm: m.impedanceOhm?.round(),
      bodyComposition: _composition,
    );
    await DatabaseService.insert(measurement);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medição salva!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  bool get _canSave => _lastStable != null && !_saved;

  bool get _stale => _secondsAgo > 8;

  @override
  Widget build(BuildContext context) {
    final m = _last;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Peso'),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.tealAccent),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: m == null
          ? const _SearchingView()
          : _WeightView(
              m: m,
              composition: _composition,
              secondsAgo: _secondsAgo,
              stale: _stale,
            ),
      floatingActionButton: _canSave
          ? FloatingActionButton.extended(
              onPressed: _saveMeasurement,
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

// ── Searching ───────────────────────────────────────────────────────────────

class _SearchingView extends StatelessWidget {
  const _SearchingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_weight_outlined, size: 72, color: Colors.white12),
          SizedBox(height: 24),
          Text('Procurando balança...',
              style: TextStyle(fontSize: 18, color: Colors.white38)),
          SizedBox(height: 8),
          Text(
            'Suba na balança para ela começar a transmitir',
            style: TextStyle(fontSize: 13, color: Colors.white24),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Weight + Composition ────────────────────────────────────────────────────

class _WeightView extends StatelessWidget {
  final BroadcastMeasurement m;
  final BodyComposition? composition;
  final int secondsAgo;
  final bool stale;
  const _WeightView({
    required this.m,
    required this.composition,
    required this.secondsAgo,
    required this.stale,
  });

  @override
  Widget build(BuildContext context) {
    final color = stale
        ? Colors.white24
        : (m.isStable ? Colors.tealAccent : Colors.amber);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        children: [
          // Status chip
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                stale
                    ? 'ÚLTIMA MEDIÇÃO'
                    : (m.isStable ? 'ESTÁVEL' : 'MEDINDO...'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Big weight
          Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: m.weightDisplay,
                    style: TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w200,
                        color: color,
                        height: 1),
                  ),
                  TextSpan(
                    text: ' kg',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: color.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),

          if (stale) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                'última leitura: ${secondsAgo}s atrás',
                style: const TextStyle(fontSize: 11, color: Colors.white24),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Body composition grid
          if (composition != null) _CompositionGrid(c: composition!),

          const SizedBox(height: 16),

          // Impedance + RSSI
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (m.impedanceOhm != null) ...[
                _SmallInfo(
                    icon: Icons.electrical_services,
                    label:
                        '${m.impedanceOhm!.toStringAsFixed(0)} Ω'),
                const SizedBox(width: 16),
              ],
              _SmallInfo(
                  icon: Icons.bluetooth,
                  label: '${m.rssi} dBm'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SmallInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
      ],
    );
  }
}

// ── Composition grid ────────────────────────────────────────────────────────

class _CompositionGrid extends StatelessWidget {
  final BodyComposition c;
  const _CompositionGrid({required this.c});

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Composição corporal',
              style: TextStyle(fontSize: 13, color: Colors.white38)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _MetricCard(
              label: 'IMC',
              value: c.bmi.toStringAsFixed(1),
              sub: _bmiCategory(c.bmi),
              icon: Icons.straighten,
            ),
            _MetricCard(
              label: 'Gordura',
              value: '${c.bodyFatPct.toStringAsFixed(1)}%',
              sub: '',
              icon: Icons.water_drop_outlined,
            ),
            _MetricCard(
              label: 'Músculo',
              value: '${c.musclePct.toStringAsFixed(1)}%',
              sub: '',
              icon: Icons.fitness_center,
            ),
            _MetricCard(
              label: 'Água',
              value: '${c.waterPct.toStringAsFixed(1)}%',
              sub: '',
              icon: Icons.opacity,
            ),
            _MetricCard(
              label: 'Ósseo',
              value: '${c.boneKg.toStringAsFixed(1)} kg',
              sub: '',
              icon: Icons.accessibility_new,
            ),
            _MetricCard(
              label: 'TMB',
              value: '${c.bmr.toStringAsFixed(0)}',
              sub: 'kcal/dia',
              icon: Icons.local_fire_department_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.tealAccent.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white38)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
