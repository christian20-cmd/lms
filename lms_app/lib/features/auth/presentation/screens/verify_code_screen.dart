import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class VerifyResetCodeScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyResetCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyResetCodeScreen> createState() =>
      _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends ConsumerState<VerifyResetCodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String _error = '';
  int _countdown = 60;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }  // ✅ accolades ajoutées
    for (final f in _focusNodes) { f.dispose(); }   // ✅ accolades ajoutées
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {       // ✅ accolades ajoutées
          _countdown--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() { _error = ''; });
    if (_code.length == 6) _verifier();
  }

  // ✅ RawKeyEvent → KeyEvent, RawKeyDownEvent → KeyDownEvent
  void _onKey(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  Future<void> _verifier() async {
    if (_code.length < 6 || _isLoading) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await ref.read(authProvider.notifier).verifierCodeReset(
        emailUser: widget.email,
        code: _code,
      );
      if (mounted) {
        context.push('/reset-password', extra: {
          'email': widget.email,
          'code': _code,
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        for (final c in _controllers) { c.clear(); } // ✅ accolades ajoutées
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _renvoyer() async {
    if (!_canResend) return;
    try {
      await ref
          .read(authProvider.notifier)
          .demanderResetPassword(widget.email);
      _startCountdown();
      setState(() { _error = ''; });
      for (final c in _controllers) { c.clear(); } // ✅ accolades ajoutées
      _focusNodes[0].requestFocus();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _masquerEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final visible =
        parts[0].length > 2 ? parts[0].substring(0, 2) : parts[0][0];
    return '$visible***@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildBack(),
              const SizedBox(height: 28),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.mark_email_read_outlined,
                    size: 26, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Text(
                'Vérifiez\nvotre boîte mail',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[400], height: 1.6),
                  children: [
                    const TextSpan(text: 'Code envoyé à '),
                    TextSpan(
                      text: _masquerEmail(widget.email),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                    ),
                    const TextSpan(text: '. Entrez-le ci-dessous.'),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Champs OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildDigit),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildError(_error),
              ],

              const SizedBox(height: 28),
              _buildButton(
                label: _isLoading ? 'Vérification...' : 'Vérifier le code',
                icon: Icons.check_circle_outline,
                disabled: _code.length < 6 || _isLoading,
                isLoading: _isLoading,
                onTap: _verifier,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _canResend ? _renvoyer : null,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey[400]),
                      children: [
                        const TextSpan(text: 'Pas reçu ? '),
                        _canResend
                            ? TextSpan(
                                text: 'Renvoyer',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black),
                              )
                            : TextSpan(
                                text: 'Renvoyer dans ${_countdown}s',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.grey[400]),
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

  Widget _buildDigit(int index) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (e) => _onKey(e, index), // ✅ onKeyEvent (nouveau nom)
      child: SizedBox(
        width: 46,
        height: 56,
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => _onChanged(v, index),
          style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _controllers[index].text.isNotEmpty
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.grey[100],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _error.isNotEmpty
                    ? Colors.red[300]!
                    : Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() => GestureDetector(
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

  Widget _buildError(String msg) => Container(
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
              msg,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]),
            ),
          ),
        ]),
      );

  Widget _buildButton({
    required String label,
    required IconData icon,
    required bool disabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) =>
      GestureDetector(
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