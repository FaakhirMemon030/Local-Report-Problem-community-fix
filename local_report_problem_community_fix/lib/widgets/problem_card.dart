import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/problem_model.dart';
import '../providers/auth_provider.dart';
import '../providers/problem_provider.dart';

class ProblemCard extends StatelessWidget {
  final ProblemModel problem;
  const ProblemCard({super.key, required this.problem});

  @override
  Widget build(BuildContext context) {
    print("LPRCF: Rendering ProblemCard for '${problem.title}' (ID: ${problem.problemId}) - Votes: ${problem.voteCount}");
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  problem.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(problem.status).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      problem.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        problem.category.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(problem.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(problem.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        problem.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Material(
                        key: const ValueKey('vote_material'),
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final problemProvider = Provider.of<ProblemProvider>(context, listen: false);
                            if (authProvider.currentUserId != null) {
                              await problemProvider.voteProblem(problem.problemId, authProvider.currentUserId!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Voted Successfully!'), duration: Duration(seconds: 1)),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.thumb_up_alt_outlined, size: 20, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text(
                                  '${problem.voteCount} Votes',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 18, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Rank: ${problem.priorityScore.toStringAsFixed(1)}',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ProblemStatus status) {
    switch (status) {
      case ProblemStatus.pending: return Colors.orange;
      case ProblemStatus.approved: return Colors.blue;
      case ProblemStatus.resolved: return Colors.green;
      case ProblemStatus.rejected: return Colors.red;
    }
  }
}
