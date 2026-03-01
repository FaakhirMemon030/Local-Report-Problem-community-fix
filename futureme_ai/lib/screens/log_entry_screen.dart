import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_log_model.dart';
import '../providers/user_provider.dart';
import '../providers/simulation_provider.dart';
import '../utils/app_theme.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  double _codingHours = 0;
  double _workoutMinutes = 0;
  double _learningTime = 0;
  double _wastedTime = 0;
  String _mood = 'Neutral';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final simProvider = Provider.of<SimulationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY LOG ENTRY'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSliderSection('Coding Hours', _codingHours, 0, 16, (val) => setState(() => _codingHours = val)),
              _buildSliderSection('Workout Minutes', _workoutMinutes, 0, 180, (val) => setState(() => _workoutMinutes = val)),
              _buildSliderSection('Learning Time (Hrs)', _learningTime, 0, 8, (val) => setState(() => _learningTime = val)),
              _buildSliderSection('Wasted Time (Hrs)', _wastedTime, 0, 12, (val) => setState(() => _wastedTime = val)),
              const SizedBox(height: 24),
              const Text('Current Mood', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: ['Productive', 'Neutral', 'Stressed', 'Energetic'].map((m) {
                  bool isSelected = _mood == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _mood = m),
                    selectedColor: AppTheme.primaryNeon,
                    labelStyle: TextStyle(color: isSelected ? AppTheme.backgroundDark : Colors.white),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: AppTheme.backgroundDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final newLog = DailyLogModel(
                        logId: const Uuid().v4(),
                        userId: userProvider.userModel!.userId,
                        date: DateTime.now(),
                        codingHours: _codingHours,
                        workoutMinutes: _workoutMinutes,
                        learningTime: _learningTime,
                        wastedTime: _wastedTime,
                        mood: _mood,
                        productivityScore: (_codingHours * 2 + _learningTime * 1.5) / 3, // Simple mock score
                      );
                      await simProvider.addLog(newLog);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('SUBMIT DATA LOG', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value.toStringAsFixed(1), style: const TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt() * 2,
          activeColor: AppTheme.primaryNeon,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
