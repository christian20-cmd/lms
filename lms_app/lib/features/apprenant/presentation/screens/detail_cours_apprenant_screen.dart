import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:LMS/features/apprenant/providers/apprenant_provider.dart';
import 'package:LMS/core/network/dio_client.dart';

// ══════════════════════════════════════════════════════════════
//  DESIGN TOKENS — même palette que mes_cours_apprenant_screen
// ══════════════════════════════════════════════════════════════
class _C {
  static const bg         = Color(0xFFF7F7F9);
  static const card       = Colors.white;
  static const ink        = Color(0xFF1A1A2E);
  static const muted      = Color(0xFF9090A0);
  static const hint       = Color(0xFFBBBBCC);
  static const border     = Color(0xFFEEEEF3);
  static const accent     = Color(0xFF5B5BD6);
  static const accentSoft = Color(0xFFEEEDFE);
  static const green      = Color(0xFF2EA862);
  static const greenSoft  = Color(0xFFE1F5EE);
  static const amber      = Color(0xFFEA9F25);
  static const amberSoft  = Color(0xFFFEF5E7);
}

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════
class DetailCoursApprenantScreen extends ConsumerStatefulWidget {
  final String idCours;
  const DetailCoursApprenantScreen({super.key, required this.idCours});

  @override
  ConsumerState<DetailCoursApprenantScreen> createState() =>
      _DetailCoursApprenantScreenState();
}

class _DetailCoursApprenantScreenState
    extends ConsumerState<DetailCoursApprenantScreen> {
  bool _inscriptionEnCours = false;

  Future<void> _confirmerInscription(Map<String, dynamic> cours) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("S'inscrire à ce cours ?",
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: _C.ink)),
        content: Text(
          cours['estGratuitCours'] == true
              ? 'Ce cours est gratuit. Vous y aurez accès immédiatement.'
              : 'Ce cours est payant (${cours['prixCours'] ?? 0} Ar). '
                'Votre inscription sera en attente de paiement.',
          style: GoogleFonts.outfit(fontSize: 13, color: _C.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.outfit(color: _C.muted)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _C.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("S'inscrire",
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _inscriptionEnCours = true);
    try {
      await ref.read(apprenantActionsProvider.notifier).sInscrire(widget.idCours);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Inscription réussie !', style: GoogleFonts.outfit()),
          backgroundColor: _C.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _inscriptionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursAsync      = ref.watch(detailCoursApprenantProvider(widget.idCours));
    final estInscritAsync = ref.watch(estInscritProvider(widget.idCours));

    return Scaffold(
      backgroundColor: _C.bg,
      body: coursAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: _C.accent)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(err.toString().replaceAll('Exception: ', ''),
                  style: GoogleFonts.outfit(color: _C.muted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _AccentButton(label: 'Retour', onTap: () => context.pop()),
            ],
          ),
        ),
        data: (cours) => CustomScrollView(
          slivers: [
            // ── Header image ──
            _buildHeader(cours),

            // ── Inscription ou Progression ──
            SliverToBoxAdapter(
              child: estInscritAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: _C.accent, strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (estInscrit) => estInscrit
                    ? _buildProgressionSection()
                    : _buildInscriptionPrompt(cours),
              ),
            ),

            // ── Section titre modules ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 18,
                      decoration: BoxDecoration(
                        color: _C.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Contenu du cours',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _C.ink,
                        )),
                  ],
                ),
              ),
            ),

            // ── Liste modules ──
            SliverToBoxAdapter(
              child: estInscritAsync.maybeWhen(
                data: (estInscrit) => estInscrit
                    ? _buildModulesList()
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _C.accentSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded,
                                  size: 18, color: _C.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Inscrivez-vous pour accéder au contenu',
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: _C.accent,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  HEADER — image plein écran avec overlay dégradé
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader(Map<String, dynamic> cours) {
    final imageUrl   = cours['imageCouvertureCours'] as String?;
    final enseignant = cours['enseignant'] as Map<String, dynamic>?;
    final nomEns     = '${enseignant?['user']?['prenomUser'] ?? ''} '
        '${enseignant?['user']?['nomUser'] ?? 'Enseignant'}'.trim();
    final niveauCours = cours['niveauCours'] as String? ?? '';

    return SliverAppBar(
      backgroundColor: _C.ink,
      elevation: 0,
      pinned: true,
      expandedHeight: 240,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: Colors.white),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de couverture
            imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: '${DioClient.baseUrl}$imageUrl',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: _C.accent),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.accent, const Color(0xFF3B3BAA)],
                      ),
                    ),
                  ),
            // Overlay dégradé bas
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),
            // Texte titre + auteur
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (niveauCours.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        niveauCours,
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  Text(
                    cours['titreCours'] ?? 'Sans titre',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Avatar enseignant
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Par $nomEns',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  INSCRIPTION PROMPT
  // ══════════════════════════════════════════════════════════
  Widget _buildInscriptionPrompt(Map<String, dynamic> cours) {
    final estGratuit = cours['estGratuitCours'] == true;
    final prix       = cours['prixCours'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Non inscrit",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.muted,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: estGratuit ? _C.greenSoft : _C.amberSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    estGratuit ? 'Gratuit' : '${prix ?? 0} Ar',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: estGratuit ? _C.green : _C.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _inscriptionEnCours
                    ? null
                    : () => _confirmerInscription(cours),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _inscriptionEnCours
                        ? const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.5)
                        : const Color.fromARGB(255, 12, 12, 26),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _inscriptionEnCours
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text("S'inscrire au cours",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            )),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PROGRESSION
  // ══════════════════════════════════════════════════════════
  Widget _buildProgressionSection() {
    final progressionAsync = ref.watch(progressionCoursProvider(widget.idCours));

    return progressionAsync.when(
      loading: () => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          height: 110,
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (progression) {
        final pct   = (progression['pourcentage'] as num?)?.toInt() ?? 0;
        final done  = progression['modulesTermines'] ?? 0;
        final total = progression['totalModules'] ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Container(
            
            
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Votre progression',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.ink,
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: pct >= 100 ? _C.greenSoft : _C.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$pct%',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: pct >= 100 ? _C.green : _C.accent,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 4,
                    backgroundColor: _C.border,
                    valueColor: AlwaysStoppedAnimation(
                        pct >= 100 ? _C.green : const Color.fromARGB(255, 0, 0, 0)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$done sur $total modules terminés',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: _C.muted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MODULES LIST
  // ══════════════════════════════════════════════════════════
  Widget _buildModulesList() {
    final modulesAsync = ref.watch(modulesCourProvider(widget.idCours));

    return modulesAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Column(
            children: List.generate(3, (_) => Container(
              height: 76,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 175, 166, 166),
                  borderRadius: BorderRadius.circular(999)),
            )),
          ),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Text(err.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.outfit(color: const Color.fromARGB(255, 0, 0, 0))),
      ),
      data: (modules) {
        if (modules.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text('Aucun module disponible',
                style: GoogleFonts.outfit(color: _C.muted)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(
              modules.length,
              (i) => _ModuleItem(
                module: modules[i],
                idCours: widget.idCours,
                index: i + 1,
                isLast: i == modules.length - 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MODULE ITEM — même style carte que mes_cours_apprenant
// ══════════════════════════════════════════════════════════════
class _ModuleItem extends StatelessWidget {
  final Map<String, dynamic> module;
  final String idCours;
  final int index;
  final bool isLast;
  const _ModuleItem({
    required this.module,
    required this.idCours,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final estPublie      = module['statutModule'] == 'PUBLIE';
    final nombreContenus = module['_count']?['contenus'] ?? 0;
    final titre          = module['titreModule'] as String? ?? 'Sans titre';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Opacity(
        opacity: estPublie ? 1.0 : 0.45,
        child: GestureDetector(
          onTap: estPublie
              ? () => context.go(
                  '/apprenant/cours/$idCours/module/${module['idModule']}')
              : null,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _C.border, width: 0.8),
            ),
            child: Row(
              children: [
                // ── Numéro du module (cercle violet) ──
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: estPublie ? _C.accentSoft : const Color(0xFFEEEEF3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: estPublie ? _C.accent : _C.hint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Infos ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            estPublie
                                ? Icons.play_lesson_rounded
                                : Icons.lock_outline_rounded,
                            size: 12,
                            color: estPublie ? _C.muted : _C.hint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            estPublie
                                ? '$nombreContenus contenu${nombreContenus > 1 ? 's' : ''}'
                                : 'Non disponible',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: _C.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Chevron si disponible ──
                if (estPublie)
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: _C.hint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ACCENT BUTTON
// ══════════════════════════════════════════════════════════════
class _AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AccentButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _C.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
      ),
    );
  }
}