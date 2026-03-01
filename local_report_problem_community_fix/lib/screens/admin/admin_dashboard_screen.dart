import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../../providers/problem_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/problem_model.dart';
import '../../models/user_model.dart';
import '../../models/worker_model.dart';
import '../../models/assignment_model.dart';
import '../../services/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';


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
    _tabController = TabController(length: 5, vsync: this);
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
            Tab(text: 'ASSIGNMENTS'),
            Tab(text: 'USERS'),
            Tab(text: 'WORKERS'),
          ],

        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OverviewTab(),
          const _ModerationTab(),
          const _AssignmentsTab(),
          const _UsersTab(),
          const _WorkersTab(),
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
          const SizedBox(height: 12),
          // Assign to worker
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => _showAssignWorkerSheet(context, problem, fs, auth),
              icon: const Icon(Icons.engineering_rounded, size: 16),
              label: const Text('ASSIGN TO WORKER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                foregroundColor: const Color(0xFF10B981),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(80, 36),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showAssignWorkerSheet(BuildContext context, ProblemModel problem, FirestoreService fs, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.engineering_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ASSIGN: ${problem.title}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select an approved worker to handle this problem:',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<WorkerModel>>(
                stream: fs.getAllWorkers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                  
                  // Helper to map problem category to worker category
                  bool isMatchingCategory(WorkerModel worker, String probCat) {
                    return worker.category.name.toLowerCase() == probCat.toLowerCase();
                  }

                  final workers = (snapshot.data ?? [])
                      .where((w) => w.status == WorkerStatus.approved && !w.isBanned)
                      .where((w) => isMatchingCategory(w, problem.category))
                      .toList();

                  if (workers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.engineering_rounded, color: Colors.white10, size: 48),
                          const SizedBox(height: 12),
                          Text('No matching ${problem.category.toUpperCase()} workers available', 
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: workers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final worker = workers[i];
                      return GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          if (auth.currentUserId == null) return;
                          try {
                            final assignment = AssignmentModel(
                              assignmentId: const Uuid().v4(),
                              problemId: problem.problemId,
                              problemTitle: problem.title,
                              problemCategory: problem.category,
                              problemCity: problem.city,
                              problemAddress: problem.address,
                              problemImageUrl: problem.imageUrl,
                              workerId: worker.workerId,
                              workerName: worker.name,
                              assignedBy: auth.currentUserId!,
                              assignedAt: DateTime.now(),
                            );
                            await fs.assignProblemToWorker(assignment);
                            // Update problem status to inProgress
                            await fs.updateProblemStatus(problem.problemId, ProblemStatus.inProgress, auth.currentUserId!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Assigned to ${worker.name}!'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                                child: Icon(_workerCatIcon(worker.category), color: const Color(0xFF10B981), size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(worker.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('${worker.category.name.toUpperCase()} • ${worker.city} • ${worker.jobsDone} jobs done',
                                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _workerCatIcon(WorkerCategory cat) {
    switch (cat) {
      case WorkerCategory.road: return Icons.construction_rounded;
      case WorkerCategory.garbage: return Icons.delete_sweep_rounded;
      case WorkerCategory.water: return Icons.water_drop_rounded;
      case WorkerCategory.electricity: return Icons.bolt_rounded;
      case WorkerCategory.drainage: return Icons.waves_rounded;
      case WorkerCategory.other: return Icons.engineering_rounded;
      case WorkerCategory.election: return Icons.how_to_vote_rounded;
    }
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
              CircleAvatar(
                backgroundColor: const Color(0xFF0F172A), 
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _UserStat(label: 'REPORTS', value: user.totalReports.toString()),
              _UserStat(label: 'COINS', value: user.reputationScore.toString()),
              if (user.role != 'admin')
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: () => authProvider.toggleUserBan(user.userId, !user.isBanned),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isBanned ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      foregroundColor: user.isBanned ? Colors.green : Colors.red,
                      elevation: 0,
                      minimumSize: const Size(60, 34),
                      maximumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(user.isBanned ? 'UNBAN' : 'BAN', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(80, 36),
            ),
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
            Text('${(user.name.isEmpty ? "USER" : user.name).toUpperCase()}\'S REPORTS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
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

// ─────────────────────────────────────────────────────────
// WORKERS TAB
// ─────────────────────────────────────────────────────────
class _WorkersTab extends StatefulWidget {
  const _WorkersTab();

  @override
  State<_WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<_WorkersTab> with SingleTickerProviderStateMixin {
  late TabController _subTab;

  @override
  void initState() {
    super.initState();
    _subTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF1E293B),
          child: TabBar(
            controller: _subTab,
            indicatorColor: const Color(0xFF10B981),
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
            tabs: const [Tab(text: 'PENDING APPROVALS'), Tab(text: 'APPROVED WORKERS')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTab,
            children: [
              _WorkerList(filter: WorkerStatus.pending),
              _WorkerList(filter: WorkerStatus.approved),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkerList extends StatelessWidget {
  final WorkerStatus filter;
  const _WorkerList({required this.filter});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return StreamBuilder<List<WorkerModel>>(
      stream: fs.getAllWorkers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
        final workers = (snapshot.data ?? []).where((w) => w.status == filter && !w.isBanned).toList();

        if (workers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(filter == WorkerStatus.pending ? Icons.hourglass_empty_rounded : Icons.engineering_rounded,
                    color: Colors.white12, size: 56),
                const SizedBox(height: 16),
                Text(
                  filter == WorkerStatus.pending ? 'No Pending Approvals' : 'No Approved Workers',
                  style: const TextStyle(color: Colors.white30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          itemBuilder: (_, i) => _WorkerCard(worker: workers[i], auth: auth, fs: fs),
        );
      },
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final AuthProvider auth;
  final FirestoreService fs;
  const _WorkerCard({required this.worker, required this.auth, required this.fs});

  IconData _catIcon(WorkerCategory cat) {
    switch (cat) {
      case WorkerCategory.road: return Icons.construction_rounded;
      case WorkerCategory.garbage: return Icons.delete_sweep_rounded;
      case WorkerCategory.water: return Icons.water_drop_rounded;
      case WorkerCategory.electricity: return Icons.bolt_rounded;
      case WorkerCategory.drainage: return Icons.waves_rounded;
      case WorkerCategory.other: return Icons.engineering_rounded;
      case WorkerCategory.election: return Icons.how_to_vote_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = worker.status == WorkerStatus.pending;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(0.2)
              : const Color(0xFF10B981).withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                child: Icon(_catIcon(worker.category), color: const Color(0xFF10B981)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.name.isNotEmpty ? worker.name : 'No Name',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(worker.email, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_catIcon(worker.category), color: const Color(0xFF10B981), size: 12),
                  const SizedBox(width: 4),
                  Text(worker.category.name.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _detail(Icons.phone_outlined, worker.phone),
              _detail(Icons.credit_card_outlined, worker.cnic),
              _detail(Icons.location_city_outlined, worker.city),
              _detail(Icons.work_rounded, '${worker.jobsDone} jobs done'),
            ],
          ),
          const SizedBox(height: 10),
          // Documents button
          GestureDetector(
            onTap: () => _showWorkerDocuments(context, worker),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open_rounded, size: 14, color: Color(0xFF60A5FA)),
                  const SizedBox(width: 6),
                  Text(
                    'VIEW DOCUMENTS',
                    style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  _docBadge(worker),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Actions
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (auth.currentUserId != null) {
                          await fs.updateWorkerStatus(worker.workerId, WorkerStatus.approved, auth.currentUserId!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${worker.name} approved!'), backgroundColor: const Color(0xFF10B981)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('APPROVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                        foregroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (auth.currentUserId != null) {
                          await fs.updateWorkerStatus(worker.workerId, WorkerStatus.rejected, auth.currentUserId!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${worker.name} rejected.'), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('REJECT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () async {
                        await fs.updateWorkerBanStatus(worker.workerId, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        foregroundColor: Colors.orange,
                        elevation: 0,
                        minimumSize: const Size(60, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('BAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (auth.currentUserId != null) {
                          await fs.deleteWorker(worker.workerId, auth.currentUserId!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        minimumSize: const Size(60, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('KICK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.white24),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
    ],
  );

  Widget _docBadge(WorkerModel w) {
    final count = [
      w.cnicPicUrl,
      w.electricityBillUrl,
      w.gasBillUrl,
      w.profilePicUrl,
    ].where((u) => u.isNotEmpty).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: count > 0 ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$count/4',
          style: TextStyle(
              color: count > 0 ? const Color(0xFF10B981) : Colors.white30,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  void _showWorkerDocuments(BuildContext context, WorkerModel worker) {
    final docs = [
      {'label': 'Profile Photo', 'url': worker.profilePicUrl, 'icon': Icons.photo_camera_outlined},
      {'label': 'CNIC Photo', 'url': worker.cnicPicUrl, 'icon': Icons.credit_card_outlined},
      {'label': 'Electricity Bill', 'url': worker.electricityBillUrl, 'icon': Icons.bolt_outlined},
      {'label': 'Gas Bill', 'url': worker.gasBillUrl, 'icon': Icons.local_fire_department_outlined},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.folder_open_rounded, color: Color(0xFF60A5FA), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${worker.name.toUpperCase()} — DOCUMENTS',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                          letterSpacing: 1, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final url = doc['url'] as String;
                  final icon = doc['icon'] as IconData;
                  final label = doc['label'] as String;
                  final hasDoc = url.isNotEmpty;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: hasDoc
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 16,
                                  color: hasDoc
                                      ? const Color(0xFF10B981)
                                      : Colors.white30),
                              const SizedBox(width: 8),
                              Text(label,
                                  style: TextStyle(
                                      color: hasDoc ? Colors.white : Colors.white30,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: hasDoc
                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hasDoc ? 'UPLOADED' : 'MISSING',
                                  style: TextStyle(
                                      color: hasDoc
                                          ? const Color(0xFF10B981)
                                          : Colors.orange,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasDoc)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16)),
                            child: Image.network(
                              url,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                          height: 200,
                                          color: Colors.white.withOpacity(0.03),
                                          child: const Center(
                                              child: CircularProgressIndicator(
                                                  color: Color(0xFF10B981),
                                                  strokeWidth: 2))),
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                color: Colors.white.withOpacity(0.03),
                                child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.white24)),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 60,
                            decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(16))),
                            child: const Center(
                              child: Text('No document uploaded',
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab();

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return StreamBuilder<List<AssignmentModel>>(
      stream: fs.getAllAssignments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        final assignments = snapshot.data ?? [];
        if (assignments.isEmpty) {
          return const Center(child: Text('No assignments yet', style: TextStyle(color: Colors.white24)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: assignments.length,
          itemBuilder: (context, index) => _AssignmentModerationCard(assignment: assignments[index]),
        );
      },
    );
  }
}

class _AssignmentModerationCard extends StatelessWidget {
  final AssignmentModel assignment;
  const _AssignmentModerationCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDone = assignment.status == AssignmentStatus.done;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDone ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDone ? const Color(0xFF10B981) : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  assignment.status.name.toUpperCase(),
                  style: TextStyle(
                    color: isDone ? const Color(0xFF10B981) : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(assignment.assignedAt),
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(assignment.problemTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Worker: ${assignment.workerName}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 16),
          
          if (isDone && assignment.completionImageUrl.isNotEmpty) ...[
            const Text('COMPLETION PHOTO:', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                assignment.completionImageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            if (assignment.workerNotes.isNotEmpty) ...[
              Text('Worker Notes:', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
              Text(assignment.workerNotes, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: const Text('Update Problem Image?', style: TextStyle(color: Colors.white)),
                      content: const Text('This will replace the original user photo with this worker completion photo.', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          child: const Text('REPLACE'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && auth.currentUserId != null) {
                    await fs.updateProblemImage(assignment.problemId, assignment.completionImageUrl);
                    // Also mark problem as solved if not already
                    await fs.updateProblemStatus(assignment.problemId, ProblemStatus.solved, auth.currentUserId!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Problem image updated and status marked as SOLVED!'), backgroundColor: Color(0xFF10B981))
                      );
                    }
                  }
                },
                icon: const Icon(Icons.published_with_changes_rounded),
                label: const Text('PUBLISH AS SOLUTION IMAGE', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else if (isDone) ...[
             const Text('Waiting for completion details...', style: TextStyle(color: Colors.white24, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
