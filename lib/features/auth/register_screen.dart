import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum _Step { personal, credentials, role }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color kPrimary = Color(0xFF3D5AFE);

  _Step _currentStep = _Step.personal;
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'Member';

  final _personalFormKey = GlobalKey<FormState>();
  final _credentialsFormKey = GlobalKey<FormState>();

  final List<String> _roles = ['Member', 'Team Lead', 'Department Head', 'Super Admin'];

  final List<Map<String, dynamic>> _roleDetails = [
    {'role': 'Member', 'icon': Icons.person_outline, 'desc': 'Volunteer, attend tasks & check-in'},
    {'role': 'Team Lead', 'icon': Icons.group_outlined, 'desc': 'Manage a squad, assign tasks'},
    {'role': 'Department Head', 'icon': Icons.manage_accounts_outlined, 'desc': 'Oversee department operations'},
    {'role': 'Super Admin', 'icon': Icons.admin_panel_settings_outlined, 'desc': 'Full control room access'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int get _stepIndex => _Step.values.indexOf(_currentStep);

  void _nextStep() {
    if (_currentStep == _Step.personal) {
      if (!_personalFormKey.currentState!.validate()) return;
      setState(() => _currentStep = _Step.credentials);
    } else if (_currentStep == _Step.credentials) {
      if (!_credentialsFormKey.currentState!.validate()) return;
      setState(() => _currentStep = _Step.role);
    } else {
      _handleRegister();
    }
  }

  void _prevStep() {
    if (_currentStep == _Step.credentials) {
      setState(() => _currentStep = _Step.personal);
    } else if (_currentStep == _Step.role) {
      setState(() => _currentStep = _Step.credentials);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created! Welcome to GroundFlow.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A2E)),
          onPressed: _currentStep == _Step.personal ? () => Navigator.pop(context) : _prevStep,
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _buildCurrentStep(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Personal Info', 'Credentials', 'Your Role'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _stepIndex;
          final isDone = i < _stepIndex;
          return Expanded(
            child: Row(
              children: [
                _StepDot(index: i, isActive: isActive, isDone: isDone, label: steps[i]),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? kPrimary : const Color(0xFFE5E7EB),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case _Step.personal:
        return _buildPersonalStep();
      case _Step.credentials:
        return _buildCredentialsStep();
      case _Step.role:
        return _buildRoleStep();
    }
  }

  Widget _buildPersonalStep() {
    return Form(
      key: _personalFormKey,
      child: Column(
        key: const ValueKey('personal'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Tell us about yourself', 'Your name as it will appear to your team.'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameCtrl,
            label: 'Full Name',
            hint: 'e.g. Alex Johnson',
            icon: Icons.badge_outlined,
            validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailCtrl,
            label: 'College Email',
            hint: 'you@college.edu',
            icon: Icons.school_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.info_outline,
            text: 'Use your official college email. You\'ll receive a verification link.',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildCredentialsStep() {
    return Form(
      key: _credentialsFormKey,
      child: Column(
        key: const ValueKey('credentials'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Secure your account', 'Choose a strong password.'),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Min 8 characters',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'At least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordStrength(_passwordCtrl.text),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildRoleStep() {
    return Column(
      key: const ValueKey('role'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Select your role', 'Your coordinator can change this later.'),
        const SizedBox(height: 24),
        ..._roleDetails.map((rd) {
          final isSelected = _selectedRole == rd['role'] as String;
          return GestureDetector(
            onTap: () => setState(() => _selectedRole = rd['role'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? kPrimary : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: kPrimary.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimary : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rd['icon'] as IconData, color: isSelected ? Colors.white : const Color(0xFF6B7280), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rd['role'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isSelected ? kPrimary : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rd['desc'] as String,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: kPrimary, size: 22),
                ],
              ),
            ),
          );
        }),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0, duration: 400.ms);
  }

  Widget _buildPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*]'))) strength++;

    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.lightGreen, Colors.green];
    final labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: i < strength ? colors[strength] : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: ${labels[strength]}',
          style: TextStyle(fontSize: 12, color: strength > 0 ? colors[strength] : const Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kPrimary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == _Step.role ? 'Create Account' : 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final bool isActive;
  final bool isDone;
  final String label;

  const _StepDot({required this.index, required this.isActive, required this.isDone, required this.label});

  static const Color kPrimary = Color(0xFF3D5AFE);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? kPrimary : (isActive ? kPrimary.withOpacity(0.15) : const Color(0xFFF3F4F6)),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isActive || isDone) ? kPrimary : const Color(0xFFE5E7EB),
              width: 2,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? kPrimary : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? kPrimary : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
