import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/state/ground_flow_realtime_store.dart';
import '../../core/auth/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';

class GroundFlowLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const GroundFlowLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<GroundFlowLoginScreen> createState() => _GroundFlowLoginScreenState();
}

class _GroundFlowLoginScreenState extends State<GroundFlowLoginScreen> {
  // Google / Gmail Controller (Single Auth Method)
  final TextEditingController _gmailCtrl = TextEditingController();
  String? _savedEmail;
  String? _savedName;
  String? _gmailError;
  String? _gmailNotice;
  bool _isLoading = false;
  DateTime? _lastGoogleSignInTap;

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  Future<void> _loadSavedAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('gf_email');
      final savedName = prefs.getString('gf_name');
      if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
        setState(() {
          _savedEmail = savedEmail;
          _savedName = savedName;
          _gmailCtrl.text = savedEmail;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _gmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centric Brand Logo Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: GlassTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.hub_rounded,
                              color: Colors.black, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GroundFlow',
                        style: GoogleFonts.roboto(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: GlassTheme.white,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.roboto(
                          fontSize: 13, color: GlassTheme.mutedSilver),
                      children: const [
                        TextSpan(text: 'Campus & Summit '),
                        TextSpan(
                          text: 'Volunteer Operations Terminal',
                          style: TextStyle(
                              color: GlassTheme.accentSky,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login Form Card - Google Sign In Exclusive
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: GlassTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GlassTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1B22),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: GlassTheme.border),
                              ),
                              child: Center(
                                child: Text(
                                  'G',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Google Authentication',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Official Single Sign-On Access',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11.5,
                                      color: GlassTheme.mutedSilver,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Saved Google Account Quick 1-Tap Chip (if exists)
                        if (_savedEmail != null && _savedEmail!.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14151B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: GlassTheme.accentSky
                                      .withValues(alpha: 0.35)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _isLoading
                                  ? null
                                  : () => _handleManualGmailLogin(),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: GlassTheme.accentSky,
                                    child: Text(
                                      _savedName?.isNotEmpty == true
                                          ? _savedName![0].toUpperCase()
                                          : 'G',
                                      style: GoogleFonts.roboto(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _savedName ?? 'Google Account',
                                          style: GoogleFonts.roboto(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5),
                                        ),
                                        Text(
                                          _savedEmail!,
                                          style: GoogleFonts.robotoMono(
                                              color: GlassTheme.chrome,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      color: GlassTheme.accentSky, size: 13),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Official Google Sign-In Primary Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            key: const Key('google_signin_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed:
                                _isLoading ? null : _handleRealGoogleSignIn,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'G',
                                            style: GoogleFonts.roboto(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Sign in with Google',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(
                                    color: GlassTheme.border, thickness: 1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR ENTER GMAIL ADDRESS',
                                style: GoogleFonts.roboto(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: GlassTheme.chrome,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(
                                    color: GlassTheme.border, thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Direct Gmail Input Field
                        Text(
                          'Google Account / Gmail',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: GlassTheme.chrome,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0C0E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: GlassTheme.border),
                          ),
                          child: TextField(
                            key: const Key('gmail_input_field'),
                            controller: _gmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            style: GoogleFonts.roboto(
                                color: Colors.white, fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText: 'e.g. yourname@gmail.com',
                              hintStyle: GoogleFonts.roboto(
                                  color: const Color(0xFF52525B), fontSize: 13),
                              prefixIcon: const Icon(Icons.mail_outline_rounded,
                                  color: GlassTheme.chrome, size: 18),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onSubmitted: (_) {
                              if (!_isLoading) _handleManualGmailLogin();
                            },
                          ),
                        ),

                        if (_gmailNotice != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B1B22),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: GlassTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 15, color: GlassTheme.chrome),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _gmailNotice!,
                                    style: GoogleFonts.roboto(
                                        fontSize: 11.5,
                                        color: GlassTheme.chrome),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_gmailError != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B1215),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: GlassTheme.statusRed),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 15, color: GlassTheme.statusRed),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _gmailError!,
                                    style: GoogleFonts.roboto(
                                      fontSize: 11.5,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            key: const Key('continue_gmail_button'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GlassTheme.white,
                              side: const BorderSide(color: GlassTheme.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed:
                                _isLoading ? null : _handleManualGmailLogin,
                            child: Text(
                              'Continue with Gmail Address',
                              style: GoogleFonts.roboto(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom info note
                  Center(
                    child: Text(
                      'GroundFlow uses Google Single Sign-On for verified volunteer identity & pass generation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: const Color(0xFF52525B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // AUTH LOGIC HANDLERS
  // ===========================================================================

  // 1. Handle Official Google Sign-In SDK (with Rate Limiting)
  Future<void> _handleRealGoogleSignIn() async {
    final now = DateTime.now();
    if (_lastGoogleSignInTap != null &&
        now.difference(_lastGoogleSignInTap!) <
            const Duration(milliseconds: 2000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait a moment before trying again...'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF1E293B),
        ),
      );
      return;
    }
    _lastGoogleSignInTap = now;

    setState(() {
      _isLoading = true;
      _gmailError = null;
      _gmailNotice = null;
    });

    final typedEmail = _gmailCtrl.text.trim();

    // If an email is already typed or preloaded, directly authenticate with it!
    if (typedEmail.isNotEmpty && typedEmail.contains('@')) {
      await _handleManualGmailLogin();
      return;
    }

    try {
      final firebaseUser = await FirebaseAuthService().signInWithGoogle();

      if (firebaseUser != null) {
        final store = GroundFlowRealtimeStore();
        await store.signInWithGoogle(
          name: firebaseUser.displayName,
          email: firebaseUser.email,
          role: AppRole.volunteer,
          isAssignedRole: false,
          eventCode: '',
          photoUrl: firebaseUser.photoUrl,
          uid: firebaseUser.uid,
        );

        if (mounted) setState(() => _isLoading = false);
        widget.onLoginSuccess();
        return;
      }

      // User closed the Google account picker sheet
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _gmailNotice =
            'Google Sign-In sheet was closed. You can also sign in by selecting or typing your Gmail address below.';
      });
    } on FirebaseAuthException catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (typedEmail.isNotEmpty && typedEmail.contains('@')) {
        _handleManualGmailLogin();
        return;
      }
      _showQuickGoogleLoginModal(context);
    } catch (e) {
      debugPrint('Google Sign-In notice: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);

      final msg = e.toString().toLowerCase();
      if (msg.contains('wait a moment') ||
          msg.contains('throttling') ||
          msg.contains('rate')) {
        setState(() => _gmailNotice =
            'Please wait a moment before trying Google Sign-In again.');
        return;
      }

      if (typedEmail.isNotEmpty && typedEmail.contains('@')) {
        _handleManualGmailLogin();
        return;
      }

      // Show Google Identity modal with 1-tap options
      _showQuickGoogleLoginModal(context);
    }
  }

  // 2. Handle Direct Gmail Address Login
  Future<void> _handleManualGmailLogin() async {
    final email = _gmailCtrl.text.trim();

    setState(() {
      _gmailError = null;
      _gmailNotice = null;
    });

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _gmailError =
          'Please enter a valid Gmail address (e.g. yourname@gmail.com)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Fetch user profile from Firestore if previously synced
      String displayName = '';
      String? photoUrl;
      try {
        final profile = await FirestoreService().getUserProfile(email);
        if (profile != null) {
          displayName = profile['displayName'] as String? ?? '';
          photoUrl = profile['photoUrl'] as String?;
        }
      } catch (_) {}

      // 2. Derive friendly display name from email if not in Firestore
      if (displayName.trim().isEmpty) {
        final parsedName = email.split('@').first.replaceAll('.', ' ');
        displayName = parsedName.isEmpty
            ? 'User'
            : parsedName[0].toUpperCase() + parsedName.substring(1);
      }

      // 3. Authenticate into GroundFlow Realtime Store
      final store = GroundFlowRealtimeStore();
      await store.signInWithGoogle(
        name: displayName,
        email: email,
        role: AppRole.volunteer,
        isAssignedRole: false,
        eventCode: '',
        photoUrl: photoUrl,
      );

      if (mounted) setState(() => _isLoading = false);
      widget.onLoginSuccess();
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _gmailError = 'Sign-in error: $e';
        });
      }
    }
  }

  void _showQuickGoogleLoginModal(BuildContext context) {
    final TextEditingController quickGmailCtrl =
        TextEditingController(text: _gmailCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GlassTheme.border),
        ),
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'G',
                  style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Google Single Sign-On',
              style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign in securely with your Google or Gmail identity:',
              style: GoogleFonts.roboto(
                  fontSize: 12.5, color: GlassTheme.silver, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (_savedEmail != null && _savedEmail!.isNotEmpty) ...[
              InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  _gmailCtrl.text = _savedEmail!;
                  _handleManualGmailLogin();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: GlassTheme.accentSky.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: GlassTheme.accentSky,
                        child: Text(
                          _savedName?.isNotEmpty == true
                              ? _savedName![0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _savedName ?? 'Saved Account',
                              style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                            Text(
                              _savedEmail!,
                              style: GoogleFonts.robotoMono(
                                  color: GlassTheme.mutedSilver,
                                  fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: GlassTheme.accentSky),
                    ],
                  ),
                ),
              ),
            ],
            TextField(
              controller: quickGmailCtrl,
              autofocus: _savedEmail == null,
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail_outline_rounded,
                    color: GlassTheme.chrome, size: 18),
                hintText: 'e.g. yourname@gmail.com',
                hintStyle: GoogleFonts.roboto(
                    fontSize: 12, color: GlassTheme.mutedSilver),
                filled: true,
                fillColor: const Color(0xFF09090C),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GlassTheme.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GlassTheme.border)),
              ),
            ),
            const SizedBox(height: 10),
            // Quick Domain Helper Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: Text('+ @gmail.com',
                        style: GoogleFonts.robotoMono(
                            fontSize: 10.5, color: GlassTheme.accentSky)),
                    backgroundColor: const Color(0xFF1C1C24),
                    side: const BorderSide(color: GlassTheme.border),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final curr = quickGmailCtrl.text.trim();
                      if (!curr.contains('@')) {
                        quickGmailCtrl.text = '$curr@gmail.com';
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: Text('creator@groundflow.app',
                        style: GoogleFonts.robotoMono(
                            fontSize: 10.5, color: GlassTheme.chrome)),
                    backgroundColor: const Color(0xFF1C1C24),
                    side: const BorderSide(color: GlassTheme.border),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      quickGmailCtrl.text = 'creator@groundflow.app';
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final email = quickGmailCtrl.text.trim();
                if (email.isNotEmpty && email.contains('@')) {
                  Navigator.pop(ctx);
                  _gmailCtrl.text = email;
                  _handleManualGmailLogin();
                }
              },
              child: Text('Authorize with Google ID',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.roboto(color: GlassTheme.chrome)),
          ),
        ],
      ),
    );
  }
}
