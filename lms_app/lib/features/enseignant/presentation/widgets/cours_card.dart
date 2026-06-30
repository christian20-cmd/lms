import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:LMS/features/enseignant/presentation/screens/cours_detail_screen.dart';
import 'package:LMS/features/enseignant/presentation/providers/cours_provider.dart';

// ── Design tokens ──────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF7F7F5);
  static const surface    = Colors.white;
  static const ink        = Color(0xFF111111);
  static const muted      = Color(0xFF8A8A8A);
  static const faint      = Color(0xFFE8E8E4);
  static const blue       = Color(0xFF2563EB);
  static const blueSoft   = Color(0xFFEFF6FF);
  static const green      = Color(0xFF16A34A);
  static const greenSoft  = Color(0xFFECFDF5);
  static const amber      = Color(0xFFD97706);
  static const amberSoft  = Color(0xFFFFFBEB);
  static const red        = Color(0xFFDC2626);
  static const redSoft    = Color(0xFFFEF2F2);
  static const purple     = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFF5F3FF);
}

// ── Meta par type de contenu ───────────────────────────────────
const _typeMeta = {
  'VIDEO':    (icon: Icons.play_circle_filled_rounded,  color: _C.blue,   soft: _C.blueSoft,   label: 'Vidéo'),
  'DOCUMENT': (icon: Icons.description_rounded,         color: _C.amber,  soft: _C.amberSoft,  label: 'Doc'),
  'IMAGE':    (icon: Icons.image_rounded,               color: _C.purple, soft: _C.purpleSoft, label: 'Image'),
  'TEXTE':    (icon: Icons.article_rounded,             color: _C.green,  soft: _C.greenSoft,  label: 'Texte'),
};

// ══════════════════════════════════════════════════════════════
//  COURS CARD
// ══════════════════════════════════════════════════════════════
class CoursCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> cours;
  final int modulesCount;
  final VoidCallback onEdit;
  final VoidCallback onAddModule;
  final VoidCallback onDelete;

  const CoursCard({
    required this.cours,
    required this.modulesCount,
    required this.onEdit,
    required this.onAddModule,
    required this.onDelete,
    super.key,
  });

  @override
  ConsumerState<CoursCard> createState() => _CoursCardState();
}

class _CoursCardState extends ConsumerState<CoursCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _expandAnim;
  late final Animation<double> _expandCurve;

  @override
  void initState() {
    super.initState();
    _expandAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandCurve = CurvedAnimation(parent: _expandAnim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandAnim.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    _expanded ? _expandAnim.forward() : _expandAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final titre      = widget.cours['titreCours']        ?? 'Cours sans titre';
    final desc       = widget.cours['descriptionCours']  ?? '';
    final statut     = widget.cours['statutCours']       ?? 'BROUILLON';
    final estGratuit = widget.cours['estGratuitCours']   ?? true;
    final prix       = widget.cours['prixCours'];
    final idCours    = widget.cours['idCours']           ?? '';
    final coverUrl   = widget.cours['coverUrl']          as String?;
    final enseignant = widget.cours['enseignant']        as Map<String, dynamic>?;
    final nomEns     = enseignant?['nomEnseignant'] ?? enseignant?['nom'] ?? 'Enseignant';
    final avatarUrl  = enseignant?['avatarUrl']          as String?;
    final isPublie   = statut == 'PUBLIE';
    final duree      = widget.cours['dureeCours']        as String?;
    final niveau     = widget.cours['niveauCours']       as String?;

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.faint),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Cover image ──────────────────────────────────
            _CoverImage(
              coverUrl:   coverUrl,
              isPublie:   isPublie,
              niveau:     niveau,
              estGratuit: estGratuit,
              prix:       prix,
              onEdit:     widget.onEdit,
              onDelete:   widget.onDelete,
            ),

            // ── 2. Titre + description ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.ink,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: _C.muted,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── 3. Instructor + stats ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  _Avatar(avatarUrl: avatarUrl, nom: nomEns),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nomEns,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _C.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Stats compactes
                  _StatChip(icon: Icons.layers_outlined,
                      label: '${widget.modulesCount} mod.'),
                  if (duree != null) ...[
                    const SizedBox(width: 8),
                    _StatChip(icon: Icons.timer_outlined, label: duree),
                  ],
                ],
              ),
            ),

            // ── 4. Aperçu modules (expandable) ──────────────────
            if (widget.modulesCount > 0) ...[
              const Divider(height: 1, color: Color(0xFFF0F0EE)),
              _ModulesPreview(
                idCours:        idCours,
                expanded:       _expanded,
                expandAnimation: _expandCurve,
                onToggle:       _toggleExpand,
              ),
            ],

            // ── 5. Actions ───────────────────────────────────────
            const Divider(height: 1, color: Color(0xFFF0F0EE)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToDetail(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: _C.faint),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_outlined, size: 13, color: _C.muted),
                            const SizedBox(width: 4),
                            Text('Voir', style: GoogleFonts.dmSans(
                              fontSize: 11, fontWeight: FontWeight.w600, color: _C.muted,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onAddModule,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _C.ink,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('Module', style: GoogleFonts.dmSans(
                              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoursDetailScreen(
          idCours:          widget.cours['idCours'],
          titreCours:       widget.cours['titreCours'],
          descriptionCours: widget.cours['descriptionCours'],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  COVER IMAGE — badges: niveau · statut · prix  +  menu
// ══════════════════════════════════════════════════════════════
class _CoverImage extends StatelessWidget {
  final String? coverUrl;
  final bool isPublie;
  final String? niveau;
  final bool estGratuit;
  final dynamic prix;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CoverImage({
    required this.coverUrl,
    required this.isPublie,
    required this.niveau,
    required this.estGratuit,
    required this.prix,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          // ── Image / placeholder ──
          SizedBox(
            height: 130,
            width: double.infinity,
            child: coverUrl != null
                ? Image.network(
                    coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _CoverPlaceholder(isPublie: isPublie),
                  )
                : _CoverPlaceholder(isPublie: isPublie),
          ),

          // ── Gradient bas ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 55,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xBB000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Haut-gauche : badge niveau ──
          if (niveau != null)
            Positioned(
              top: 8, left: 8,
              child: _NiveauBadge(niveau: niveau!),
            ),

          // ── Haut-droite : [badge prix/gratuit] [badge statut] [menu] ──
          Positioned(
            top: 8, right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge prix / gratuit
                _OverlayBadge(
                  label: (!estGratuit && prix != null)
                      ? '${prix.toStringAsFixed(0)} Ar'
                      : 'Gratuit',
                  color: (!estGratuit && prix != null) ? _C.amber : _C.green,
                  icon: (!estGratuit && prix != null)
                      ? Icons.sell_rounded
                      : Icons.card_giftcard_rounded,
                ),
                const SizedBox(width: 5),
                // Badge statut publication
                _OverlayBadge(
                  label: isPublie ? 'Publié' : 'Brouillon',
                  color: isPublie ? _C.blue : _C.muted,
                  icon: isPublie ? Icons.public_rounded : Icons.lock_outline_rounded,
                ),
                const SizedBox(width: 5),
                // Menu
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit')   onEdit();
                    if (v == 'delete') onDelete();
                  },
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: _PopItem(Icons.edit_outlined, 'Modifier'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: _PopItem(Icons.delete_outline, 'Supprimer', color: _C.red),
                    ),
                  ],
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.40),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.more_vert, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge sur l'image (fond semi-transparent) ────────────────
class _OverlayBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _OverlayBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

// ── Cover placeholder ─────────────────────────────────────────
class _CoverPlaceholder extends StatelessWidget {
  final bool isPublie;
  const _CoverPlaceholder({required this.isPublie});

  @override
  Widget build(BuildContext context) => Container(
    height: 130,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isPublie
            ? [const Color(0xFF16A34A), const Color(0xFF047857)]
            : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
      ),
    ),
    child: Center(
      child: Icon(
        isPublie ? Icons.school_rounded : Icons.edit_note_rounded,
        size: 44,
        color: Colors.white.withOpacity(0.30),
      ),
    ),
  );
}

// ── Badge niveau (frosted glass) ──────────────────────────────
class _NiveauBadge extends StatelessWidget {
  final String niveau;
  const _NiveauBadge({required this.niveau});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (niveau.toUpperCase()) {
      case 'AVANCE':
      case 'AVANCÉ':
        icon = Icons.signal_cellular_alt_rounded;
        break;
      case 'INTERMEDIAIRE':
      case 'INTERMÉDIAIRE':
        icon = Icons.signal_cellular_alt_2_bar_rounded;
        break;
      default:
        icon = Icons.signal_cellular_alt_1_bar_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: _C.ink),
              const SizedBox(width: 3),
              Text(
                niveau,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatar enseignant ─────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String nom;
  const _Avatar({this.avatarUrl, required this.nom});

  @override
  Widget build(BuildContext context) => Container(
    width: 24, height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: _C.faint, width: 1.5),
      color: _C.blueSoft,
    ),
    child: ClipOval(
      child: avatarUrl != null
          ? Image.network(avatarUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarFallback(nom: nom))
          : _AvatarFallback(nom: nom),
    ),
  );
}

class _AvatarFallback extends StatelessWidget {
  final String nom;
  const _AvatarFallback({required this.nom});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      nom.isNotEmpty ? nom[0].toUpperCase() : 'E',
      style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: _C.blue),
    ),
  );
}

// ── Stat chip ────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: _C.muted),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: _C.muted)),
    ],
  );
}

// ══════════════════════════════════════════════════════════════
//  MODULES PREVIEW (expandable)
// ══════════════════════════════════════════════════════════════
class _ModulesPreview extends ConsumerWidget {
  final String idCours;
  final bool expanded;
  final Animation<double> expandAnimation;
  final VoidCallback onToggle;

  const _ModulesPreview({
    required this.idCours,
    required this.expanded,
    required this.expandAnimation,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesProvider(idCours));

    return modulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (modules) {
        if (modules.isEmpty) return const SizedBox.shrink();
        final preview = modules.take(3).toList();

        return Column(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 13, color: _C.muted),
                    const SizedBox(width: 5),
                    Text('${modules.length} module${modules.length > 1 ? 's' : ''}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted,
                        )),
                    const Spacer(),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: _C.muted),
                    ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: expandAnimation,
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFF0F0EE)),
                  ...preview.map((m) => _ModuleRow(idCours: idCours, module: m, ref: ref)),
                  if (modules.length > 3)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        '+ ${modules.length - 3} autre(s) module(s)',
                        style: GoogleFonts.dmSans(fontSize: 10, color: _C.blue),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Module row ───────────────────────────────────────────────
class _ModuleRow extends StatelessWidget {
  final String idCours;
  final Map<String, dynamic> module;
  final WidgetRef ref;

  const _ModuleRow({required this.idCours, required this.module, required this.ref});

  @override
  Widget build(BuildContext context) {
    final idModule = module['idModule'] ?? '';
    final titre    = module['titreModule'] ?? 'Module';
    final statut   = module['statutModule'] ?? 'BROUILLON';
    final count    = module['_count']?['contenus'] ?? 0;
    final isPublie = statut == 'PUBLIE';

    final contenusAsync = ref.watch(contenusProvider((
      idCours:  idCours,
      idModule: idModule,
    )));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0EE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  color: isPublie ? _C.green : _C.faint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(child: Text(titre,
                  style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _C.ink,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              _Badge(label: '$count contenus', color: _C.muted, soft: _C.bg),
            ],
          ),
          contenusAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
            data: (contenus) {
              if (contenus.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Wrap(
                  spacing: 5, runSpacing: 5,
                  children: contenus.take(5).map((c) => _ContenuChip(contenu: c)).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Chip contenu ─────────────────────────────────────────────
class _ContenuChip extends StatelessWidget {
  final Map<String, dynamic> contenu;
  const _ContenuChip({required this.contenu});

  @override
  Widget build(BuildContext context) {
    final type       = contenu['typeContenu'] ?? 'TEXTE';
    final titre      = contenu['titreContenu'] ?? '';
    final fichierUrl = contenu['fichierUrl']  as String?;
    final lien       = contenu['lienExterne'] as String?;
    final meta       = _typeMeta[type];
    final isVideo    = type == 'VIDEO' && (fichierUrl != null || (lien != null && lien.isNotEmpty));

    return GestureDetector(
      onTap: isVideo ? () => _openVideo(context, fichierUrl, lien) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: meta?.soft ?? _C.bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: (meta?.color ?? _C.faint).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.play_circle_filled_rounded : (meta?.icon ?? Icons.file_present),
              size: 12, color: meta?.color ?? _C.muted,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 90),
              child: Text(titre,
                  style: GoogleFonts.dmSans(
                    fontSize: 9, fontWeight: FontWeight.w500,
                    color: meta?.color ?? _C.muted,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (isVideo) ...[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: _C.blue, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, size: 7, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openVideo(BuildContext ctx, String? fichierUrl, String? lien) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) => _CardVideoPlayer(fichierUrl: fichierUrl, lienExterne: lien),
    );
  }
}

// ── Mini lecteur vidéo ────────────────────────────────────────
class _CardVideoPlayer extends StatefulWidget {
  final String? fichierUrl;
  final String? lienExterne;
  const _CardVideoPlayer({this.fichierUrl, this.lienExterne});

  @override
  State<_CardVideoPlayer> createState() => _CardVideoPlayerState();
}

class _CardVideoPlayerState extends State<_CardVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _ready   = false;
  bool _playing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      VideoPlayerController ctrl;
      final lien = widget.lienExterne;
      if (lien != null && lien.isNotEmpty) {
        ctrl = VideoPlayerController.networkUrl(Uri.parse(lien));
      } else if (widget.fichierUrl != null) {
        const base = 'http://localhost:3000';
        ctrl = VideoPlayerController.networkUrl(Uri.parse('$base${widget.fichierUrl}'));
      } else {
        setState(() => _error = 'Source vidéo introuvable');
        return;
      }
      await ctrl.initialize();
      if (mounted) {
        setState(() { _ctrl = ctrl; _ready = true; });
        ctrl.play();
        setState(() => _playing = true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Impossible de lire la vidéo');
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('Lecteur vidéo',
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.error_outline, color: Colors.white38, size: 40),
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.dmSans(color: Colors.white38)),
              ]),
            )
          else if (!_ready)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else ...[
            AspectRatio(
              aspectRatio: _ctrl!.value.aspectRatio,
              child: VideoPlayer(_ctrl!),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VideoProgressIndicator(
                _ctrl!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF2563EB),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _playing ? _ctrl!.pause() : _ctrl!.play();
                      _playing = !_playing;
                    });
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HELPERS VISUELS
// ══════════════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color soft;
  const _Badge({required this.label, required this.color, required this.soft});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(4)),
    child: Text(label,
        style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );
}

class _PopItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _PopItem(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color ?? _C.ink),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: color ?? _C.ink)),
  ]);
}