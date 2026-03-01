import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/assignment_model.dart';
import '../../providers/worker_provider.dart';
import 'worker_login_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final worker = Provider.of<WorkerProvider>(context).workerModel;
    if (worker == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MY JOBS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16, color: Colors.white)),
            Text(worker.city, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ],
        ),
        actions: [
          _CategoryBadge(worker.category.name),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          ),
        ],
      ),
      body: StreamBuilder<List<AssignmentModel>>(
        stream: Provider.of<WorkerProvider>(context).myAssignments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStats(assignments),
              const SizedBox(height: 24),
              ...assignments.map((a) => _AssignmentCard(assignment: a)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.work_off_rounded, color: Color(0xFF10B981), size: 56),
        ),
        const SizedBox(height: 24),
        const Text('No Jobs Assigned Yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          'An admin will assign jobs to you\nbased on your category and location.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.4), height: 1.6),
        ),
      ],
    ),
  );

  Widget _buildStats(List<AssignmentModel> assignments) {
    final done = assignments.where((a) => a.status == AssignmentStatus.done).length;
    final pending = assignments.where((a) => a.status != AssignmentStatus.done).length;
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'ASSIGNED', value: assignments.length.toString(), color: const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'PENDING', value: pending.toString(), color: Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'COMPLETED', value: done.toString(), color: const Color(0xFF10B981))),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<WorkerProvider>(context, listen: false).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WorkerLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(80, 36)),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    ),
  );
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge(this.category);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF10B981).withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
    ),
    child: Text(
      category.toUpperCase(),
      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    ),
  );
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final isDone = assignment.status == AssignmentStatus.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDone 
            ? const Color(0xFF10B981).withOpacity(0.2) 
            : Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header
          if (assignment.problemImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                assignment.problemImageUrl,
                height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100, color: Colors.white.withOpacity(0.03),
                  child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Category
                Row(
                  children: [
                    _chip(assignment.problemCategory.toUpperCase(), const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _chip(assignment.status.name.toUpperCase(),
                        isDone ? const Color(0xFF10B981) : Colors.orange),
                    const Spacer(),
                    if (isDone) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(assignment.problemTitle, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Expanded(child: Text('${assignment.problemAddress}, ${assignment.problemCity}',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13))),
                  ],
                ),
                if (isDone && assignment.workerNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(assignment.workerNotes, style: const TextStyle(color: Color(0xFF10B981), fontSize: 13))),
                      ],
                    ),
                  ),
                ],
                if (!isDone) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _markDoneDialog(context, assignment.assignmentId),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('MARK AS DONE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  void _markDoneDialog(BuildContext context, String assignmentId) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 12),
            Text('Mark as Done', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add any notes about the completed work:', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Fixed the broken pipe, replaced valves...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<WorkerProvider>(context, listen: false);
              await provider.markAssignmentDone(assignmentId, notesCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size(80, 36)),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}
