import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/problem_model.dart';
import '../providers/auth_provider.dart';
import '../providers/problem_provider.dart';
import '../services/firestore_service.dart';

class ProblemCard extends StatefulWidget {
  final ProblemModel problem;
  const ProblemCard({super.key, required this.problem});

  @override
  State<ProblemCard> createState() => _ProblemCardState();
}

class _ProblemCardState extends State<ProblemCard> {
  bool? _hasVoted; // null = loading, true = voted, false = not voted
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _loadVoteStatus();
  }

  Future<void> _loadVoteStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId == null) return;
    final voted = await FirestoreService()
        .hasUserVoted(widget.problem.problemId, authProvider.currentUserId!);
    if (mounted) setState(() => _hasVoted = voted);
  }

  @override
  Widget build(BuildContext context) {
    final problem = widget.problem;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Status Overlay
            Stack(
              children: [
                Image.network(
                  problem.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: const Color(0xFF0F172A),
                    child: Icon(Icons.broken_image_rounded,
                        size: 40, color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4)
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_rounded,
                            size: 12,
                            color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          problem.category.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(problem.status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: _getStatusColor(problem.status)
                                .withOpacity(0.3),
                            blurRadius: 8)
                      ],
                    ),
                    child: Text(
                      problem.status.name.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          problem.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(problem.createdAt),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          problem.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Section
                  Row(
                    children: [
                      // Upvote Button
                      Expanded(
                        child: _buildUpvoteButton(problem),
                      ),
                      const SizedBox(width: 12),
                      // Priority Score
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                size: 18, color: Colors.orange),
                            const SizedBox(width: 6),
                            Text(
                              problem.priorityScore.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpvoteButton(ProblemModel problem) {
    final alreadyVoted = _hasVoted == true;
    final color = alreadyVoted ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final icon = alreadyVoted ? Icons.thumb_up_rounded : Icons.thumb_up_rounded;

    return InkWell(
      onTap: _isVoting || alreadyVoted
          ? () {
              if (alreadyVoted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('You already upvoted this!'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          : () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final problemProvider =
                  Provider.of<ProblemProvider>(context, listen: false);
              if (authProvider.currentUserId == null) return;
              setState(() => _isVoting = true);
              try {
                await problemProvider.voteProblem(
                    problem.problemId, authProvider.currentUserId!);
                if (mounted) {
                  setState(() => _hasVoted = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Upvoted Successfully! 👍'),
                      backgroundColor: const Color(0xFF3B82F6),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                final msg = e.toString();
                if (mounted) {
                  if (msg.contains('already_voted')) {
                    setState(() => _hasVoted = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text('You already upvoted this!'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } finally {
                if (mounted) setState(() => _isVoting = false);
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(alreadyVoted ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: _isVoting
            ? const Center(
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF60A5FA))))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    alreadyVoted
                        ? '${problem.voteCount} UPVOTED ✓'
                        : '${problem.voteCount} UPVOTES',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getStatusColor(ProblemStatus status) {
    switch (status) {
      case ProblemStatus.pending:
        return Colors.orange;
      case ProblemStatus.approved:
        return const Color(0xFF3B82F6);
      case ProblemStatus.inProgress:
        return Colors.cyan;
      case ProblemStatus.solved:
        return const Color(0xFF10B981);
      case ProblemStatus.rejected:
        return Colors.redAccent;
    }
  }
}
