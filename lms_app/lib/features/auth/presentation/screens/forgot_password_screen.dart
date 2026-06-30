import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

// Provider pour le statut de vérification de l'email
final forgotEmailStatusProvider = StateProvider<String>((ref) => 'idle');
// idle | checking | found | notfound

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _error = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _emailController.dispose();
    // Réinitialiser le statut à la sortie de l'écran
    ref.read(forgotEmailStatusProvider.notifier).state = 'idle';
    super.dispose();
  }

  // ── Vérification email avec debounce (700ms) ──
  void _onEmailChanged(String val) {
    _debounceTimer?.cancel();
    final trimmed = val.trim();
    setState(() { _error = ''; });

    // Format email basique requis avant de vérifier
    if (!trimmed.contains('@') || !trimmed.contains('.') || trimmed.length < 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(forgotEmailStatusProvider.notifier).state = 'idle';
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(forgotEmailStatusProvider.notifier).state = 'checking';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_emailController.text.trim() == trimmed) _verifierEmail(trimmed);
    });
  }

  Future<void> _verifierEmail(String email) async {
    if (!mounted) return;
    try {
      await ref.read(authProvider.notifier).verifierEmailLogin(email);
      if (mounted) ref.read(forgotEmailStatusProvider.notifier).state = 'found';
    } catch (_) {
      if (mounted) ref.read(forgotEmailStatusProvider.notifier).state = 'notfound';
    }
  }

  // ── Envoi du code de réinitialisation ──
  Future<void> _envoyerCode() async {
    final emailStatus = ref.read(forgotEmailStatusProvider);
    if (emailStatus != 'found') return;

    setState(() { _isLoading = true; _error = ''; });
    try {
      await ref.read(authProvider.notifier).demanderResetPassword(
        _emailController.text.trim(),
      );
      if (mounted) {
        context.push('/verify-reset-code', extra: _emailController.text.trim());
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailStatus = ref.watch(forgotEmailStatusProvider);
    final canSubmit = emailStatus == 'found' && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildBackButton(),
              const SizedBox(height: 24),

              // ── Icône ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lock_reset_rounded, size: 26, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              // ── Titre ──
              Text(
                'Mot de passe\noublié ?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Entrez votre adresse email pour\nrecevoir un code de réinitialisation.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[400], height: 1.6),
              ),
              const SizedBox(height: 36),

              // ── Champ email ──
              _buildLabel('Adresse email'),
              const SizedBox(height: 6),
              _buildEmailInput(emailStatus),
              const SizedBox(height: 6),
              _buildEmailIndicator(emailStatus),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildErrorBox(_error),
              ],

              const SizedBox(height: 28),

              // ── Bouton envoi ──
              _buildPrimaryButton(
                label: _isLoading ? 'Envoi en cours...' : 'Recevoir le code',
                icon: Icons.send_rounded,
                disabled: !canSubmit,
                isLoading: _isLoading,
                onTap: _envoyerCode,
              ),

              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey[400]),
                      children: [
                        const TextSpan(text: 'Vous vous souvenez ? '),
                        TextSpan(
                          text: 'Se connecter',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
      ),
    );
  }

  // ── Widgets ──

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login'); // fallback si pas de stack
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.chevron_left, size: 20, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]),
    );
  }

  Widget _buildEmailInput(String emailStatus) {
    Color borderColor = Colors.grey[200]!;
    if (emailStatus == 'found') borderColor = Colors.green;
    if (emailStatus == 'notfound') borderColor = Colors.red[300]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: _onEmailChanged,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'exemple@email.com',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[300]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: _buildEmailSuffixIcon(emailStatus),
        ),
      ),
    );
  }

  Widget? _buildEmailSuffixIcon(String emailStatus) {
    switch (emailStatus) {
      case 'checking':
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
          ),
        );
      case 'found':
        return const Icon(Icons.check_circle_outline, color: Colors.green, size: 18);
      case 'notfound':
        return Icon(Icons.cancel_outlined, color: Colors.red[400], size: 18);
      default:
        return null;
    }
  }

  Widget _buildEmailIndicator(String emailStatus) {
    switch (emailStatus) {
      case 'checking':
        return Row(children: [
          const SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
          ),
          const SizedBox(width: 6),
          Text('Vérification...',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
        ]);

      case 'found':
        return Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 11),
          const SizedBox(width: 4),
          Text(
            'Compte trouvé — vous pouvez recevoir le code',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.green),
          ),
        ]);

      case 'notfound':
        return Row(children: [
          Icon(Icons.cancel_outlined, color: Colors.red[400], size: 11),
          const SizedBox(width: 4),
          Text('Aucun compte associé à cet email',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.red[500])),
        ]);

      default:
        return const SizedBox.shrink();
    }
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
          child: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]),
          ),
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
              else ...[
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
                const SizedBox(width: 6),
                Icon(icon, size: 15, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}