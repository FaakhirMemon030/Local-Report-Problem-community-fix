import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/problem_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/problem_model.dart';
import '../../services/firestore_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final problemProvider = Provider.of<ProblemProvider>(context);

    // Calculate stats
    final total = problemProvider.problems.length;
    final pending = problemProvider.problems.where((p) => p.status == ProblemStatus.pending).length;
    final resolved = problemProvider.problems.where((p) => p.status == ProblemStatus.resolved).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Moderation Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatCard(title: 'Total', value: total.toString(), color: Colors.blue),
                const SizedBox(width: 16),
                _StatCard(title: 'Pending', value: pending.toString(), color: Colors.orange),
                const SizedBox(width: 16),
                _StatCard(title: 'Resolved', value: resolved.toString(), color: Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Reports by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _CategoryChart(problems: problemProvider.problems),
            ),
            const SizedBox(height: 32),
            const Text('Pending Moderation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: problemProvider.problems.where((p) => p.status == ProblemStatus.pending).length,
              itemBuilder: (context, index) {
                final pendingProblems = problemProvider.problems.where((p) => p.status == ProblemStatus.pending).toList();
                final problem = pendingProblems[index];
                return _ModerationCard(problem: problem);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<ProblemModel> problems;
  const _CategoryChart({required this.problems});

  @override
  Widget build(BuildContext context) {
    Map<String, int> counts = {};
    for (var p in problems) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }

    if (counts.isEmpty) return const Center(child: Text('No data'));

    return PieChart(
      PieChartData(
        sections: counts.entries.map((e) {
          final color = _getCategoryColor(e.key);
          return PieChartSectionData(
            color: color,
            value: e.value.toDouble(),
            title: '${e.value}',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          );
        }).toList(),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'road': return Colors.grey;
      case 'garbage': return Colors.brown;
      case 'water': return Colors.blue;
      case 'electricity': return Colors.amber;
      case 'drainage': return Colors.teal;
      default: return Colors.deepPurple;
    }
  }
}

class _ModerationCard extends StatelessWidget {
  final ProblemModel problem;
  const _ModerationCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(problem.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.error)),
        ),
        title: Text(problem.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(problem.category.toUpperCase(), style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => fs.updateProblemStatus(problem.problemId, ProblemStatus.approved, auth.currentUserId!),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => fs.updateProblemStatus(problem.problemId, ProblemStatus.rejected, auth.currentUserId!),
            ),
          ],
        ),
      ),
    );
  }
}
