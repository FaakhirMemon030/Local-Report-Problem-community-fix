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
      appBar: AppBar(title: const Text('Top Ranked Issues')),
      body: problemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : problemProvider.problems.isEmpty
              ? const Center(child: Text('No issues reported yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: problemProvider.problems.length,
                  itemBuilder: (context, index) {
                    final problem = problemProvider.problems[index];
                    return ProblemCard(problem: problem);
                  },
                ),
    );
  }
}
