import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class OAuthScreen extends ConsumerStatefulWidget {
  final Map<String, String> queryParams;

  const OAuthScreen({super.key, required this.queryParams});

  @override
  ConsumerState<OAuthScreen> createState() => _OAuthScreenState();
}

class _OAuthScreenState extends ConsumerState<OAuthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleOAuth());
  }

  Future<void> _handleOAuth() async {
    final params = widget.queryParams;

    if (params['error'] == 'true') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la connexion OAuth',
                style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/login');
      }
      return;
    }

    final token = params['token'];
    final idUser = params['idUser'];
    final nomUser = params['nomUser'] ?? '';
    final prenomUser = params['prenomUser'] ?? '';
    final emailUser = params['emailUser'] ?? '';
    final roleUser = params['roleUser'] ?? 'APPRENANT';
    final photoProfilUser = params['photoProfilUser'];
    final isNewUser = params['isNewUser'] == 'true';

    if (token == null || idUser == null) {
      if (mounted) context.go('/login');
      return;
    }

    await ref.read(authProvider.notifier).connecterOAuth(
      token: token,
      idUser: idUser,
      nomUser: nomUser,
      prenomUser: prenomUser,
      emailUser: emailUser,
      roleUser: roleUser,
      photoProfilUser: photoProfilUser,
    );

    if (!mounted) return;

    if (isNewUser) {
      context.go('/complete-profile', extra: {
        'nomUser': nomUser,
        'prenomUser': prenomUser,
        'emailUser': emailUser,
        'photoProfilUser': photoProfilUser,
      });
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Connexion en cours...',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}