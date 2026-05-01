import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balança')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monitor_weight_outlined, size: 80),
            const SizedBox(height: 24),
            const Text('Nenhuma medição ainda', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Conectar balança'),
            ),
          ],
        ),
      ),
    );
  }
}
