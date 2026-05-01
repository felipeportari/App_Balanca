import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/weight_measurement.dart';
import '../../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WeightMeasurement> _measurements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.getAll();
    setState(() {
      _measurements = data;
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    await DatabaseService.delete(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Histórico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _measurements.isEmpty
              ? _EmptyView()
              : _ContentView(
                  measurements: _measurements,
                  onDelete: _delete,
                ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.white12),
          SizedBox(height: 16),
          Text('Sem medições ainda',
              style: TextStyle(fontSize: 18, color: Colors.white38)),
          SizedBox(height: 8),
          Text('Salve uma medição na aba Peso',
              style: TextStyle(fontSize: 13, color: Colors.white24)),
        ],
      ),
    );
  }
}

// ── Content ─────────────────────────────────────────────────────────────────

class _ContentView extends StatelessWidget {
  final List<WeightMeasurement> measurements;
  final Future<void> Function(int id) onDelete;
  const _ContentView(
      {required this.measurements, required this.onDelete});

  List<WeightMeasurement> get _ascending =>
      measurements.reversed.toList();

  @override
  Widget build(BuildContext context) {
    final asc = _ascending;
    final minW = asc.map((m) => m.weightKg).reduce((a, b) => a < b ? a : b);
    final maxW = asc.map((m) => m.weightKg).reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).clamp(2.0, double.infinity);

    return Column(
      children: [
        // Chart
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
          child: SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minW - range * 0.2,
                maxY: maxW + range * 0.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white38),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (asc.length / 4).ceilToDouble().clamp(1, double.infinity),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= asc.length) return const SizedBox();
                        return Text(
                          DateFormat('dd/MM').format(asc[i].timestamp),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white38),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      asc.length,
                      (i) => FlSpot(i.toDouble(), asc[i].weightKg),
                    ),
                    isCurved: true,
                    color: Colors.tealAccent,
                    barWidth: 2,
                    dotData: FlDotData(show: asc.length <= 20),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.tealAccent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _StatChip(
                  label: 'Medições', value: '${measurements.length}'),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Mín',
                  value: '${minW.toStringAsFixed(1)} kg'),
              const SizedBox(width: 8),
              _StatChip(
                  label: 'Máx',
                  value: '${maxW.toStringAsFixed(1)} kg'),
            ],
          ),
        ),
        const Divider(color: Colors.white12),

        // List
        Expanded(
          child: ListView.builder(
            itemCount: measurements.length,
            itemBuilder: (_, i) => _MeasurementTile(
              m: measurements[i],
              onDelete: measurements[i].id != null
                  ? () => onDelete(measurements[i].id!)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white38)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  final WeightMeasurement m;
  final VoidCallback? onDelete;
  const _MeasurementTile({required this.m, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy  HH:mm');
    final bc = m.bodyComposition;

    return Dismissible(
      key: ValueKey(m.id ?? m.timestamp.millisecondsSinceEpoch),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withValues(alpha: 0.8),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Apagar medição?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Apagar',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fmt.format(m.timestamp),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white38)),
                  const SizedBox(height: 2),
                  Text('${m.weightKg.toStringAsFixed(2)} kg',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  if (bc != null)
                    Text(
                      'Gordura ${bc.bodyFatPct.toStringAsFixed(1)}%  '
                      'Músculo ${bc.musclePct.toStringAsFixed(1)}%  '
                      'IMC ${bc.bmi.toStringAsFixed(1)}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }
}
