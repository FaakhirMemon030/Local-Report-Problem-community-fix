import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/problem_provider.dart';
import '../../models/problem_model.dart';
import '../../widgets/problem_card.dart';

class TopIssuesScreen extends StatefulWidget {
  const TopIssuesScreen({super.key});

  @override
  State<TopIssuesScreen> createState() => _TopIssuesScreenState();
}

class _TopIssuesScreenState extends State<TopIssuesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemProvider>(context, listen: false).fetchProblems(sortBy: 'priorityScore');
    });
  }

  @override
  Widget build(BuildContext context) {
    final problemProvider = Provider.of<ProblemProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('TOP RANKED'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.03),
              ),
            ),
          ),
          
          problemProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : problemProvider.problems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.leaderboard_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text(
                            'NO ISSUES FOUND',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: problemProvider.problems.length,
                      itemBuilder: (context, index) {
                        final problem = problemProvider.problems[index];
                        // Optionally add a header for the very first item
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_up_rounded, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TRENDING ISSUES',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ProblemCard(problem: problem),
                            ],
                          );
                        }
                        return ProblemCard(problem: problem);
                      },
                    ),
        ],
      ),
    );
  }
}
