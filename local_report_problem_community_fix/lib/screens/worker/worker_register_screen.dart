import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/worker_provider.dart';
import '../../models/worker_model.dart';
import 'worker_dashboard_screen.dart';

class WorkerRegisterScreen extends StatefulWidget {
  const WorkerRegisterScreen({super.key});

  @override
  State<WorkerRegisterScreen> createState() => _WorkerRegisterScreenState();
}

class _WorkerRegisterScreenState extends State<WorkerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cnicCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  WorkerCategory _category = WorkerCategory.electrician;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose();
    _phoneCtrl.dispose(); _cnicCtrl.dispose(); _cityCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerProvider = Provider.of<WorkerProvider>(context);

    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFF10B981), size: 64),
                ),
                const SizedBox(height: 32),
                const Text('Registration Submitted!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(
                  'Your application is under review. You will be able to login once an admin approves your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, height: 1.6),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('BACK TO LOGIN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('WORKER REGISTRATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('PERSONAL INFO', Icons.person_rounded),
              const SizedBox(height: 16),
              _buildField(_nameCtrl, 'Full Name', Icons.person_outline, validator: _required),
              const SizedBox(height: 16),
              _buildField(_emailCtrl, 'Email Address', Icons.email_outlined, validator: _required),
              const SizedBox(height: 16),
              _buildField(_passwordCtrl, 'Password', Icons.lock_outline, obscure: true,
                validator: (v) => (v ?? '').length < 6 ? 'Min 6 characters' : null),
              const SizedBox(height: 16),
              _buildField(_phoneCtrl, 'Phone Number', Icons.phone_outlined, validator: _required),
              const SizedBox(height: 16),
              _buildField(_cnicCtrl, 'CNIC (e.g. 42101-1234567-1)', Icons.credit_card_outlined,
                validator: _required),
              const SizedBox(height: 32),
              _sectionHeader('JOB CATEGORY', Icons.work_outline_rounded),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 32),
              _sectionHeader('LOCATION', Icons.location_on_outlined),
              const SizedBox(height: 16),
              _buildField(_cityCtrl, 'City', Icons.location_city_outlined, validator: _required),
              const SizedBox(height: 16),
              _buildField(_addressCtrl, 'Current Address', Icons.home_outlined, maxLines: 2, validator: _required),
              const SizedBox(height: 32),
              _sectionHeader('DOCUMENTS', Icons.folder_outlined),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Note: After submitting, the admin will request document verification via your email.', 
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
                    const SizedBox(height: 12),
                    _docRow(Icons.credit_card, 'CNIC Photo'),
                    _docRow(Icons.bolt_outlined, 'Electricity Bill'),
                    _docRow(Icons.local_fire_department_outlined, 'Gas Bill'),
                    _docRow(Icons.photo_camera_outlined, 'Profile Photo'),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: workerProvider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: workerProvider.isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _docRow(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        const Spacer(),
        Text('Required', style: TextStyle(color: Colors.orange.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _sectionHeader(String title, IconData icon) => Row(
    children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Icon(icon, size: 16, color: Colors.white.withOpacity(0.4)),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 11)),
    ],
  );

  Widget _buildCategorySelector() {
    final cats = {
      WorkerCategory.electrician: ('Electrician', Icons.bolt_rounded),
      WorkerCategory.plumber: ('Plumber', Icons.water_drop_rounded),
      WorkerCategory.road: ('Road Worker', Icons.construction_rounded),
      WorkerCategory.drainage: ('Drainage', Icons.waves_rounded),
      WorkerCategory.garbage: ('Garbage', Icons.delete_sweep_rounded),
      WorkerCategory.election: ('Election Staff', Icons.how_to_vote_rounded),
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cats.entries.map((e) {
        final selected = _category == e.key;
        return GestureDetector(
          onTap: () => setState(() => _category = e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(e.value.$2, size: 16, color: selected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.4)),
                const SizedBox(width: 8),
                Text(e.value.$1, style: TextStyle(color: selected ? const Color(0xFF10B981) : Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {
    bool obscure = false, String? Function(String?)? validator, int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      final provider = Provider.of<WorkerProvider>(context, listen: false);
      await provider.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cnic: _cnicCtrl.text.trim(),
        category: _category,
        city: _cityCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      // Sign out immediately since they need admin approval
      await provider.signOut();
      setState(() => _submitted = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }
}
