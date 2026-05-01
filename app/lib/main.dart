import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: BalancaApp()));
}

class BalancaApp extends StatelessWidget {
  const BalancaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Balança',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
