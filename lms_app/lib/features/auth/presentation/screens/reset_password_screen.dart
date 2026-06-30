import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String code;
  const ResetPasswordScreen({super.key, required this.email, required this.code});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;
  bool _success = false;
  String _error = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasUppercase => _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _passwordsMatch =>
      _newPasswordController.text == _confirmController.text &&
      _confirmController.text.isNotEmpty;
  bool get _canSubmit =>
      _hasMinLength && _hasUppercase && _hasDigit && _passwordsMatch && !_isLoading;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await ref.read(authProvider.notifier).reinitialiserPassword(
        emailUser: widget.email,
        code: widget.code,
        newPassword: _newPasswordController.text, // ✅ corrigé
      );
      setState(() { _success = true; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccessState();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildBackButton(context),
              const SizedBox(height: 24),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lock_outline_rounded, size: 26, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Text(
                'Nouveau\nmot de passe',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez un mot de passe fort\npour sécuriser votre compte.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[400], height: 1.6),
              ),
              const SizedBox(height: 36),

              _buildLabel('Nouveau mot de passe'),
              const SizedBox(height: 6),
              _buildPasswordField(
                controller: _newPasswordController,
                hint: '••••••••',
                show: _showNew,
                onToggle: () => setState(() => _showNew = !_showNew),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _buildRules(),
              const SizedBox(height: 20),

              _buildLabel('Confirmer le mot de passe'),
              const SizedBox(height: 6),
              _buildPasswordField(
                controller: _confirmController,
                hint: '••••••••',
                show: _showConfirm,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
                onChanged: (_) => setState(() {}),
                borderColor: _confirmController.text.isNotEmpty
                    ? (_passwordsMatch ? Colors.green : Colors.red[300]!)
                    : Colors.grey[200]!,
                suffixIcon: _confirmController.text.isNotEmpty
                    ? Icon(
                        _passwordsMatch
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 18,
                        color: _passwordsMatch ? Colors.green : Colors.red[400],
                      )
                    : null,
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildErrorBox(_error),
              ],

              const SizedBox(height: 28),
              _buildPrimaryButton(
                label: _isLoading ? 'Réinitialisation...' : 'Réinitialiser',
                icon: Icons.check_rounded,
                disabled: !_canSubmit,
                isLoading: _isLoading,
                onTap: _resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 36, color: Colors.green[600]),
                ),
                const SizedBox(height: 24),
                Text(
                  'Mot de passe\nréinitialisé !',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Vous allez être redirigé vers la\npage de connexion...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[400], height: 1.6),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRules() {
    return Column(
      children: [
        _buildRule('Au moins 8 caractères', _hasMinLength),
        const SizedBox(height: 6),
        _buildRule('Au moins une majuscule', _hasUppercase),
        const SizedBox(height: 6),
        _buildRule('Au moins un chiffre', _hasDigit),
      ],
    );
  }

  Widget _buildRule(String label, bool valid) {
    return Row(children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          valid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          key: ValueKey(valid),
          size: 14,
          color: valid ? Colors.green : Colors.grey[400],
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: valid ? Colors.green : Colors.grey[400],
        ),
      ),
    ]);
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
    Color? borderColor,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: !show,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[300]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffixIcon ??
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login');
        }
      },
      child: Container(
        child: Icon(Icons.chevron_left, size: 40),
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
                  width: 15,
                  height: 15,
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