import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:LMS/features/enseignant/presentation/providers/cours_provider.dart';
import 'package:LMS/features/enseignant/presentation/widgets/module_management_drawer.dart';
import 'package:LMS/features/enseignant/presentation/screens/video_player_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:LMS/core/network/dio_client.dart';
import 'package:dio/dio.dart';
// ══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ══════════════════════════════════════════════════════════════
class _C {
  static const bg         = Color(0xFFF1EFE8);
  static const surface    = Colors.white;
  static const ink        = Color(0xFF111111);
  static const inkLight   = Color(0xFF4A4A4A);
  static const muted      = Color(0xFF888780);
  static const faint      = Color(0xFFD3D1C7);
  static const border     = Color(0xFFE8E8E4);

  static const green      = Color(0xFF3B6D11);
  static const greenSoft  = Color(0xFFEAF3DE);
  static const amber      = Color(0xFF854F0B);
  static const amberSoft  = Color(0xFFFAEEDA);
  static const red        = Color(0xFFA32D2D);
  static const redSoft    = Color(0xFFFCEBEB);
  static const blue       = Color(0xFF185FA5);
  static const blueSoft   = Color(0xFFE6F1FB);
  static const purple     = Color(0xFF534AB7);
  static const purpleSoft = Color(0xFFEEEDFE);
  static const teal       = Color(0xFF0F6E56);
  static const tealSoft   = Color(0xFFE1F5EE);

  static ({Color color, Color soft, IconData icon}) contentMeta(String type) {
    switch (type) {
      case 'VIDEO':    return (color: blue,   soft: blueSoft,   icon: Icons.play_circle_rounded);
      case 'DOCUMENT': return (color: amber,  soft: amberSoft,  icon: Icons.description_rounded);
      case 'TEXTE':    return (color: teal,   soft: tealSoft,   icon: Icons.article_rounded);
      case 'IMAGE':    return (color: purple, soft: purpleSoft, icon: Icons.image_rounded);
      default:         return (color: muted,  soft: bg,         icon: Icons.file_present_rounded);
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  TYPE CONTENU CONFIG — ordre fixe des 4 cases
// ══════════════════════════════════════════════════════════════
const List<String> _kTypeOrder = ['VIDEO', 'DOCUMENT', 'TEXTE', 'IMAGE'];

const Map<String, String> _kTypeLabel = {
  'VIDEO':    'Vidéo',
  'DOCUMENT': 'Document',
  'TEXTE':    'Texte',
  'IMAGE':    'Image',
};

// Extensions autorisées par type pour le file picker
const Map<String, List<String>> _kTypeExtensions = {
  'VIDEO':    ['mp4', 'mov', 'avi', 'mkv', 'webm'],
  'DOCUMENT': ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx'],
  'TEXTE':    ['txt', 'md'],
  'IMAGE':    ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
};

// ══════════════════════════════════════════════════════════════
//  COURS DETAIL SCREEN
// ══════════════════════════════════════════════════════════════
class CoursDetailScreen extends ConsumerStatefulWidget {
  final String idCours;
  final String titreCours;
  final String descriptionCours;
  final String statutCours;

  const CoursDetailScreen({
    required this.idCours,
    required this.titreCours,
    required this.descriptionCours,
    this.statutCours = 'BROUILLON',
    super.key,
  });

  @override
  ConsumerState<CoursDetailScreen> createState() => _CoursDetailScreenState();
}

class _CoursDetailScreenState extends ConsumerState<CoursDetailScreen>
    with TickerProviderStateMixin {
  final Map<String, bool> _expandedModules = {};
  late final AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  /// Lit le statut réel du cours depuis mesCoursProvider, avec repli sur
  /// widget.statutCours si la liste n'est pas encore chargée.
  String _statutActuel(WidgetRef ref) {
    final coursAsync = ref.watch(mesCoursProvider);
    return coursAsync.maybeWhen(
      data: (liste) {
        final cours = liste.firstWhere(
          (c) => c['idCours'] == widget.idCours,
          orElse: () => null,
        );
        return cours?['statutCours'] ?? widget.statutCours;
      },
      orElse: () => widget.statutCours,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modulesAsync = ref.watch(modulesProvider(widget.idCours));
    final statutActuel = _statutActuel(ref);
    final isPublie = statutActuel == 'PUBLIE';

    return Scaffold(
      backgroundColor: _C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────
          _HeroAppBar(
            titre: widget.titreCours,
            description: widget.descriptionCours,
            statut: statutActuel,
            heroAnim: _heroAnim,
            onBack: () => Navigator.pop(context),
            onPublier: _onPublier,
          ),

          // ── Stats ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: modulesAsync.maybeWhen(
                data: (modules) {
                  final totalContenus = modules.fold<int>(
                    0, (s, m) => s + ((m['_count']?['contenus'] ?? 0) as int),
                  );
                  return _StatsRow(
                    modulesCount: modules.length,
                    contenusCount: totalContenus,
                    anim: _heroAnim,
                  );
                },
                orElse: () => _StatsRow(modulesCount: 0, contenusCount: 0, anim: _heroAnim),
              ),
            ),
          ),

          // ── Section header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 18,
                    decoration: BoxDecoration(
                      color: _C.ink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Modules',
                      style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink,
                      )),
                ],
              ),
            ),
          ),

          // ── Liste modules ──────────────────────────────────
          modulesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_C.ink),
                ),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: _C.redSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.error_outline, size: 28, color: _C.red),
                    ),
                    const SizedBox(height: 12),
                    Text('Erreur de chargement',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _C.ink,
                        )),
                    const SizedBox(height: 4),
                    Text(err.toString(),
                        style: GoogleFonts.dmSans(fontSize: 11, color: _C.muted),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            data: (modules) {
              if (modules.isEmpty) return SliverFillRemaining(child: _EmptyState());
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final m = modules[i];
                      final id = m['idModule'] ?? '';
                      _expandedModules[id] ??= false;
                      return _ModuleCard(
                        index: i,
                        isLast: i == modules.length - 1,
                        idCours: widget.idCours,
                        idModule: id,
                        module: m,
                        titre: m['titreModule'] ?? 'Module sans titre',
                        description: m['descriptionModule'] ?? '',
                        statut: m['statutModule'] ?? 'BROUILLON',
                        isExpanded: _expandedModules[id]!,
                        onExpand: () => setState(() {
                          _expandedModules[id] = !_expandedModules[id]!;
                        }),
                        onLongPress: () => _showModuleLongPress(context, m),
                      );
                    },
                    childCount: modules.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ── FAB ───────────────────────────────────────────────
      floatingActionButton: GestureDetector(
        onTap: _openModuleSheet,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: _C.ink,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Nouveau module',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _openModuleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModuleManagementDrawer(
        idCours: widget.idCours,
        titreCours: widget.titreCours,
      ),
    );
  }

  // ── Long press menu module ────────────────────────────────
  void _showModuleLongPress(BuildContext ctx, Map<String, dynamic> module) {
    final isPublie = (module['statutModule'] ?? 'BROUILLON') == 'PUBLIE';
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _LongPressMenu(
        title: module['titreModule'] ?? 'Module',
        actions: [
          _LongPressAction(
            icon: Icons.edit_outlined,
            label: 'Modifier',
            onTap: () {
              Navigator.pop(ctx);
              _showSnack(ctx, 'Modification en développement');
            },
          ),
          _LongPressAction(
            icon: isPublie
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            label: isPublie ? 'Dépublier' : 'Publier',
            onTap: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(coursNotifierProvider.notifier).toggleStatutModule(
                    idCours: widget.idCours, idModule: module['idModule']);
              } finally {
                ref.invalidate(modulesProvider(widget.idCours));
              }
            },
          ),
          _LongPressAction(
            icon: Icons.delete_outline,
            label: 'Supprimer',
            color: _C.red,
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteModule(ctx, module['idModule'] ?? '');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteModule(BuildContext ctx, String idModule) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ce module ?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.dmSans(fontSize: 13, color: _C.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.dmSans()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer',
                style: GoogleFonts.dmSans(
                    color: _C.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(coursNotifierProvider.notifier)
          .supprimerModule(idCours: widget.idCours, idModule: idModule);
    }
  }

  void _onPublier() {
    final statutActuel = _statutActuel(ref);
    final estPublie = statutActuel == 'PUBLIE';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(estPublie ? 'Dépublier le cours ?' : 'Publier le cours ?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
        content: Text(
          estPublie
              ? 'Le cours ne sera plus visible par les étudiants.'
              : 'Le cours sera visible par tous les étudiants inscrits.',
          style: GoogleFonts.poppins(fontSize: 13, color: _C.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins(color: _C.muted)),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              try {
                await ref.read(coursNotifierProvider.notifier)
                    .toggleStatutCours(widget.idCours);
                ref.invalidate(modulesProvider(widget.idCours)); // ← ajoute cette ligne
                if (mounted) {
                  _showSnack(context, estPublie ? 'Cours dépublié' : 'Cours publié avec succès');
                }
              } catch (e) {
                if (mounted) {
                  _showSnack(context,
                      'Erreur : ${e.toString().replaceAll('Exception: ', '')}');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: estPublie ? _C.amber : _C.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(estPublie ? 'Dépublier' : 'Publier',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 12)),
        backgroundColor: _C.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HERO APP BAR
// ══════════════════════════════════════════════════════════════
class _HeroAppBar extends StatelessWidget {
  final String titre;
  final String description;
  final String statut;
  final AnimationController heroAnim;
  final VoidCallback onBack;
  final VoidCallback onPublier;

  const _HeroAppBar({
    required this.titre,
    required this.description,
    required this.statut,
    required this.heroAnim,
    required this.onBack,
    required this.onPublier,
  });

  @override
  Widget build(BuildContext context) {
    final isPublie   = statut == 'PUBLIE';
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverToBoxAdapter(
      child: Container(
        color: _C.bg,
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 16),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: heroAnim, curve: Curves.easeOut),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: _C.ink),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.faint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded, size: 11, color: _C.muted),
                        const SizedBox(width: 5),
                        Text('Cours',
                            style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w500, color: _C.muted,
                            )),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onPublier,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: isPublie ? _C.amber : _C.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPublie ? Icons.visibility_off_rounded : Icons.send_rounded,
                            size: 15, color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(isPublie ? 'Dépublier' : 'Publier',
                              style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15), end: Offset.zero,
                      ).animate(CurvedAnimation(parent: heroAnim, curve: Curves.easeOutCubic)),
                      child: Text(titre,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: _C.ink,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPublie ? _C.greenSoft : _C.faint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPublie ? _C.green : _C.muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(isPublie ? 'Publié' : 'Brouillon',
                            style: GoogleFonts.dmSans(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: isPublie ? _C.green : _C.muted,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(description,
                    style: GoogleFonts.poppins(
                      fontSize: 12, color: _C.muted, height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STATS ROW
// ══════════════════════════════════════════════════════════════
class _StatsRow extends StatelessWidget {
  final int modulesCount;
  final int contenusCount;
  final AnimationController anim;

  const _StatsRow({
    required this.modulesCount,
    required this.contenusCount,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final curve = CurvedAnimation(
          parent: anim,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3), end: Offset.zero,
            ).animate(curve),
            child: Row(
              children: [
                Expanded(child: _StatCard(
                  icon: Icons.layers_rounded,
                  label: 'Modules',
                  value: modulesCount.toString(),
                  iconColor: _C.purple,
                  iconBg: _C.purpleSoft,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  icon: Icons.play_lesson_rounded,
                  label: 'Contenus',
                  value: contenusCount.toString(),
                  iconColor: _C.teal,
                  iconBg: _C.tealSoft,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Étudiants',
                  value: '—',
                  iconColor: _C.amber,
                  iconBg: _C.amberSoft,
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.dmSans(
              fontSize: 20, fontWeight: FontWeight.w800, color: _C.ink,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 9, color: _C.muted)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
//  MODULE CARD
// ══════════════════════════════════════════════════════════════
class _ModuleCard extends ConsumerStatefulWidget {
  final int index;
  final bool isLast;
  final String idCours;
  final String idModule;
  final Map<String, dynamic> module;
  final String titre;
  final String description;
  final String statut;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onLongPress;

  const _ModuleCard({
    required this.index,
    required this.isLast,
    required this.idCours,
    required this.idModule,
    required this.module,
    required this.titre,
    required this.description,
    required this.statut,
    required this.isExpanded,
    required this.onExpand,
    required this.onLongPress,
  });

  @override
  ConsumerState<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends ConsumerState<_ModuleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandCtrl;
  late final Animation<double> _expandCurve;
  late final Animation<double> _radiusAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _expandCurve = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOutCubic);
    _radiusAnim  = Tween<double>(begin: 999, end: 24).animate(_expandCurve);
  }

  @override
  void didUpdateWidget(_ModuleCard old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      widget.isExpanded ? _expandCtrl.forward() : _expandCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPublie = widget.statut == 'PUBLIE';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline ──
          Column(
            children: [
              Container(
                width: 34, height: 34,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPublie ? _C.greenSoft : _C.faint,
                  border: Border.all(
                    color: isPublie ? _C.green : _C.muted,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text('${widget.index + 1}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: isPublie ? _C.green : _C.muted,
                      )),
                ),
              ),
              if (!widget.isLast)
                Container(width: 1.5, height: 20, color: _C.border),
            ],
          ),
          const SizedBox(width: 10),

          // ── Card animée ──
          Expanded(
            child: AnimatedBuilder(
              animation: _radiusAnim,
              builder: (_, child) => Container(
                margin: const EdgeInsets.only(top: 6, bottom: 12),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(_radiusAnim.value),
                  border: Border.all(
                    color: widget.isExpanded
                        ? _C.ink.withOpacity(0.15)
                        : _C.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        widget.isExpanded ? 0.06 : 0.02,
                      ),
                      blurRadius: widget.isExpanded ? 12 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: child,
              ),
              child: Column(
                children: [
                  // ── Header ──
                  GestureDetector(
                    onTap: widget.onExpand,
                    onLongPress: widget.onLongPress,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(widget.titre,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _C.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPublie ? _C.greenSoft : _C.faint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5, height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPublie ? _C.green : _C.muted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(isPublie ? 'Publié' : 'Brouillon',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isPublie ? _C.green : _C.muted,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: widget.isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _C.bg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 15,
                                color: widget.isExpanded ? _C.ink : _C.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Contenus (expandable) ──
                  SizeTransition(
                    sizeFactor: _expandCurve,
                    child: _ContenusSection(
                      idCours:  widget.idCours,
                      idModule: widget.idModule,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CONTENUS SECTION  — liste verticale 4 lignes fixes (VIDEO/DOC/TEXTE/IMAGE)
// ══════════════════════════════════════════════════════════════
class _ContenusSection extends ConsumerStatefulWidget {
  final String idCours;
  final String idModule;

  const _ContenusSection({required this.idCours, required this.idModule});

  /// Retourne vrai si le contenu a une source lisible
  static bool hasFichier(Map<String, dynamic> c) {
    final type = c['typeContenu'] ?? 'TEXTE';
    if (type == 'TEXTE') {
      final texte = c['texteContenu'] as String?;
      return texte != null && texte.isNotEmpty;
    }
    final lien       = c['lienExterne']  as String?;
    final fichierUrl = c['fichierUrl']   as String?;
    final localPath  = c['localPath']    as String?;
    return (lien       != null && lien.isNotEmpty) ||
           (fichierUrl != null && fichierUrl.isNotEmpty) ||
           (localPath  != null && localPath.isNotEmpty);
  }

  @override
  ConsumerState<_ContenusSection> createState() => _ContenusSectionState();
}

class _ContenusSectionState extends ConsumerState<_ContenusSection> {
  // ── Etat d'upload en cours (affiché en spinner sur la ligne concernée) ──
  String? _uploadingType;
  double _uploadProgress = 0;

  String get idCours  => widget.idCours;
  String get idModule => widget.idModule;

  @override
  Widget build(BuildContext context) {
    final contenusAsync = ref.watch(contenusProvider((
      idCours:  idCours,
      idModule: idModule,
    )));

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: contenusAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(18),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_C.ink),
            ),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(14),
          child: Text('Erreur: $e',
              style: GoogleFonts.poppins(fontSize: 11, color: _C.red)),
        ),
        data: (contenus) {
          // ── Construire un Map<type → contenu> depuis la liste ──
          final Map<String, Map<String, dynamic>?> byType = {
            for (final t in _kTypeOrder) t: null,
          };
          for (final c in contenus) {
            final type = c['typeContenu'] as String?;
            if (type != null && byType.containsKey(type)) {
              byType[type] = c;
            }
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_play_rounded, size: 13, color: _C.muted),
                      const SizedBox(width: 5),
                      Text(
                        '${contenus.length} contenu${contenus.length > 1 ? 's' : ''}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11, fontWeight: FontWeight.w600, color: _C.inkLight,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.touch_app_outlined, size: 11, color: _C.muted),
                      const SizedBox(width: 3),
                      Text('Appui long pour options',
                          style: GoogleFonts.poppins(fontSize: 9, color: _C.muted)),
                    ],
                  ),
                ),

                // ── Liste 4 lignes (VIDEO / DOCUMENT / TEXTE / IMAGE) ──
                ..._kTypeOrder.map((type) {
                  final contenu = byType[type];
                  final hasFile = contenu != null && _ContenusSection.hasFichier(contenu);
                  final isUploading = _uploadingType == type;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ContenuListItem(
                      type:        type,
                      contenu:     contenu,
                      hasFichier:  hasFile,
                      isUploading: isUploading,
                      progress:    _uploadProgress,
                      onTap: isUploading
                          ? null
                          : (contenu != null && hasFile
                              ? () => _openContenu(context, contenu)
                              : () => _pickAndUpload(context, ref, type)),
                      onLongPress: isUploading
                          ? null
                          : (contenu != null
                              ? () => _showContenuLongPress(context, ref, contenu)
                              : () => _pickAndUpload(context, ref, type)),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  OUVRIR CONTENU — vidéo/image en lecteur intégré, reste via OpenFilex
  // ══════════════════════════════════════════════════════════
  Future<void> _openContenu(
      BuildContext context, Map<String, dynamic> c) async {
    final type       = c['typeContenu']  ?? 'TEXTE';
    final lien       = c['lienExterne']  as String?;
    final fichierUrl = c['fichierUrl']   as String?;
    final texte      = c['texteContenu'] as String?;
    final titre      = c['titreContenu'] ?? '';
    final localPath  = c['localPath']    as String?;

    // ── LOG DEBUG : état complet du contenu à l'ouverture ──
    debugPrint('╔══ OPEN DEBUG ═════════════════════════════');
    debugPrint('║ type       : $type');
    debugPrint('║ kIsWeb     : $kIsWeb');
    debugPrint('║ lien       : $lien');
    debugPrint('║ fichierUrl : $fichierUrl');
    debugPrint('║ localPath  : $localPath');
    debugPrint('║ baseUrl    : ${DioClient.baseUrl}');
    debugPrint('╚═══════════════════════════════════════════');

    // ── TEXTE — dialogue in-app ──
    if (type == 'TEXTE') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(titre,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
          content: SingleChildScrollView(
            child: Text(texte ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 13, color: _C.inkLight, height: 1.5,
                )),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fermer',
                  style: GoogleFonts.poppins(
                    color: _C.ink, fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      );
      return;
    }

    // ── VIDEO : toujours le lecteur intégré, jamais une app externe ──
    if (type == 'VIDEO') {
      final url = _resolveUrl(lien, fichierUrl);
      if (url == null) {
        _showSnack(context, 'Aucune source vidéo disponible');
        return;
      }

      if (kIsWeb) {
        // ── WEB : ouvrir dans un nouvel onglet ──
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else if (context.mounted) {
          _showSnack(context, 'Impossible d\'ouvrir la vidéo');
        }
      } else {
        // ── MOBILE : lecteur intégré ──
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              videoUrl: url,
              titre: titre,
              isLocal: false,
            ),
          ));
        }
      }
      return;
    }

    // ── Chemin local (fichier en cache, pour DOCUMENT/IMAGE) — MOBILE UNIQUEMENT ──
    if (!kIsWeb && localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (await file.exists()) {
        debugPrint('→ Ouverture via localPath (mobile) : $localPath');
        final result = await OpenFilex.open(localPath);
        if (result.type != ResultType.done && context.mounted) {
          _showSnack(context,
              'Impossible d\'ouvrir avec une app native : ${result.message}');
        }
        return;
      }
    }

    // ── fichierUrl commençant par '/' = chemin local absolu — MOBILE UNIQUEMENT ──
    // ⚠️ Sur le WEB, un fichierUrl du type "/uploads/documents/x.pdf" est une
    // URL RELATIVE serveur, pas un chemin filesystem. dart:io File n'est pas
    // utilisable sur Chrome : ce bloc doit être ignoré sur le web, sinon
    // l'ouverture de DOCUMENT/IMAGE échoue silencieusement avant d'atteindre
    // le bloc "Fichier hébergé sur le serveur" plus bas.
    if (!kIsWeb &&
        fichierUrl != null &&
        fichierUrl.isNotEmpty &&
        fichierUrl.startsWith('/')) {
      final file = File(fichierUrl);
      if (await file.exists()) {
        debugPrint('→ Ouverture via fichierUrl en tant que chemin local (mobile) : $fichierUrl');
        final result = await OpenFilex.open(fichierUrl);
        if (result.type != ResultType.done && context.mounted) {
          _showSnack(context,
              'Impossible d\'ouvrir avec une app native : ${result.message}');
        }
        return;
      }
    } else if (kIsWeb) {
      debugPrint('→ Web détecté : bloc "chemin local absolu" ignoré (comme prévu)');
    }

    // ── Lien externe véritable (YouTube, Vimeo...) ──
    if (lien != null && lien.isNotEmpty) {
      final uri = Uri.tryParse(lien);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showSnack(context, 'Impossible d\'ouvrir le lien');
      }
      return;
    }

    // ── Fichier hébergé sur le serveur (DOCUMENT/IMAGE) ──
    if (fichierUrl != null && fichierUrl.isNotEmpty) {
      final url = _resolveUrl(null, fichierUrl);
      debugPrint('→ URL résolue pour ouverture serveur : $url');
      if (url == null) {
        _showSnack(context, 'Aucune source disponible');
        return;
      }

      if (kIsWeb) {
        // ── WEB : ouvrir dans un nouvel onglet ──
        final uri = Uri.tryParse(url);
        final peutOuvrir = uri != null ? await canLaunchUrl(uri) : false;
        debugPrint('→ Uri.tryParse : $uri');
        debugPrint('→ canLaunchUrl : $peutOuvrir');
        if (uri != null && peutOuvrir) {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('→ launchUrl résultat : $ok');
        } else if (context.mounted) {
          debugPrint('→ ÉCHEC : impossible de lancer $url');
          _showSnack(context, 'Impossible d\'ouvrir le fichier');
        }
      } else {
        // ── MOBILE : télécharger en local puis ouvrir ──
        _showSnack(context, 'Téléchargement…');
        final path = await _downloadToTemp(url, fichierUrl, titre);
        if (path == null) {
          if (context.mounted) _showSnack(context, 'Échec du téléchargement');
          return;
        }
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done && context.mounted) {
          _showSnack(context, 'Impossible d\'ouvrir : ${result.message}');
        }
      }
      return;
    }

    _showSnack(context, 'Aucune source disponible');
  }

  /// Télécharge le fichier distant dans le cache local de l'app et retourne
  /// son chemin, pour pouvoir l'ouvrir avec le lecteur système (OpenFilex)
  /// au lieu de passer par un navigateur ou une app externe.
  Future<String?> _downloadToTemp(
      String url, String fichierUrl, String titre) async {
        if (kIsWeb) return null;
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return null;
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      client.close();

      final originalName = fichierUrl.split('/').last.split('?').first;
      final ext = originalName.contains('.') ? originalName.split('.').last : '';
      final safeTitre = (titre.isNotEmpty ? titre : 'fichier')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = ext.isNotEmpty ? '$safeTitre.$ext' : safeTitre;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════
  //  PICK & UPLOAD — sélectionner puis uploader vers le backend
  //  Sur web (Chrome), le picker ne fournit pas de `path` filesystem :
  //  on utilise `withData: true` pour récupérer les bytes en mémoire
  //  et on les envoie tels quels au notifier / datasource.
  //  Pendant l'upload, `_uploadingType` fait afficher un spinner + %
  //  directement sur la ligne concernée dans la liste.
  // ══════════════════════════════════════════════════════════
  Future<void> _pickAndUpload(
      BuildContext context, WidgetRef ref, String type) async {
    HapticFeedback.lightImpact();

    FileType fileType;
    List<String>? allowedExtensions;

    switch (type) {
      case 'VIDEO':
        fileType = FileType.video;
        break;
      case 'IMAGE':
        fileType = FileType.image;
        break;
      case 'DOCUMENT':
        fileType = FileType.custom;
        allowedExtensions = _kTypeExtensions['DOCUMENT'];
        break;
      case 'TEXTE':
        fileType = FileType.custom;
        allowedExtensions = _kTypeExtensions['TEXTE'];
        break;
      default:
        fileType = FileType.any;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: kIsWeb, // ← nécessaire sur Chrome, sinon path == null
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      final bool hasSource = kIsWeb
          ? file.bytes != null
          : (file.path != null && file.path!.isNotEmpty);

      if (!hasSource) {
        if (context.mounted) {
          _showSnack(context, 'Erreur : impossible d\'accéder au fichier');
        }
        return;
      }

      // ── Demander un titre avant l'upload ──
      final titre = await _askTitre(context, defaultValue: file.name);
      if (titre == null || titre.trim().isEmpty) return; // annulé

      // ── LOG DEBUG : infos sur le fichier avant envoi ──
      debugPrint('╔══ UPLOAD DEBUG ══════════════════════════');
      debugPrint('║ type          : $type');
      debugPrint('║ titre         : ${titre.trim()}');
      debugPrint('║ file.name     : ${file.name}');
      debugPrint('║ file.extension: ${file.extension}');
      debugPrint('║ file.size     : ${file.size} octets');
      debugPrint('║ kIsWeb        : $kIsWeb');
      debugPrint('║ file.path     : ${kIsWeb ? "(null sur web)" : file.path}');
      debugPrint('║ bytes != null : ${file.bytes != null}');
      debugPrint('║ bytes.length  : ${file.bytes?.length}');
      debugPrint('║ baseUrl utilisé : ${DioClient.baseUrl}');
      debugPrint('╚═══════════════════════════════════════════');

      // ── Upload réel vers le backend (path sur mobile, bytes sur web) ──
      if (mounted) setState(() { _uploadingType = type; _uploadProgress = 0; });
      try {
        await ref.read(coursNotifierProvider.notifier).ajouterContenu(
          idCours: idCours,
          idModule: idModule,
          titreContenu: titre.trim(),
          typeContenu: type,
          fichierPath: kIsWeb ? null : file.path,
          fichierBytes: kIsWeb ? file.bytes : null,
          fichierNom: file.name,
          onSendProgress: (sent, total) {
            if (mounted && total > 0) {
              setState(() => _uploadProgress = sent / total);
            }
          },
        );
        debugPrint('✅ UPLOAD RÉUSSI pour type=$type');
        if (context.mounted) {
          _showSnack(context, '${_kTypeLabel[type]} ajouté avec succès');
        }
      } catch (e) {
        // ── LOG DEBUG : détail complet de l'erreur ──
        debugPrint('╔══ UPLOAD ERROR DEBUG ════════════════════');
        debugPrint('║ type erreur   : ${e.runtimeType}');
        if (e is DioException) {
          debugPrint('║ statusCode    : ${e.response?.statusCode}');
          debugPrint('║ response.data : ${e.response?.data}');
          debugPrint('║ request URI   : ${e.requestOptions.uri}');
          debugPrint('║ request method: ${e.requestOptions.method}');
          debugPrint('║ request headers: ${e.requestOptions.headers}');
          debugPrint('║ request contentType (options): ${e.requestOptions.contentType}');
          debugPrint('║ request data type: ${e.requestOptions.data.runtimeType}');
          debugPrint('║ DioException type: ${e.type}');
          debugPrint('║ message       : ${e.message}');
        } else {
          debugPrint('║ toString()    : $e');
        }
        debugPrint('╚═══════════════════════════════════════════');
        if (context.mounted) {
          _showSnack(context, 'Erreur upload : ${e.toString().replaceAll('Exception: ', '')}');
        }
      } finally {
        if (mounted) setState(() { _uploadingType = null; _uploadProgress = 0; });
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Erreur lors de la sélection : $e');
      }
    }
  }

  // ── Petite boîte de dialogue pour saisir le titre ──
  Future<String?> _askTitre(BuildContext context, {String? defaultValue}) {
    final ctrl = TextEditingController(text: defaultValue ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Titre du contenu',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ex: Introduction Flutter',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text('Annuler', style: GoogleFonts.poppins(color: _C.muted)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, ctrl.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _C.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Continuer',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Long press menu contenu ───────────────────────────────
  void _showContenuLongPress(
      BuildContext ctx, WidgetRef ref, Map<String, dynamic> c) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _LongPressMenu(
        title: c['titreContenu'] ?? 'Contenu',
        actions: [
          _LongPressAction(
            icon: Icons.edit_outlined,
            label: 'Modifier',
            onTap: () {
              Navigator.pop(ctx);
              _showSnack(ctx, 'Modification en développement');
            },
          ),
          _LongPressAction(
            icon: Icons.delete_outline,
            label: 'Supprimer',
            color: _C.red,
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteContenu(ctx, ref, c['idContenu'] ?? '');
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteContenu(
      BuildContext ctx, WidgetRef ref, String idContenu) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.poppins(fontSize: 13, color: _C.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.poppins(color: _C.muted)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              ref.read(coursNotifierProvider.notifier).supprimerContenu(
                idCours:   idCours,
                idModule:  idModule,
                idContenu: idContenu,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _C.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Supprimer',
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Résout l'URL finale (lien externe ou fichier uploadé sur serveur)
  String? _resolveUrl(String? lien, String? fichierUrl) {
    if (lien != null && lien.isNotEmpty) return lien;
    if (fichierUrl != null && fichierUrl.isNotEmpty) {
      return fichierUrl.startsWith('http')
          ? fichierUrl
          : '${DioClient.baseUrl}$fichierUrl';
    }
    return null;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 12)),
        backgroundColor: _C.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CONTENU LIST ITEM  — ligne façon liste de transactions
//  (icône ronde colorée + titre/sous-titre + statut ou spinner d'upload)
// ══════════════════════════════════════════════════════════════
class _ContenuListItem extends StatelessWidget {
  final String type;
  final Map<String, dynamic>? contenu;
  final bool hasFichier;
  final bool isUploading;
  final double progress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ContenuListItem({
    required this.type,
    required this.contenu,
    required this.hasFichier,
    required this.isUploading,
    required this.progress,
    required this.onTap,
    required this.onLongPress,
  });

  String _subtitle() {
    if (isUploading) return 'Envoi en cours…';
    if (contenu == null) return 'Appuyer pour ajouter';
    final titre = contenu?['titreContenu'] as String?;
    if (titre != null && titre.isNotEmpty) return titre;
    return 'Sans titre';
  }

  /// Icône d'action selon le type (bouton explicite pour ouvrir/lire le contenu)
  IconData _actionIcon() {
    switch (type) {
      case 'VIDEO':    return Icons.play_arrow_rounded;
      case 'DOCUMENT': return Icons.open_in_new_rounded;
      case 'TEXTE':    return Icons.remove_red_eye_rounded;
      case 'IMAGE':    return Icons.open_in_new_rounded;
      default:         return Icons.open_in_new_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta    = _C.contentMeta(type);
    final label   = _kTypeLabel[type] ?? type;
    final isEmpty = contenu == null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUploading
                ? meta.color.withOpacity(0.4)
                : _C.border,
            width: isUploading ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Icône ronde avec badge (façon avatar transaction) ──
            SizedBox(
              width: 42, height: 42,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEmpty ? _C.faint : meta.soft,
                    ),
                    child: isUploading
                        ? Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              value: progress > 0 ? progress : null,
                              valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                              backgroundColor: meta.color.withOpacity(0.15),
                            ),
                          )
                        : Icon(
                            meta.icon,
                            size: 19,
                            color: isEmpty ? _C.muted : meta.color,
                          ),
                  ),
                  // Badge bas-droite : ✓ si présent, + si vide
                  if (!isUploading)
                    Positioned(
                      right: -2, bottom: -2,
                      child: Container(
                        width: 17, height: 17,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasFichier ? _C.green : _C.ink,
                          border: Border.all(color: _C.surface, width: 2),
                        ),
                        child: Icon(
                          hasFichier ? Icons.check_rounded : Icons.add_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Titre + sous-titre ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _C.ink,
                      )),
                  const SizedBox(height: 2),
                  Text(_subtitle(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isUploading ? meta.color : _C.muted,
                        fontWeight: isUploading ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Trailing : % pendant upload, sinon statut / chevron ──
            if (isUploading)
              Text('${(progress * 100).clamp(0, 100).toInt()}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: meta.color,
                  ))
            else if (hasFichier)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.greenSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Ajouté',
                        style: GoogleFonts.dmSans(
                          fontSize: 9, fontWeight: FontWeight.w700, color: _C.green,
                        )),
                  ),
                  const SizedBox(width: 6),
                  // ── Bouton rond — lire / ouvrir le contenu ──
                  if (onTap != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTap,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: meta.soft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_actionIcon(), size: 15, color: meta.color),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // ── Bouton "3 points" — ouvre le menu d'options ──
                  if (onLongPress != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onLongPress,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.more_vert_rounded, size: 17, color: _C.muted),
                      ),
                    ),
                ],
              )
            else
              Icon(Icons.add_circle_outline_rounded, size: 18, color: _C.muted),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LONG PRESS MENU SHEET
// ══════════════════════════════════════════════════════════════
class _LongPressAction {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _LongPressAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class _LongPressMenu extends StatelessWidget {
  final String title;
  final List<_LongPressAction> actions;
  const _LongPressMenu({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 3,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: _C.faint, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(title,
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _C.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          ),
          ...actions.map((a) => _LongPressMenuTile(action: a)),
        ],
      ),
    );
  }
}

class _LongPressMenuTile extends StatelessWidget {
  final _LongPressAction action;
  const _LongPressMenuTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final color = action.color ?? _C.ink;
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: action.color != null
              ? action.color!.withOpacity(0.05)
              : _C.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: action.color != null
                  ? action.color!.withOpacity(0.2)
                  : _C.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(action.icon, size: 17, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(action.label,
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color))),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: color.withOpacity(0.4)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  EMPTY STATE  (aucun module)
// ══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _C.faint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.layers_outlined, size: 32, color: _C.muted),
        ),
        const SizedBox(height: 14),
        Text('Aucun module',
            style: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w700, color: _C.ink,
            )),
        const SizedBox(height: 5),
        Text('Créez votre premier module pour commencer',
            style: GoogleFonts.poppins(fontSize: 12, color: _C.muted)),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
//  LEGACY
// ══════════════════════════════════════════════════════════════
@Deprecated('Use CoursDetailScreen instead')
class ModuleDetailScreen extends ConsumerWidget {
  final String idCours;
  final String idModule;
  final String titreModule;

  const ModuleDetailScreen({
    required this.idCours,
    required this.idModule,
    required this.titreModule,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: _C.bg,
    appBar: AppBar(
      backgroundColor: _C.ink,
      title: Text(titreModule,
          style: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
          )),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: const Center(child: Text('Migré vers CoursDetailScreen')),
  );
}