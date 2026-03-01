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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('MY REPORTS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.05),
              ),
            ),
          ),
          
          problemProvider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
              : myProblems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 16),
                          Text(
                            'NO REPORTS YET',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Issues you report will appear here',
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: myProblems.length,
                      itemBuilder: (context, index) {
                        final problem = myProblems[index];
                        return ProblemCard(problem: problem);
                      },
                    ),
        ],
      ),
    );
  }
}
