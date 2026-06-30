import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LMS/features/enseignant/presentation/providers/enseignant_provider.dart';
import 'package:LMS/features/enseignant/data/enseignant_remote_datasource.dart';
import 'package:LMS/features/enseignant/presentation/screens/categories_management_screen.dart';
import 'package:LMS/features/auth/presentation/providers/auth_provider.dart';
import 'package:LMS/features/auth/presentation/screens/login_screen.dart';

// ══════════════════════════════════════════════════════════════
//  DESIGN TOKENS — cohérent avec Connexion.jsx / Inscription
// ══════════════════════════════════════════════════════════════
class _C {
  static const ink     = Color(0xFF000000);
  static const bg      = Color(0xFFF3F4F6);
  static const surface = Colors.white;
  static const border  = Color(0xFFE5E7EB);
  static const muted   = Color(0xFF6B7280);
  static const mutedLt = Color(0xFF9CA3AF);
  static const green   = Color(0xFF16A34A);
  static const red     = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFEF2F2);
}

// Adapte selon ta plateforme de test (localhost web, IP réseau mobile…)
const String _kBaseUrl = 'http://localhost:3000';

class ProfilEnseignantScreen extends ConsumerWidget {
  const ProfilEnseignantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilEnseignantProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: profilAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: _C.ink),
          ),
          error: (e, _) => Center(
            child: Text('Erreur de chargement',
                style: GoogleFonts.poppins(fontSize: 13, color: _C.muted)),
          ),
          data: (p) {
            final user = p;
            final enseignant = user['enseignant'];
            final photo = user['photoProfilUser'];
            final nom = user['nomUser'] ?? '';
            final prenom = user['prenomUser'] ?? '';
            final email = user['emailUser'] ?? '';
            final bio = user['bioUser'] ?? '';
            final tel = user['numeroTelUser'] ?? '';

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Titre ──
                  Text('Mon profil',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: _C.ink,
                      )),
                  const SizedBox(height: 4),
                  Text('Gérez vos informations personnelles',
                      style: GoogleFonts.poppins(fontSize: 13, color: _C.mutedLt)),
                  const SizedBox(height: 28),

                  // ── Header avatar + nom ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: _C.bg,
                        backgroundImage: photo != null
                            ? NetworkImage('$_kBaseUrl$photo') as ImageProvider
                            : null,
                        child: photo == null
                            ? Text(
                                (nom.isNotEmpty ? nom[0] : '?').toUpperCase(),
                                style: GoogleFonts.playfairDisplay(
                                    fontSize: 26,
                                    fontStyle: FontStyle.italic,
                                    color: _C.mutedLt),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$prenom $nom',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, fontWeight: FontWeight.w600, color: _C.ink)),
                            const SizedBox(height: 2),
                            Text(email,
                                style: GoogleFonts.poppins(fontSize: 12, color: _C.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Actions secondaires ──
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          label: 'Modifier',
                          icon: Icons.edit_outlined,
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _EditProfileSheet(profil: user),
                            );
                            ref.invalidate(profilEnseignantProvider);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SecondaryButton(
                          label: 'Catégories',
                          icon: Icons.category_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CategoriesManagementScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── À propos ──
                  _SectionLabel('À propos'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    text: bio.isNotEmpty ? bio : 'Aucune description',
                    isPlaceholder: bio.isEmpty,
                  ),

                  const SizedBox(height: 22),

                  // ── Contact ──
                  _SectionLabel('Contact'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    icon: Icons.phone_outlined,
                    text: tel.isNotEmpty ? tel : 'Non renseigné',
                    isPlaceholder: tel.isEmpty,
                  ),

                  const SizedBox(height: 22),

                  // ── Informations enseignant ──
                  _SectionLabel('Informations enseignant'),
                  const SizedBox(height: 8),

                  if (enseignant != null) ...[
                    _InfoCard(
                      icon: Icons.school_outlined,
                      text: 'Spécialité : ${enseignant['specialiteEnseignant'] ?? 'Non renseignée'}',
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(
                      icon: Icons.badge_outlined,
                      text: 'Titre : ${enseignant['titreProfessionnelEnseignant'] ?? 'Non renseigné'}',
                    ),

                    const SizedBox(height: 18),
                    _SectionLabel('Réseaux sociaux'),
                    const SizedBox(height: 8),

                    ...((enseignant['reseauxSociaux'] as List<dynamic>?)?.map(
                          (rs) => _SocialRow(item: rs),
                        ) ??
                        [
                          _InfoCard(
                            text: 'Aucun réseau social',
                            isPlaceholder: true,
                          ),
                        ]),

                    const SizedBox(height: 12),
                    _SecondaryButton(
                      label: 'Ajouter un réseau social',
                      icon: Icons.add_link_rounded,
                      fullWidth: true,
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const _AddSocialSheet(),
                        );
                        ref.invalidate(profilEnseignantProvider);
                      },
                    ),
                  ] else
                    _InfoCard(
                      text: 'Profil enseignant non complété',
                      isPlaceholder: true,
                    ),

                  const SizedBox(height: 40),

                  // ── Déconnexion — isolée en bas, bien visible ──
                  Divider(color: _C.border),
                  const SizedBox(height: 20),
                  _LogoutButton(
                    onTap: () => _confirmerDeconnexion(context, ref),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmerDeconnexion(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Déconnexion',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?',
            style: GoogleFonts.poppins(fontSize: 13, color: _C.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Annuler',
                style: GoogleFonts.poppins(fontSize: 13, color: _C.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Déconnecter',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _C.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  WIDGETS PARTAGÉS — design système du projet
// ══════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink));
}

class _InfoCard extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isPlaceholder;

  const _InfoCard({required this.text, this.icon, this.isPlaceholder = false});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: _C.mutedLt),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(text,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isPlaceholder ? _C.mutedLt : _C.ink,
                    fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
                  )),
            ),
          ],
        ),
      );
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: _C.ink),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500, color: _C.ink)),
            ],
          ),
        ),
      );
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _C.redSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.red.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 16, color: _C.red),
              const SizedBox(width: 8),
              Text('Déconnexion',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _C.red)),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  EDIT PROFILE SHEET
// ══════════════════════════════════════════════════════════════
class _EditProfileSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> profil;
  const _EditProfileSheet({required this.profil});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _specialiteCtrl;
  late TextEditingController _titreCtrl;
  bool _loading = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final p = widget.profil;
    _nomCtrl = TextEditingController(text: p['nomUser'] ?? '');
    _prenomCtrl = TextEditingController(text: p['prenomUser'] ?? '');
    _bioCtrl = TextEditingController(text: p['bioUser'] ?? '');
    _telCtrl = TextEditingController(text: p['numeroTelUser'] ?? '');
    final enseignant = p['enseignant'];
    _specialiteCtrl = TextEditingController(text: enseignant?['specialiteEnseignant'] ?? '');
    _titreCtrl = TextEditingController(text: enseignant?['titreProfessionnelEnseignant'] ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _bioCtrl.dispose();
    _telCtrl.dispose();
    _specialiteCtrl.dispose();
    _titreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final datasource = ref.read(enseignantDatasourceProvider);
      await datasource.modifierProfil(
        nomUser: _nomCtrl.text.trim(),
        prenomUser: _prenomCtrl.text.trim(),
        bioUser: _bioCtrl.text.trim(),
        numeroTelUser: _telCtrl.text.trim(),
      );
      await datasource.modifierProfilEnseignant(
        specialiteEnseignant: _specialiteCtrl.text.trim().isEmpty ? null : _specialiteCtrl.text.trim(),
        titreProfessionnelEnseignant:
            _titreCtrl.text.trim().isEmpty ? null : _titreCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erreur = 'Erreur lors de la sauvegarde');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Text('Modifier le profil',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22, fontStyle: FontStyle.italic, color: _C.ink)),
            const SizedBox(height: 16),
            if (_erreur != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.redSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_erreur!,
                    style: GoogleFonts.poppins(fontSize: 12, color: _C.red)),
              ),
              const SizedBox(height: 12),
            ],
            _FieldLabel('Nom'),
            _StyledField(controller: _nomCtrl),
            const SizedBox(height: 12),
            _FieldLabel('Prénom'),
            _StyledField(controller: _prenomCtrl),
            const SizedBox(height: 12),
            _FieldLabel('Bio'),
            _StyledField(controller: _bioCtrl, maxLines: 3),
            const SizedBox(height: 12),
            _FieldLabel('Téléphone'),
            _StyledField(controller: _telCtrl),
            const SizedBox(height: 12),
            _FieldLabel('Spécialité'),
            _StyledField(controller: _specialiteCtrl),
            const SizedBox(height: 12),
            _FieldLabel('Titre professionnel'),
            _StyledField(controller: _titreCtrl),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: _loading ? 'Enregistrement...' : 'Enregistrer',
              loading: _loading,
              onTap: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SOCIAL ROW
// ══════════════════════════════════════════════════════════════
class _SocialRow extends ConsumerWidget {
  final Map<String, dynamic> item;
  const _SocialRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['plateformeRS'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _C.ink)),
                const SizedBox(height: 2),
                Text(item['lienRS'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 11, color: _C.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              try {
                await ref.read(enseignantDatasourceProvider).supprimerReseauSocial(item['idReseauxSociaux']);
                ref.invalidate(profilEnseignantProvider);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur suppression', style: GoogleFonts.poppins(fontSize: 12))),
                  );
                }
              }
            },
            child: Icon(Icons.delete_outline, size: 18, color: _C.red),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ADD SOCIAL SHEET
// ══════════════════════════════════════════════════════════════
class _AddSocialSheet extends ConsumerStatefulWidget {
  const _AddSocialSheet({super.key});

  @override
  ConsumerState<_AddSocialSheet> createState() => _AddSocialSheetState();
}

class _AddSocialSheetState extends ConsumerState<_AddSocialSheet> {
  final _plat = TextEditingController();
  final _lien = TextEditingController();
  bool _loading = false;
  String? _erreur;

  @override
  void dispose() {
    _plat.dispose();
    _lien.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final plat = _plat.text.trim();
    final lien = _lien.text.trim();
    if (plat.isEmpty || lien.isEmpty) {
      setState(() => _erreur = 'Tous les champs sont obligatoires');
      return;
    }
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      await ref.read(enseignantDatasourceProvider).ajouterReseauSocial(
            plateformeRS: plat,
            lienRS: lien,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erreur = 'Erreur lors de l\'ajout');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Text('Ajouter un réseau social',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22, fontStyle: FontStyle.italic, color: _C.ink)),
            const SizedBox(height: 16),
            if (_erreur != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.redSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_erreur!,
                    style: GoogleFonts.poppins(fontSize: 12, color: _C.red)),
              ),
              const SizedBox(height: 12),
            ],
            _FieldLabel('Plateforme'),
            _StyledField(controller: _plat, hint: 'Ex: LinkedIn, Twitter...'),
            const SizedBox(height: 12),
            _FieldLabel('Lien'),
            _StyledField(controller: _lien, hint: 'https://...'),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: _loading ? 'Ajout...' : 'Ajouter',
              loading: _loading,
              onTap: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FORM HELPERS
// ══════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w500, color: _C.muted)),
      );
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final int maxLines;

  const _StyledField({required this.controller, this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13, color: _C.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: _C.mutedLt),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton({required this.label, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _C.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      );
}