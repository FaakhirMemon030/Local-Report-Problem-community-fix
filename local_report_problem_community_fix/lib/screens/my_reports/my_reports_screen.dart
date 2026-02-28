import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problem_provider.dart';
import '../../widgets/problem_card.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUserId != null) {
        // We'll need to modify ProblemProvider.fetchProblems to accept reportedBy filter
        // Or handle it in FirestoreService. For now, let's assume we fetch all and filter locally
        // or I'll quickly update FirestoreService to support this.
        Provider.of<ProblemProvider>(context, listen: false).fetchProblems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final problemProvider = Provider.of<ProblemProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final myProblems = problemProvider.problems
        .where((p) => p.reportedBy == authProvider.currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: problemProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : myProblems.isEmpty
              ? const Center(child: Text('You haven\'t reported any issues yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myProblems.length,
                  itemBuilder: (context, index) {
                    final problem = myProblems[index];
                    return ProblemCard(problem: problem);
                  },
                ),
    );
  }
}
