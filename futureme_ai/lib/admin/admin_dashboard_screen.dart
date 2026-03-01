import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN TERMINAL'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found in database.'));
          }

          final users = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCards(users),
                const SizedBox(height: 24),
                const Text('USER DATABASE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: user.isPremium ? AppTheme.primaryNeon : AppTheme.surfaceDark,
                            child: Text(user.name[0], style: TextStyle(color: user.isPremium ? AppTheme.backgroundDark : Colors.white)),
                          ),
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(user.role.toUpperCase(), style: TextStyle(fontSize: 10, color: user.role == 'admin' ? AppTheme.primaryNeon : Colors.white54)),
                              const SizedBox(height: 4),
                              Icon(user.isPremium ? Icons.star : Icons.star_border, size: 16, color: user.isPremium ? Colors.amber : Colors.white24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(List<UserModel> users) {
    int premiumCount = users.where((u) => u.isPremium).length;
    return Row(
      children: [
        Expanded(child: _buildStatTile('TOTAL USERS', users.length.toString(), Icons.people_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile('PREMIUM', premiumCount.toString(), Icons.workspace_premium_outlined)),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryNeon, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}
