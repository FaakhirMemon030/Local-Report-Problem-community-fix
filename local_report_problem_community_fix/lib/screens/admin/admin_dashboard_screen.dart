import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../../providers/problem_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/problem_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ADMIN CONSOLE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white24,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'MODERATION'),
            Tab(text: 'USERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OverviewTab(),
          const _ModerationTab(),
          const _UsersTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final problemProvider = Provider.of<ProblemProvider>(context);
    final total = problemProvider.problems.length;
    final pending = problemProvider.problems.where((p) => p.status == ProblemStatus.pending).length;
    final inProgress = problemProvider.problems.where((p) => p.status == ProblemStatus.inProgress).length;
    final solved = problemProvider.problems.where((p) => p.status == ProblemStatus.solved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatCard(title: 'TOTAL', value: total.toString(), color: const Color(0xFF3B82F6), icon: Icons.analytics_rounded),
              const SizedBox(width: 8),
              _StatCard(title: 'PENDING', value: pending.toString(), color: Colors.orange, icon: Icons.pending_actions_rounded),
              const SizedBox(width: 8),
              _StatCard(title: 'FIXING', value: inProgress.toString(), color: Colors.cyan, icon: Icons.handyman_rounded),
              const SizedBox(width: 8),
              _StatCard(title: 'SOLVED', value: solved.toString(), color: const Color(0xFF10B981), icon: Icons.task_alt_rounded),
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
            ),
            child: _CategoryChart(problems: problemProvider.problems),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12)),
      ],
    );
  }
}

class _ModerationTab extends StatelessWidget {
  const _ModerationTab();

  @override
  Widget build(BuildContext context) {
    final problemProvider = Provider.of<ProblemProvider>(context);
    final problems = problemProvider.problems;

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: problems.length,
      itemBuilder: (context, index) => _ProblemModerationCard(problem: problems[index]),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return StreamBuilder<List<UserModel>>(
      stream: authProvider.allUsers,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        final users = snapshot.data ?? [];
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) => _UserCard(user: users[index]),
        );
      },
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
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
    for (var p in problems) counts[p.category] = (counts[p.category] ?? 0) + 1;
    if (counts.isEmpty) return const Center(child: Text('NO DATA', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)));

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
      default: return const Color(0xFF8B5CF6);
    }
  }
}

class _Badge extends StatelessWidget {
  final String category;
  final Color color;
  const _Badge(this.category, {required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(category.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
  );
}

class _ProblemModerationCard extends StatelessWidget {
  final ProblemModel problem;
  const _ProblemModerationCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(problem.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 50, height: 50, color: Colors.black12, child: const Icon(Icons.broken_image, size: 20))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(problem.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(problem.category.toUpperCase(), style: TextStyle(color: const Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ),
              _buildStatusBadge(problem.status),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDeleteProblem(context, problem.problemId),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('SET STATUS: ', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ProblemStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(status.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        backgroundColor: problem.status == status ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.05),
                        onPressed: () {
                          if (auth.currentUserId != null) {
                            fs.updateProblemStatus(problem.problemId, status, auth.currentUserId!);
                          }
                        },
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProblem(BuildContext context, String problemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Post?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this report?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final pp = Provider.of<ProblemProvider>(context, listen: false);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.currentUserId != null) {
                await pp.deleteProblem(problemId, auth.currentUserId!);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ProblemStatus status) {
    Color color = Colors.grey;
    if (status == ProblemStatus.approved) color = Colors.green;
    if (status == ProblemStatus.pending) color = Colors.orange;
    if (status == ProblemStatus.solved) color = Colors.cyan;
    if (status == ProblemStatus.rejected) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: user.isBanned ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: const Color(0xFF0F172A), child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                  ],
                ),
              ),
              if (user.role == 'admin')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ADMIN', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _UserStat(label: 'REPORTS', value: user.totalReports.toString()),
              _UserStat(label: 'COINS', value: user.reputationScore.toString()),
              if (user.role != 'admin')
                ElevatedButton(
                  onPressed: () => authProvider.toggleUserBan(user.userId, !user.isBanned),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isBanned ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    foregroundColor: user.isBanned ? Colors.green : Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(user.isBanned ? 'UNBAN' : 'BAN'),
                ),
              IconButton(
                onPressed: () => _showUserPosts(context, user),
                icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF60A5FA), size: 18),
              ),
              IconButton(
                onPressed: () => _confirmKickUser(context, user),
                icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 18),
                style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.05)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmKickUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Kick ${user.name}?', style: const TextStyle(color: Colors.white)),
        content: const Text('This will delete the user account from the system. Continue?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).adminDeleteUser(user.userId);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('KICK'),
          ),
        ],
      ),
    );
  }

  void _showUserPosts(BuildContext context, UserModel user) {
    final problemProvider = Provider.of<ProblemProvider>(context, listen: false);
    final userProblems = problemProvider.problems.where((p) => p.reportedBy == user.userId).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('${user.name.toUpperCase()}\'S REPORTS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
            const SizedBox(height: 24),
            Expanded(
              child: userProblems.isEmpty 
                ? const Center(child: Text('NO REPORTS FOUND', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.bold)))
                : ListView.builder(
                    itemCount: userProblems.length,
                    itemBuilder: (context, index) {
                      final p = userProblems[index];
                      return ListTile(
                        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image))),
                        title: Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(p.status.name.toUpperCase(), style: TextStyle(color: const Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          onPressed: () async {
                            final pp = Provider.of<ProblemProvider>(context, listen: false);
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.currentUserId != null) {
                              await pp.deleteProblem(p.problemId, auth.currentUserId!);
                            }
                            if (context.mounted) Navigator.pop(context); // Close sheet
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStat extends StatelessWidget {
  final String label;
  final String value;
  const _UserStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ],
  );
}
