import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../widgets/profile_form_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onSaved;
  const ProfileScreen(
      {super.key, required this.profile, required this.onSaved});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late Gender _gender;
  late int _age;
  late int _height;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _gender = widget.profile.gender;
    _age = widget.profile.ageYears;
    _height = widget.profile.heightCm;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = UserProfile(
      heightCm: _height,
      ageYears: _age,
      gender: _gender,
      targetWeightKg: widget.profile.targetWeightKg,
    );
    await DatabaseService.saveProfile(updated);
    widget.onSaved(updated);
    setState(() {
      _editing = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Editar',
                  style: TextStyle(color: Colors.tealAccent)),
            )
          else ...[
            TextButton(
              onPressed: () => setState(() {
                _editing = false;
                _reset();
              }),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Salvar',
                  style: TextStyle(color: Colors.tealAccent)),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: _editing ? _buildEditForm() : _buildViewForm(),
      ),
    );
  }

  Widget _buildViewForm() {
    final p = widget.profile;
    return _InfoCard(
      children: [
        _InfoRow(
          icon: p.gender == Gender.male ? Icons.male : Icons.female,
          label: 'Sexo',
          value: p.gender == Gender.male ? 'Masculino' : 'Feminino',
        ),
        const Divider(color: Colors.white10, height: 1),
        _InfoRow(
          icon: Icons.cake_outlined,
          label: 'Idade',
          value: '${p.ageYears} anos',
        ),
        const Divider(color: Colors.white10, height: 1),
        _InfoRow(
          icon: Icons.height,
          label: 'Altura',
          value: '${p.heightCm} cm',
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionLabel('Sexo biológico'),
        const SizedBox(height: 10),
        FormGenderPicker(
          value: _gender,
          onChanged: (v) => setState(() => _gender = v),
        ),
        const SizedBox(height: 28),
        FormSectionLabel('Idade'),
        const SizedBox(height: 10),
        FormStepper(
          value: _age,
          unit: 'anos',
          min: 10,
          max: 99,
          onChanged: (v) => setState(() => _age = v),
        ),
        const SizedBox(height: 28),
        FormSectionLabel('Altura'),
        const SizedBox(height: 10),
        FormStepper(
          value: _height,
          unit: 'cm',
          min: 100,
          max: 220,
          onChanged: (v) => setState(() => _height = v),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white38),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.white54)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
