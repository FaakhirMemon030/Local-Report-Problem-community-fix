import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../main.dart';
import '../../screens/admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isEditing = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    _nameController.text = user?.name ?? '';
    _passwordController.text = user?.password ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    try {
      if (_nameController.text.trim() != user?.name) {
        await authProvider.updateName(_nameController.text.trim());
      }
      if (_passwordController.text.trim().isNotEmpty && _passwordController.text.trim() != user?.password) {
        await authProvider.updatePassword(_passwordController.text.trim());
      }
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('PROFILE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              if (_isEditing) {
                _handleSave();
              } else {
                setState(() => _isEditing = true);
              }
            },
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, color: const Color(0xFF60A5FA)),
          ),
          if (_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = user?.name ?? '';
                  _passwordController.text = user?.password ?? '';
                });
              },
              icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            top: 50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Avatar Section
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF1E293B),
                        child: Text(
                          (user?.name ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Editable Name Field
                  _buildProfileField(
                    label: 'DISPLAY NAME',
                    controller: _nameController,
                    icon: Icons.person_rounded,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 16),
                  
                  // Static Email Field (Immutable)
                  _buildProfileField(
                    label: 'EMAIL ADDRESS',
                    controller: TextEditingController(text: user?.email ?? ''),
                    icon: Icons.email_rounded,
                    isEditing: false,
                    isLocked: true,
                  ),
                  const SizedBox(height: 16),

                  // Editable Password Field
                  _buildProfileField(
                    label: 'PASSWORD',
                    controller: _passwordController,
                    icon: Icons.lock_rounded,
                    isEditing: _isEditing,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),

                  // City Section (Read-only for now)
                  _buildProfileField(
                    label: 'CITY',
                    controller: TextEditingController(text: user?.city ?? 'Not specified'),
                    icon: Icons.location_city_rounded,
                    isEditing: false,
                    isLocked: true,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  if (!_isEditing) ...[
                    if (user?.role == 'admin') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                          label: const Text('ADMIN PANEL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: const Color(0xFF60A5FA),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            side: BorderSide(color: const Color(0xFF60A5FA).withOpacity(0.3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          await authProvider.signOut();
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthWrapper()),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                        label: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Delete Account Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.5), size: 18),
                        label: Text(
                          'DELETE ACCOUNT',
                          style: TextStyle(
                            color: Colors.redAccent.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (authProvider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be cleared.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await Provider.of<AuthProvider>(context, listen: false).deleteAccount();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isEditing,
    bool isPassword = false,
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isEditing ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              if (isLocked) ...[
                const Spacer(),
                Icon(Icons.lock_rounded, size: 12, color: Colors.white.withOpacity(0.1)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (isEditing)
            TextField(
              controller: controller,
              obscureText: isPassword && !_showPassword,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Enter $label',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
                suffixIcon: isPassword ? IconButton(
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ) : null,
              ),
            )
          else
            Text(
              isPassword ? '••••••••' : controller.text,
              style: TextStyle(color: Colors.white.withOpacity(isLocked ? 0.5 : 1), fontSize: 16, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
