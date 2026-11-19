import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showInviteField = false;
  final _inviteCtrl = TextEditingController();

  static const Color kPrimary = Color(0xFF3D5AFE);
  static const Color kDarkNavy = Color(0xFF0A0E21);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Navigate after login (replace with go_router push)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login successful!')),
    );
  }

  Future<void> _handleInviteJoin() async {
    if (_inviteCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite accepted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kPrimary, Color(0xFF1A237E), kDarkNavy],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 48),
                  _buildFormCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: const Icon(Icons.stream_rounded, color: Colors.white, size: 40),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.6, 0.6), duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text(
          'GroundFlow',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),
        const SizedBox(height: 8),
        Text(
          'Event Ops · Redefined',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 14,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w400,
          ),
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _showInviteField ? 'Join with Invite Code' : 'Welcome back',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _showInviteField
                  ? 'Enter the invite code shared by your coordinator'
                  : 'Sign in to your GroundFlow account',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 28),
            if (!_showInviteField) ...[
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'you@college.edu',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordCtrl,
                label: 'Password',
                hint: '••••••••',
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
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot password?', style: TextStyle(color: kPrimary)),
                ),
              ),
              const SizedBox(height: 8),
              _buildPrimaryButton(
                label: 'Sign In',
                onPressed: _handleLogin,
              ),
            ] else ...[
              _buildTextField(
                controller: _inviteCtrl,
                label: 'Invite Code',
                hint: 'e.g. BCSM-2024-XYZ',
                icon: Icons.qr_code_2_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your invite code';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPrimaryButton(
                label: 'Join Event',
                onPressed: _handleInviteJoin,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showInviteField = !_showInviteField),
              icon: Icon(
                _showInviteField ? Icons.login_rounded : Icons.card_giftcard_rounded,
                size: 18,
              ),
              label: Text(
                _showInviteField ? 'Sign in instead' : 'Join with invite code',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  // go_router: context.push('/auth/register')
                },
                child: RichText(
                  text: const TextSpan(
                    text: "New to GroundFlow? ",
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Create account',
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.4, end: 0, duration: 600.ms, curve: Curves.easeOut);
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kPrimary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
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
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
      ),
    );
  }
}
