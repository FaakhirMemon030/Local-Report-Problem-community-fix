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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ADMIN CONSOLE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.05),
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatCard(title: 'TOTAL', value: total.toString(), color: const Color(0xFF3B82F6), icon: Icons.analytics_rounded),
                    const SizedBox(width: 12),
                    _StatCard(title: 'PENDING', value: pending.toString(), color: Colors.orange, icon: Icons.pending_actions_rounded),
                    const SizedBox(width: 12),
                    _StatCard(title: 'RESOLVED', value: resolved.toString(), color: const Color(0xFF10B981), icon: Icons.task_alt_rounded),
                  ],
                ),
                const SizedBox(height: 40),
                
                _buildSectionHeader('REPORTS BY CATEGORY'),
                const SizedBox(height: 24),
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: _CategoryChart(problems: problemProvider.problems),
                ),
                const SizedBox(height: 40),
                
                _buildSectionHeader('PENDING MODERATION'),
                const SizedBox(height: 20),
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

    if (counts.isEmpty) return Center(child: Text('NO DATA AVAILABLE', style: TextStyle(color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.bold)));

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: counts.entries.map((e) {
          final color = _getCategoryColor(e.key);
          return PieChartSectionData(
            color: color,
            value: e.value.toDouble(),
            title: '${e.value}',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            badgeWidget: _Badge(e.key, color: color),
            badgePositionPercentageOffset: 1.3,
          );
        }).toList(),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'road': return const Color(0xFF64748B);
      case 'garbage': return const Color(0xFF92400E);
      case 'water': return const Color(0xFF3B82F6);
      case 'electricity': return const Color(0xFFF59E0B);
      case 'drainage': return const Color(0xFF14B8A6);
      default: return const Color(0xFF8B5CF6);
    }
  }
}

class _Badge extends StatelessWidget {
  final String category;
  final Color color;
  const _Badge(this.category, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(category.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  final ProblemModel problem;
  const _ModerationCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(problem.imageUrl, width: 64, height: 64, fit: BoxFit.cover, 
              errorBuilder: (_,__,___) => Container(width: 64, height: 64, color: const Color(0xFF0F172A), child: const Icon(Icons.broken_image_rounded, size: 20, color: Colors.white10))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(problem.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(problem.category.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                onPressed: () => fs.updateProblemStatus(problem.problemId, ProblemStatus.approved, auth.currentUserId!),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981).withOpacity(0.1), padding: const EdgeInsets.all(8)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                onPressed: () => fs.updateProblemStatus(problem.problemId, ProblemStatus.rejected, auth.currentUserId!),
                style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), padding: const EdgeInsets.all(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
