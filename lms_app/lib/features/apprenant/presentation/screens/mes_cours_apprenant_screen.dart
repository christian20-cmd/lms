import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:LMS/features/apprenant/providers/apprenant_provider.dart';
import 'package:LMS/core/network/dio_client.dart';

// ══════════════════════════════════════════════════════════════
//  DESIGN TOKENS — fidèle à l'image de référence
// ══════════════════════════════════════════════════════════════
class _C {
  static const bg           = Color(0xFFF7F7F9);   // fond gris très clair
  static const card         = Colors.white;
  static const ink          = Color(0xFF1A1A2E);   // noir profond
  static const muted        = Color(0xFF9090A0);   // gris texte secondaire
  static const hint         = Color(0xFFBBBBCC);   // placeholder
  static const border       = Color(0xFFEEEEF3);
  static const accent       = Color(0xFF000000);   // violet de l'image (pill sélectionné)
  static const accentSoft   = Color(0xFFEEEDFE);
  static const green        = Color(0xFF2EA862);
  static const greenSoft    = Color(0xFFE1F5EE);
  static const searchBg     = Color(0xFFEFEFF4);   // fond search bar
}

// ══════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════
class MesCoursApprenantScreen extends ConsumerStatefulWidget {
  const MesCoursApprenantScreen({super.key});

  @override
  ConsumerState<MesCoursApprenantScreen> createState() =>
      _MesCoursApprenantScreenState();
}

class _MesCoursApprenantScreenState
    extends ConsumerState<MesCoursApprenantScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _entryCtrl.forward();
    });
    _searchCtrl.addListener(() {
      ref.read(rechercheCoursApprenantProvider.notifier).state = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _estTermine(Map<String, dynamic> inscription) =>
      inscription['dateCompletionCours'] != null;

  @override
  Widget build(BuildContext context) {
    final recherche = ref.watch(rechercheCoursApprenantProvider).toLowerCase();
    final filtre    = ref.watch(filtreEtatCoursProvider);
    final coursAsync = ref.watch(mesCoursApprenantProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _entryFade,
        child: SafeArea(
          child: RefreshIndicator(
            color: _C.accent,
            onRefresh: () async {
              ref.invalidate(mesCoursApprenantProvider);
              await ref.read(mesCoursApprenantProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                // ── Titre + bouton explorer ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mes cours',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: _C.ink,
                            )),
                        
                      ],
                    ),
                  ),
                ),

                // ── Search bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _C.searchBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.outfit(
                            fontSize: 14, color: _C.ink),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un cours...',
                          hintStyle: GoogleFonts.outfit(
                              fontSize: 14, color: _C.hint),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: _C.muted, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Filtres pills ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _Pill(label: 'Tous',     selected: filtre == 'tous',
                              onTap: () => ref.read(filtreEtatCoursProvider.notifier).state = 'tous'),
                          const SizedBox(width: 8),
                          _Pill(label: 'En cours', selected: filtre == 'en_cours',
                              onTap: () => ref.read(filtreEtatCoursProvider.notifier).state = 'en_cours'),
                          const SizedBox(width: 8),
                          _Pill(label: 'Terminés', selected: filtre == 'termines',
                              onTap: () => ref.read(filtreEtatCoursProvider.notifier).state = 'termines'),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Liste ──
                SliverToBoxAdapter(
                  child: coursAsync.when(
                    data: (inscriptions) {
                      final filtered = inscriptions.where((i) {
                        final cours = i['cours'] as Map<String, dynamic>? ?? {};
                        final titre = (cours['titreCours'] as String? ?? '').toLowerCase();
                        if (recherche.isNotEmpty && !titre.contains(recherche)) return false;
                        if (filtre == 'en_cours') return !_estTermine(i);
                        if (filtre == 'termines') return _estTermine(i);
                        return true;
                      }).toList();

                      if (filtered.isEmpty) return _EmptyState();

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: filtered.map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _CoursCard(
                              inscription: i,
                              estTermine: _estTermine(i),
                            ),
                          )).toList(),
                        ),
                      );
                    },
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[50]!,
                        child: Column(
                          children: List.generate(4, (_) => Container(
                            height: 90,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          )),
                        ),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: Center(
                        child: Text(
                          err.toString().replaceAll('Exception: ', ''),
                          style: GoogleFonts.outfit(color: _C.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PILL FILTRE — style image : violet plein si sélectionné,
//  blanc avec bordure sinon
// ══════════════════════════════════════════════════════════════
class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF000000)   // ← violet forcé
              : const Color(0xFFFFFFFF),  // ← blanc forcé
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFF000000)
                : const Color(0xFFE0E0E8),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? const Color(0xFFFFFFFF)  // ← blanc sur violet
                : const Color(0xFF9090A0), // ← gris sur blanc
          ),
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════
//  COURS CARD — image arrondie à gauche, titre + sous-titre +
//  badge à droite, fidèle au style de l'image
// ══════════════════════════════════════════════════════════════
class _CoursCard extends StatelessWidget {
  final Map<String, dynamic> inscription;
  final bool estTermine;
  const _CoursCard({required this.inscription, required this.estTermine});

  @override
  Widget build(BuildContext context) {
    final cours      = inscription['cours'] as Map<String, dynamic>? ?? {};
    final imageUrl   = cours['imageCouvertureCours'] as String?;
    final titre      = cours['titreCours'] as String? ?? 'Sans titre';
    final totalMod   = cours['_count']?['modules'] ?? 0;
    final enseignant = cours['enseignant'] as Map<String, dynamic>?;
    final nomEns     = enseignant != null
        ? '${enseignant['user']?['prenomUser'] ?? ''} ${enseignant['user']?['nomUser'] ?? ''}'.trim()
        : 'Enseignant';

    return GestureDetector(
      onTap: () => context.go('/apprenant/cours/${cours['idCours']}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _C.border, width: 0.8),
        ),
        child: Row(
          children: [
            // ── Image avec coins arrondis (full) ──
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 72,
                height: 72,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '${DioClient.baseUrl}$imageUrl',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ThumbPlaceholder(titre: titre),
                        errorWidget: (_, __, ___) => _ThumbPlaceholder(titre: titre),
                      )
                    : _ThumbPlaceholder(titre: titre),
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
                  const SizedBox(height: 4),
                  Text(
                    'Par $nomEns · $totalMod modules',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: _C.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Badge statut
                  Row(
                    children: [
                      _StatusBadge(estTermine: estTermine),
                    ],
                  ),
                ],
              ),
            ),

            // ── Chevron ──
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: _C.hint),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder thumbnail avec initiale ──
class _ThumbPlaceholder extends StatelessWidget {
  final String titre;
  const _ThumbPlaceholder({required this.titre});

  @override
  Widget build(BuildContext context) {
    final initiale = titre.isNotEmpty ? titre[0].toUpperCase() : 'C';
    return Container(
      color: _C.accentSoft,
      child: Center(
        child: Text(
          initiale,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _C.accent,
          ),
        ),
      ),
    );
  }
}

// ── Badge statut ──
class _StatusBadge extends StatelessWidget {
  final bool estTermine;
  const _StatusBadge({required this.estTermine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: estTermine ? _C.greenSoft : _C.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estTermine ? Icons.check_circle_rounded : Icons.play_circle_rounded,
            size: 11,
            color: estTermine ? _C.green : _C.accent,
          ),
          const SizedBox(width: 4),
          Text(
            estTermine ? 'Terminé' : 'En cours',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: estTermine ? _C.green : _C.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.school_outlined,
                  size: 32, color: _C.accent),
            ),
            const SizedBox(height: 16),
            Text('Aucun cours trouvé',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _C.ink,
                )),
            const SizedBox(height: 6),
            Text('Explorez le catalogue pour commencer',
                style: GoogleFonts.outfit(fontSize: 13, color: _C.muted)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.go('/apprenant/catalogue'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _C.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Explorer le catalogue',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}