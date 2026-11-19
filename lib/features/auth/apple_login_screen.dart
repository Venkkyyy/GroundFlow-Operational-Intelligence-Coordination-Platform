import 'package:flutter/material.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/state/ground_flow_realtime_store.dart';

class AppleLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const AppleLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<AppleLoginScreen> createState() => _AppleLoginScreenState();
}

class _AppleLoginScreenState extends State<AppleLoginScreen> {
  final TextEditingController _eventCodeCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  
  AppRole _selectedRole = AppRole.departmentHead;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.black,
      body: Stack(
        children: [
          // Ambient Specular Glow behind glass
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Centric Layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Apple-Grade Chrome Brand Mark
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFA1A1A6),
                              Color(0xFFFFFFFF),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.blur_on_rounded, size: 40, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Brand Titles
                      const Text(
                        'GroundFlow',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: GlassTheme.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mission-Critical Event Command & Telemetry',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: GlassTheme.mutedSilver,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Glass Card Form
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        borderRadius: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Event Passcode',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GlassTheme.chrome),
                            ),
                            const SizedBox(height: 8),
                            _buildGlassInput(
                              controller: _eventCodeCtrl,
                              hint: 'Enter event code (e.g. SUMMIT-2026)',
                              prefixIcon: Icons.lock_outline_rounded,
                            ),
                            const SizedBox(height: 18),

                            const Text(
                              'Select Operational Role',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GlassTheme.chrome),
                            ),
                            const SizedBox(height: 8),
                            _buildRoleSelector(),
                            const SizedBox(height: 24),

                            // Google / Gmail Single-Tap Sign In
                            _buildGoogleButton(),
                            const SizedBox(height: 14),

                            Center(
                              child: Text(
                                'Role dynamically reconfigures navigation & security scope',
                                style: TextStyle(fontSize: 11, color: GlassTheme.mutedSilver.withValues(alpha: 0.8)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick 1-Tap Demo Switcher (Instant access for testing all 3 roles!)
                      const Text(
                        'Instant Role Preview',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GlassTheme.mutedSilver),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickRoleChip('Head of Media', AppRole.departmentHead),
                          _quickRoleChip('Squad Lead', AppRole.teamLead),
                          _quickRoleChip('Volunteer', AppRole.volunteer),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101016),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF6E6E78), fontSize: 13.5),
          prefixIcon: Icon(prefixIcon, color: GlassTheme.chrome, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        _rolePill(AppRole.departmentHead, 'Head', Icons.military_tech_rounded),
        const SizedBox(width: 6),
        _rolePill(AppRole.teamLead, 'Lead', Icons.groups_rounded),
        const SizedBox(width: 6),
        _rolePill(AppRole.volunteer, 'Member', Icons.person_rounded),
      ],
    );
  }

  Widget _rolePill(AppRole role, String label, IconData icon) {
    final isSel = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isSel ? Colors.white : const Color(0xFF101016),
            border: Border.all(
              color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              if (isSel)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 12,
                ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSel ? Colors.black : GlassTheme.mutedSilver),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isSel ? Colors.black : GlassTheme.silver,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFDCDCE0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleGoogleLogin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Google G Symbol
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Continue with Google (Gmail)',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickRoleChip(String label, AppRole role) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = role);
        _handleGoogleLogin();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF14141E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: GlassTheme.silver, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final store = GroundFlowRealtimeStore();

    String name = 'Vinik Shah';
    String email = 'vinik.shah@bcs2026.org';
    if (_selectedRole == AppRole.teamLead) {
      name = 'Arjun Mehta (Lead)';
      email = 'arjun.lead@bcs2026.org';
    } else if (_selectedRole == AppRole.volunteer) {
      name = 'Sara Ali (Volunteer)';
      email = 'sara.ali@bcs2026.org';
    }

    await store.signInWithGoogle(
      name: name,
      email: email,
      role: _selectedRole,
      eventCode: _eventCodeCtrl.text.trim(),
    );

    setState(() => _isLoading = false);
    widget.onLoginSuccess();
  }
}
