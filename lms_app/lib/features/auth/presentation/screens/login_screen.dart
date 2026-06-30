import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

final emailStatusProvider = StateProvider<String>((ref) => 'idle');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  String _error = '';
  Timer? _debounceTimer;

  // true = email trouvé → on affiche le mot de passe
  bool get _emailFound =>
      ref.read(emailStatusProvider) == 'found';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();

    if (!trimmed.contains('@') || !trimmed.contains('.') || trimmed.length < 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(emailStatusProvider.notifier).state = 'idle';
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(emailStatusProvider.notifier).state = 'checking';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_emailController.text.trim() == trimmed) _verifierEmail(trimmed);
    });
  }

  Future<void> _verifierEmail(String email) async {
    if (!mounted) return;
    try {
      print('🔍 [_verifierEmail] Vérification de: $email');
      await ref.read(authProvider.notifier).verifierEmailLogin(email);
      if (mounted) {
        print('✅ [_verifierEmail] Email trouvé, passage à l\'état found');
        ref.read(emailStatusProvider.notifier).state = 'found';
      }
    } catch (e) {
      print('❌ [_verifierEmail] Email non trouvé: $e');
      if (mounted) ref.read(emailStatusProvider.notifier).state = 'notfound';
    }
  }
Future<void> _lancerOAuth(String provider) async {
  final url = Uri.parse('http://192.168.1.168:3000/api/auth/$provider');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
  Future<void> _login() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      print('🔐 [_login] Tentative de login avec: ${_emailController.text.trim()}');
      await ref.read(authProvider.notifier).login(
        emailUser: _emailController.text.trim(),
        passwordUser: _passwordController.text.trim(),
      );
      print('✅ [_login] Login réussi, navigation vers /home');
      if (mounted) context.go('/home');
    } catch (e) {
      print('❌ [_login] Erreur login: $e');
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailStatus = ref.watch(emailStatusProvider);
    final showPassword = emailStatus == 'found';
    final showOAuth = emailStatus != 'found';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Chevron retour (visible seulement si email trouvé) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: showPassword
                    ? GestureDetector(
                        key: const ValueKey('back'),
                        onTap: () {
                          _emailController.clear();
                          _passwordController.clear();
                          setState(() { _error = ''; });
                          ref.read(emailStatusProvider.notifier).state = 'idle';
                        },
                        child: Container(
                          child: Icon(Icons.chevron_left, size: 40, color: Colors.grey[700]),
                        ),
                      )
                    : const SizedBox(key: ValueKey('no-back'), height: 0),
              ),

              // ── Titre ──
              Text(
                showPassword ? 'Bon retour !' : 'Ravi de vous revoir',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                showPassword
                    ? 'Entrez votre mot de passe pour continuer'
                    : 'Accédez à votre espace personnel',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
              ),
              const SizedBox(height: 32),

              // ── OAuth (masqué quand email trouvé) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showOAuth
                    ? Column(
                        key: const ValueKey('oauth'),
                        children: [
                          _buildOAuthButton(
                            label: 'Continuer avec Google',
                            onTap: () => _lancerOAuth('google'),
                            icon: _buildGoogleIcon(),
                          ),
                          const SizedBox(height: 12),
                          _buildOAuthButton(
                            label: 'Continuer avec GitHub',
                            onTap: () => _lancerOAuth('github'),
                            icon: _buildGithubIcon(),
                          ),
                          const SizedBox(height: 20),
                          Row(children: [
                            Expanded(child: Divider(color: Colors.grey[200])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey[400])),
                            ),
                            Expanded(child: Divider(color: Colors.grey[200])),
                          ]),
                          const SizedBox(height: 20),
                        ],
                      )
                    : const SizedBox(key: ValueKey('no-oauth')),
              ),

              // ── Email ──
              _buildLabel('Email'),
              const SizedBox(height: 6),
              _buildEmailInput(emailStatus),
              const SizedBox(height: 6),
              _buildEmailIndicator(emailStatus),

              // ── Mot de passe (apparaît automatiquement) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showPassword
                    ? Column(
                        key: const ValueKey('password'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel('Mot de passe'),
                              GestureDetector(
                                onTap: () => context.push('/mot-de-passe-oublie'),
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey[400]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildPasswordInput(),
                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildErrorBox(_error),
                          ],
                          const SizedBox(height: 20),
                          _buildPrimaryButton(
                            label: _isLoading ? 'Connexion...' : 'Se connecter',
                            icon: Icons.chevron_right,
                            disabled: _passwordController.text.trim().isEmpty || _isLoading,
                            isLoading: _isLoading,
                            onTap: _login,
                          ),
                        ],
                      )
                    : const SizedBox(key: ValueKey('no-password')),
              ),

              const SizedBox(height: 32),
              Divider(color: Colors.grey[200]),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Pas encore de compte ? ",
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[500])),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text("S'inscrire",
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Builders ──

  Widget _buildOAuthButton({
    required String label,
    required VoidCallback onTap,
    required Widget icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    const String googleSvg = '''
<svg width="18" height="18" viewBox="0 0 18 18" fill="none">
  <path d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.874 2.684-6.615z" fill="#4285F4"/>
  <path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z" fill="#34A853"/>
  <path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z" fill="#FBBC05"/>
  <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z" fill="#EA4335"/>
</svg>
''';
    return SvgPicture.string(googleSvg, width: 18, height: 18);
  }

  Widget _buildGithubIcon() {
    return SizedBox(
        width: 18, height: 18, child: CustomPaint(painter: _GitHubIconPainter()));
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]));
  }

  Widget _buildEmailInput(String emailStatus) {
    Color borderColor = Colors.grey[200]!;
    if (emailStatus == 'found') borderColor = Colors.green;
    if (emailStatus == 'notfound') borderColor = Colors.red[300]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: _onEmailChanged,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Entrer votre email',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: _buildEmailSuffixIcon(emailStatus),
        ),
      ),
    );
  }

  Widget? _buildEmailSuffixIcon(String emailStatus) {
    if (emailStatus == 'checking') {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      );
    }
    if (emailStatus == 'found') {
      return const Icon(Icons.check_circle_outline, color: Colors.green, size: 18);
    }
    if (emailStatus == 'notfound') {
      return Icon(Icons.cancel_outlined, color: Colors.red[400], size: 18);
    }
    return null;
  }

  Widget _buildEmailIndicator(String emailStatus) {
    if (emailStatus == 'checking') {
      return Row(children: [
        const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
        const SizedBox(width: 6),
        Text('Vérification...',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
      ]);
    }
    if (emailStatus == 'found') {
      return Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 11),
        const SizedBox(width: 4),
        Text('Compte trouvé — entrez votre mot de passe',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.green)),
      ]);
    }
    if (emailStatus == 'notfound') {
      return Row(children: [
        Icon(Icons.cancel_outlined, color: Colors.red[400], size: 11),
        const SizedBox(width: 4),
        Text('Aucun compte associé — ',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.red[500])),
        GestureDetector(
          onTap: () => context.go('/register'),
          child: Text("S'inscrire",
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.red[500],
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600)),
        ),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _buildPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_showPassword,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle:
              GoogleFonts.poppins(fontSize: 13, color: Colors.grey[300]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18, color: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600])),
        ),
      ]),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool disabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 15, height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              else
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              if (!isLoading) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── GitHub icon ──
class _GitHubIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B1F23)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.scale(size.width / 98, size.height / 96);
    final path = Path();
    path.moveTo(48.854, 0);
    path.cubicTo(21.839, 0, 0, 22, 0, 49.217);
    path.cubicTo(0, 70.973, 13.993, 89.389, 33.405, 95.907);
    path.cubicTo(35.832, 96.38, 36.721, 94.895, 36.721, 93.616);
    path.cubicTo(36.721, 92.482, 36.675, 88.906, 36.652, 85.001);
    path.cubicTo(23.109, 87.952, 20.25, 79.418, 20.25, 79.418);
    path.cubicTo(18.034, 73.678, 14.822, 72.2, 14.822, 72.2);
    path.cubicTo(10.389, 69.176, 15.154, 69.236, 15.154, 69.236);
    path.cubicTo(20.051, 69.578, 22.626, 74.292, 22.626, 74.292);
    path.cubicTo(26.983, 81.858, 34.027, 79.655, 36.812, 78.44);
    path.cubicTo(37.254, 75.281, 38.514, 73.082, 39.905, 71.841);
    path.cubicTo(29.075, 70.584, 17.693, 66.428, 17.693, 47.287);
    path.cubicTo(17.693, 41.861, 19.604, 37.407, 22.724, 33.924);
    path.cubicTo(22.227, 32.668, 20.554, 27.575, 23.191, 20.701);
    path.cubicTo(23.191, 20.701, 27.271, 19.364, 36.598, 25.843);
    path.cubicTo(40.549, 24.741, 44.714, 24.189, 48.854, 24.171);
    path.cubicTo(52.994, 24.189, 57.161, 24.741, 61.12, 25.843);
    path.cubicTo(70.437, 19.364, 74.511, 20.701, 74.511, 20.701);
    path.cubicTo(77.155, 27.575, 75.481, 32.668, 74.985, 33.924);
    path.cubicTo(78.113, 37.407, 80.013, 41.861, 80.013, 47.287);
    path.cubicTo(80.013, 66.475, 68.61, 70.57, 57.744, 71.797);
    path.cubicTo(59.484, 73.315, 61.036, 76.302, 61.036, 80.918);
    path.cubicTo(61.036, 87.533, 60.976, 92.875, 60.976, 93.616);
    path.cubicTo(60.976, 94.904, 61.852, 96.4, 64.314, 95.9);
    path.cubicTo(83.71, 89.375, 97.708, 70.965, 97.708, 49.217);
    path.cubicTo(97.708, 22, 75.867, 0, 48.854, 0);
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}