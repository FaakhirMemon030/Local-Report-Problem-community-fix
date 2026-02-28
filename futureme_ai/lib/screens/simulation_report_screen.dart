import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/simulation_model.dart';
import '../utils/app_theme.dart';

class SimulationReportScreen extends StatelessWidget {
  final FutureSimulationModel simulation;

  const SimulationReportScreen({super.key, required this.simulation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROJECTION REPORT'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSimulationHeader(context),
            const SizedBox(height: 32),
            _buildReportCard(context, 'CAREER', simulation.careerPrediction, Icons.work_outline, AppTheme.primaryNeon),
            const SizedBox(height: 20),
            _buildReportCard(context, 'HEALTH', simulation.healthPrediction, Icons.favorite_border, Colors.greenAccent),
            const SizedBox(height: 20),
            _buildReportCard(context, 'WEALTH', simulation.wealthPrediction, Icons.account_balance_wallet_outlined, Colors.amberAccent),
            const SizedBox(height: 32),
            if (simulation.riskWarnings.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('CRITICAL RISK WARNINGS', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 12),
              ...simulation.riskWarnings.map((w) => _buildRiskItem(w)),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryNeon),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('BACK TO COMMAND CENTER', style: TextStyle(color: AppTheme.primaryNeon)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primaryNeon.withValues(alpha: 0.1),
          child: const Icon(Icons.auto_awesome, color: AppTheme.primaryNeon, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          '5-YEAR FUTURE SNAPSHOT',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: 4),
        Text('TIMELINE: ${simulation.timelineType.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String content, IconData icon, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.01)]),
      borderGradient: LinearGradient(colors: [color.withValues(alpha: 0.3), Colors.transparent]),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskItem(String warning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(warning, style: const TextStyle(color: Colors.white60, fontSize: 13))),
        ],
      ),
    );
  }
}
