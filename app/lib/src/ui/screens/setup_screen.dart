import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/database_service.dart';
import '../widgets/profile_form_widgets.dart';

class SetupScreen extends StatefulWidget {
  final ValueChanged<UserProfile> onSaved;
  const SetupScreen({super.key, required this.onSaved});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  Gender _gender = Gender.male;
  int _age = 25;
  int _height = 170;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = UserProfile(
      heightCm: _height,
      ageYears: _age,
      gender: _gender,
    );
    await DatabaseService.saveProfile(profile);
    widget.onSaved(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Vamos nos\nconhecer',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esses dados são usados para calcular\na composição corporal.',
                style: TextStyle(fontSize: 14, color: Colors.white38),
              ),
              const SizedBox(height: 40),

              FormSectionLabel('Sexo biológico'),
              const SizedBox(height: 10),
              FormGenderPicker(
                value: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 32),

              FormSectionLabel('Idade'),
              const SizedBox(height: 10),
              FormStepper(
                value: _age,
                unit: 'anos',
                min: 10,
                max: 99,
                onChanged: (v) => setState(() => _age = v),
              ),
              const SizedBox(height: 32),

              FormSectionLabel('Altura'),
              const SizedBox(height: 10),
              FormStepper(
                value: _height,
                unit: 'cm',
                min: 100,
                max: 220,
                onChanged: (v) => setState(() => _height = v),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Começar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
