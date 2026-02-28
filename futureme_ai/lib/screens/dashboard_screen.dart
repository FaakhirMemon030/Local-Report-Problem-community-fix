import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../providers/user_provider.dart';
import '../providers/simulation_provider.dart';
import '../utils/app_theme.dart';
import '../admin/admin_dashboard_screen.dart';
import 'log_entry_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final simProvider = Provider.of<SimulationProvider>(context);

    if (userProvider.userModel == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: Text('COMMAND CENTER', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primaryNeon),
            onPressed: () => userProvider.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(context, userProvider.userModel!),
            if (userProvider.userModel?.role == 'admin') ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                ),
                child: Text('ACCESS ADMIN TERMINAL', style: TextStyle(color: AppTheme.secondaryNeon, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 24),
            _buildMetricsGrid(context, simProvider),
            const SizedBox(height: 24),
            _buildProjectionChart(context, simProvider),
            const SizedBox(height: 24),
            _buildRiskPanel(context, simProvider),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNeon,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LogEntryScreen()),
        ),
        label: const Text('LOG DAILY DATA', style: TextStyle(color: AppTheme.backgroundDark)),
        icon: const Icon(Icons.add, color: AppTheme.backgroundDark),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HELLO, ${user.name.toUpperCase()}', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text('Current Timeline: Balanced', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 12)),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, SimulationProvider sim) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.8,
      crossAxisSpacing: 12,
      children: [
        _buildMetricCard(context, 'CAREER', '82%', AppTheme.primaryNeon),
        _buildMetricCard(context, 'HEALTH', '75%', Colors.greenAccent),
        _buildMetricCard(context, 'WEALTH', '64%', Colors.amberAccent),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity,
      borderRadius: 15,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)]),
      borderGradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.1)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildProjectionChart(BuildContext context, SimulationProvider sim) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('5-YEAR CAREER PROJECTION', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(15),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    const FlSpot(0, 1),
                    const FlSpot(1, 1.5),
                    const FlSpot(2, 2.5),
                    const FlSpot(3, 4),
                    const FlSpot(4, 6),
                  ],
                  isCurved: true,
                  color: AppTheme.primaryNeon,
                  barWidth: 4,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryNeon.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskPanel(BuildContext context, SimulationProvider sim) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RISK ALERT PANEL', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14, color: Colors.redAccent)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(15),
            color: Colors.redAccent.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sedentary lifestyle detected! Your 5-year mobility score is dropping.',
                  style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.8), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
