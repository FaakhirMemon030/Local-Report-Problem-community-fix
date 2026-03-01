import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/assignment_model.dart';
import '../../providers/worker_provider.dart';
import '../../services/storage_service.dart';
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
            const Text('MY JOBS',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 16,
                    color: Colors.white)),
            Text(worker.city,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
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
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent)));
          }

          final assignments = snapshot.data ?? [];

          if (assignments.isEmpty) {
            return _buildEmptyState(worker.category.name);
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

  Widget _buildEmptyState(String category) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.work_off_rounded,
                  color: Color(0xFF10B981), size: 56),
            ),
            const SizedBox(height: 24),
            const Text('No Jobs Assigned Yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'An admin will assign ${category.toUpperCase()} jobs\nto you based on your location.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), height: 1.6),
            ),
          ],
        ),
      );

  Widget _buildStats(List<AssignmentModel> assignments) {
    final done =
        assignments.where((a) => a.status == AssignmentStatus.done).length;
    final pending =
        assignments.where((a) => a.status != AssignmentStatus.done).length;
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'ASSIGNED',
                value: assignments.length.toString(),
                color: const Color(0xFF3B82F6))),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'PENDING',
                value: pending.toString(),
                color: Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'COMPLETED',
                value: done.toString(),
                color: const Color(0xFF10B981))),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title:
            const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<WorkerProvider>(context, listen: false)
                  .signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const WorkerLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(80, 36)),
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
  const _StatCard(
      {required this.label, required this.value, required this.color});

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
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ],
        ),
      );
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge(this.category);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Text(
          category.toUpperCase(),
          style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// ASSIGNMENT CARD (StatefulWidget to manage image upload state)
// ─────────────────────────────────────────────────────────────
class _AssignmentCard extends StatefulWidget {
  final AssignmentModel assignment;
  const _AssignmentCard({required this.assignment});

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final isDone = assignment.status == AssignmentStatus.done;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDone
                ? const Color(0xFF10B981).withOpacity(0.2)
                : Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Before image (original problem photo)
          if (assignment.problemImageUrl.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    assignment.problemImageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: Colors.white.withOpacity(0.03),
                      child: const Center(
                          child: Icon(Icons.broken_image_rounded,
                              color: Colors.white24)),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('BEFORE',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status chips
                Row(
                  children: [
                    _chip(
                        assignment.problemCategory.toUpperCase(),
                        const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _chip(
                        assignment.status.name.toUpperCase(),
                        isDone
                            ? const Color(0xFF10B981)
                            : Colors.orange),
                    const Spacer(),
                    if (isDone)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(assignment.problemTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14,
                        color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(
                            '${assignment.problemAddress}, ${assignment.problemCity}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13))),
                  ],
                ),

                // Worker notes
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
                        const Icon(Icons.notes_rounded,
                            color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(assignment.workerNotes,
                                style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 13))),
                      ],
                    ),
                  ),
                ],

                // Completion (after) image
                if (isDone &&
                    assignment.completionImageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AFTER PHOTO',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          assignment.completionImageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      height: 150,
                                      color: Colors.white
                                          .withOpacity(0.03),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              color:
                                                  Color(0xFF10B981),
                                              strokeWidth: 2))),
                          errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: Colors.white.withOpacity(0.03),
                              child: const Center(
                                  child: Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.white24))),
                        ),
                      ),
                    ],
                  ),
                ],

                // Mark Done button
                if (!isDone) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _markDoneSheet(context, assignment),
                      icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18),
                      label: const Text('MARK AS DONE',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );

  void _markDoneSheet(BuildContext context, AssignmentModel assignment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) =>
          _MarkDoneForm(assignment: assignment),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MARK DONE FORM (Stateful bottom sheet with image upload)
// ─────────────────────────────────────────────────────────────
class _MarkDoneForm extends StatefulWidget {
  final AssignmentModel assignment;
  const _MarkDoneForm({required this.assignment});

  @override
  State<_MarkDoneForm> createState() => _MarkDoneFormState();
}

class _MarkDoneFormState extends State<_MarkDoneForm> {
  final _notesCtrl = TextEditingController();
  XFile? _afterImageFile;
  String? _afterImageUrl;
  bool _uploadingImage = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAfterImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() {
      _afterImageFile = file;
      _uploadingImage = true;
    });
    final url = await StorageService()
        .uploadImage(file, 'assignments/after/${widget.assignment.assignmentId}');
    setState(() {
      _afterImageUrl = url;
      _uploadingImage = false;
    });
  }

  Future<void> _submit() async {
    if (_afterImageUrl == null || _afterImageUrl!.isEmpty) {
      setState(() => _error = 'Please upload an after-work photo first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final provider = Provider.of<WorkerProvider>(context, listen: false);
      await provider.markAssignmentDone(
        widget.assignment.assignmentId,
        _notesCtrl.text.trim(),
        completionImageUrl: _afterImageUrl!,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 22),
                SizedBox(width: 12),
                Text('Mark Job as Done',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),

            // After photo upload
            Text('AFTER PHOTO *',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _uploadingImage ? null : _pickAfterImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _afterImageUrl != null ? 180 : 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _afterImageUrl != null
                      ? Colors.transparent
                      : const Color(0xFF10B981).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _afterImageUrl != null
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFF10B981).withOpacity(0.2),
                      width: 1.5),
                ),
                child: _uploadingImage
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: Color(0xFF10B981),
                                strokeWidth: 2),
                            SizedBox(height: 12),
                            Text('Uploading photo...',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      )
                    : _afterImageUrl != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _afterImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _pickAfterImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.edit_rounded,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.9),
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  child: const Text('AFTER PHOTO ✓',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded,
                                  color: Color(0xFF10B981), size: 36),
                              const SizedBox(height: 10),
                              const Text('Tap to add after-work photo',
                                  style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Required — shows completed work',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 11)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),

            // Notes field
            Text('NOTES (OPTIONAL)',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'e.g. Fixed the broken wire, replaced fuse...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2), fontSize: 13),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF10B981))),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _submitting || _uploadingImage
                          ? null
                          : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18),
                      label: const Text('SUBMIT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
