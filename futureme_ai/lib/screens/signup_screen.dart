import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CREATE TIMELINE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryNeon.withOpacity(0.1),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                GlassmorphicContainer(
                  width: double.infinity,
                  height: 650,
                  borderRadius: 20,
                  blur: 20,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryNeon.withOpacity(0.5),
                      AppTheme.secondaryNeon.withOpacity(0.5),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
                        const SizedBox(height: 16),
                        _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_ageController, 'Age', Icons.calendar_today_outlined, isNumber: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(_salaryController, 'Base Salary', Icons.attach_money, isNumber: true)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_professionController, 'Profession', Icons.work_outline),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNeon,
                              foregroundColor: AppTheme.backgroundDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: userProvider.isLoading
                                ? null
                                : () async {
                                    final newUser = UserModel(
                                      userId: '', // Firebase will set this
                                      name: _nameController.text,
                                      email: _emailController.text,
                                      age: int.tryParse(_ageController.text) ?? 0,
                                      profession: _professionController.text,
                                      baseSalary: double.tryParse(_salaryController.text) ?? 0.0,
                                      currentHealthScore: 80.0, // Default start
                                      createdAt: DateTime.now(),
                                    );
                                    await userProvider.signUp(newUser, _passwordController.text);
                                    if (mounted && userProvider.userModel != null) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: userProvider.isLoading
                                ? const CircularProgressIndicator(color: AppTheme.backgroundDark)
                                : const Text('CREATE MY FUTURE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ALREADY HAVE A TIMELINE? LOGIN', style: TextStyle(color: AppTheme.primaryNeon)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryNeon, size: 20),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryNeon)),
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      ),
    );
  }
}
