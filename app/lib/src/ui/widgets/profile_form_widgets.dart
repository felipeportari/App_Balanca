import 'package:flutter/material.dart';
import '../../models/user_profile.dart';

class FormSectionLabel extends StatelessWidget {
  final String text;
  const FormSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, color: Colors.white54, letterSpacing: 0.8),
      );
}

class FormGenderCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const FormGenderCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected
                ? Colors.tealAccent.withValues(alpha: 0.15)
                : const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.tealAccent : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 28,
                  color: selected ? Colors.tealAccent : Colors.white38),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.tealAccent : Colors.white54,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormGenderPicker extends StatelessWidget {
  final Gender value;
  final ValueChanged<Gender> onChanged;
  const FormGenderPicker(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FormGenderCard(
          label: 'Masculino',
          icon: Icons.male,
          selected: value == Gender.male,
          onTap: () => onChanged(Gender.male),
        ),
        const SizedBox(width: 12),
        FormGenderCard(
          label: 'Feminino',
          icon: Icons.female,
          selected: value == Gender.female,
          onTap: () => onChanged(Gender.female),
        ),
      ],
    );
  }
}

class FormStepper extends StatelessWidget {
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const FormStepper({
    super.key,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white54),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: Colors.white)),
                const SizedBox(width: 6),
                Text(unit,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white38)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white54),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
