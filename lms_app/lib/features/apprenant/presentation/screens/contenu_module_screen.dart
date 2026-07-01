import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:LMS/features/apprenant/providers/apprenant_provider.dart';
import 'package:LMS/features/enseignant/presentation/screens/video_player_screen.dart';
import 'package:LMS/core/network/dio_client.dart';
// ══════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ══════════════════════════════════════════════════════════════
class _C {
  static const bg          = Color(0xFFF8F8F6);
  static const card        = Colors.white;
  static const ink         = Color(0xFF1A1A1A);
  static const muted       = Color(0xFF8A8A8A);
  static const border      = Color(0xFFF0F0EE);
  static const blue        = Color(0xFF3B8DDD);
  static const blueSoft    = Color(0xFFE8F2FC);
  static const amber       = Color(0xFFEA9F25);
  static const amberSoft   = Color(0xFFFEF5E7);
  static const teal        = Color(0xFF0F6E56);
  static const tealSoft    = Color(0xFFE1F5EE);
  static const purple      = Color(0xFF7F77DD);
  static const purpleSoft  = Color(0xFFEEEDFE);
  static const green       = Color(0xFF2EA862);

  static ({Color color, Color soft, IconData icon, String label}) formatMeta(String type) {
    switch (type) {
      case 'VIDEO':
        return (color: blue,   soft: blueSoft,   icon: Icons.play_circle_rounded,  label: 'Vidéo');
      case 'DOCUMENT':
        return (color: amber,  soft: amberSoft,  icon: Icons.description_rounded,  label: 'Document PDF');
      case 'TEXTE':
        return (color: teal,   soft: tealSoft,   icon: Icons.article_rounded,       label: 'Texte');
      case 'IMAGE':
        return (color: purple, soft: purpleSoft, icon: Icons.image_rounded,         label: 'Image');
      default:
        return (color: muted,  soft: bg,         icon: Icons.file_present_rounded,  label: type);
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  SCREEN PRINCIPAL
// ══════════════════════════════════════════════════════════════
class ContenuModuleScreen extends ConsumerStatefulWidget {
  final String idCours;
  final String idModule;

  const ContenuModuleScreen({
    super.key,
    required this.idCours,
    required this.idModule,
  });

  @override
  ConsumerState<ContenuModuleScreen> createState() => _ContenuModuleScreenState();
}

class _ContenuModuleScreenState extends ConsumerState<ContenuModuleScreen> {
  bool _dejaMarqueTermine = false;
  bool _ouvertureEnCours  = false;

  Future<void> _marquerTermine() async {
    if (_dejaMarqueTermine) return;
    _dejaMarqueTermine = true;
    try {
      final result = await ref
          .read(apprenantActionsProvider.notifier)
          .marquerModuleTermine(widget.idCours, widget.idModule);
      if (mounted && result['coursComplete'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎉 Félicitations, vous avez terminé ce cours !',
              style: GoogleFonts.outfit()),
          backgroundColor: _C.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      _dejaMarqueTermine = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final params      = '${widget.idCours}|${widget.idModule}';
    final contenuAsync = ref.watch(contenuModuleProvider(params));

    return Scaffold(
      backgroundColor: _C.bg,
      body: contenuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (err, _) => _ErrorView(message: err.toString(), onBack: () => context.pop()),
        data:    (contenus) => _buildBody(contenus),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> contenus) {
    if (contenus.isEmpty) {
      return _EmptyView(onBack: () => context.pop());
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──
          _Header(onBack: () => context.pop()),
          const SizedBox(height: 8),

          // ── Intro ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choisissez votre format',
                    style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w700, color: _C.ink,
                    )),
                const SizedBox(height: 6),
                Text(
                  'Ce module est disponible en ${contenus.length} format${contenus.length > 1 ? 's' : ''}. '
                  'Choisissez celui qui vous convient le mieux.',
                  style: GoogleFonts.outfit(fontSize: 13, color: _C.muted, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Cartes de format ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.separated(
                itemCount: contenus.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _FormatCard(
                  contenu: contenus[i],
                  isLoading: _ouvertureEnCours,
                  onOpen: () => _ouvrir(contenus[i]),
                ),
              ),
            ),
          ),

          // ── Bouton "Marquer comme terminé" ──
          _BottomBar(onTerminer: () async {
            await _marquerTermine();
            if (mounted) context.pop();
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  OUVRIR UN CONTENU SELON SON TYPE
  // ══════════════════════════════════════════════════════════
  Future<void> _ouvrir(Map<String, dynamic> c) async {
    if (_ouvertureEnCours) return;
    setState(() => _ouvertureEnCours = true);

    try {
      final type       = c['typeContenu']  as String? ?? 'TEXTE';
      final fichierUrl = c['fichierUrl']   as String?;
      final lienExt    = c['lienExterne']  as String?;
      final texte      = c['texteContenu'] as String?;
      final titre      = c['titreContenu'] as String? ?? '';

      // ── LOG DEBUG : état complet du contenu à l'ouverture ──
      debugPrint('╔══ OUVRIR DEBUG (apprenant) ════════════════');
      debugPrint('║ type       : $type');
      debugPrint('║ kIsWeb     : $kIsWeb');
      debugPrint('║ lienExt    : $lienExt');
      debugPrint('║ fichierUrl : $fichierUrl');
      debugPrint('║ baseUrl    : ${DioClient.baseUrl}');
      debugPrint('╚═════════════════════════════════════════════');

      switch (type) {

        // ── TEXTE : dialogue in-app ──
        case 'TEXTE':
          _showTexte(titre, texte ?? '');
          break;

        // ── VIDEO : lecteur intégré ──
        case 'VIDEO':
          final url = _resolveUrl(lienExt, fichierUrl);
          debugPrint('→ [VIDEO] URL résolue : $url');
          if (url != null && mounted) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                videoUrl: url,
                titre:    titre,
                isLocal:  false,
              ),
            ));
          } else {
            _snack('Aucune source vidéo disponible');
          }
          break;

        // ── DOCUMENT & IMAGE ──
        // WEB   : ouvrir directement l'URL dans un nouvel onglet (launchUrl).
        //         dart:io (HttpClient/File), path_provider et open_filex ne
        //         fonctionnent PAS sur Flutter Web — il ne faut jamais les
        //         appeler quand kIsWeb == true.
        // MOBILE: télécharger dans un fichier temporaire puis ouvrir avec
        //         le lecteur natif (OpenFilex).
        case 'DOCUMENT':
        case 'IMAGE':
          final url = _resolveUrl(lienExt, fichierUrl);
          debugPrint('→ [DOCUMENT/IMAGE] URL résolue : $url');
          if (url == null) {
            _snack('Aucune source disponible');
            break;
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
              if (!ok && mounted) _snack('Impossible d\'ouvrir le fichier');
            } else {
              debugPrint('→ ÉCHEC : impossible de lancer $url');
              _snack('Impossible d\'ouvrir le fichier');
            }
          } else {
            // ── MOBILE : télécharger en local puis ouvrir ──
            _snack('Téléchargement en cours…');
            final path = await _downloadToTemp(url, fichierUrl ?? '', titre);
            debugPrint('→ Chemin téléchargé (mobile) : $path');
            if (path == null) {
              if (mounted) _snack('Échec du téléchargement');
              break;
            }
            final result = await OpenFilex.open(path);
            debugPrint('→ OpenFilex résultat : ${result.type} / ${result.message}');
            if (result.type != ResultType.done && mounted) {
              _snack('Impossible d\'ouvrir : ${result.message}');
            }
          }
          break;

        default:
          _snack('Format non supporté');
      }
    } finally {
      if (mounted) setState(() => _ouvertureEnCours = false);
    }
  }

  void _showTexte(String titre, String texte) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titre,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(
          child: Text(texte,
              style: GoogleFonts.outfit(fontSize: 14, color: _C.ink, height: 1.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer',
                style: GoogleFonts.outfit(
                    color: _C.ink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String? _resolveUrl(String? lien, String? fichierUrl) {
    if (lien != null && lien.isNotEmpty) return lien;
    if (fichierUrl != null && fichierUrl.isNotEmpty) {
      return fichierUrl.startsWith('http')
          ? fichierUrl
          : '${DioClient.baseUrl}$fichierUrl';
    }
    return null;
  }

  Future<String?> _downloadToTemp(
      String url, String fichierUrl, String titre) async {
    // ── dart:io / path_provider non supportés sur le Web ──
    if (kIsWeb) return null;
    try {
      final client  = HttpClient();
      final request  = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) { client.close(); return null; }
      final bytes = await consolidateHttpClientResponseBytes(response);
      client.close();

      final originalName = fichierUrl.split('/').last.split('?').first;
      final ext = originalName.contains('.') ? originalName.split('.').last : '';
      final safe = (titre.isNotEmpty ? titre : 'fichier')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = ext.isNotEmpty ? '$safe.$ext' : safe;

      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontSize: 13)),
      backgroundColor: _C.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ));
  }
}

// ══════════════════════════════════════════════════════════════
//  CARTE FORMAT  — grande carte cliquable pour un format
// ══════════════════════════════════════════════════════════════
class _FormatCard extends StatelessWidget {
  final Map<String, dynamic> contenu;
  final bool isLoading;
  final VoidCallback onOpen;

  const _FormatCard({
    required this.contenu,
    required this.isLoading,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final type  = contenu['typeContenu'] as String? ?? 'TEXTE';
    final titre = contenu['titreContenu'] as String? ?? '';
    final meta  = _C.formatMeta(type);

    return GestureDetector(
      onTap: isLoading ? null : onOpen,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(999),
            
            
          ),
          child: Row(
            children: [
              // ── Icône format ──
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: meta.soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(meta.icon, size: 28, color: meta.color),
              ),
              const SizedBox(width: 16),

              // ── Infos ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.label,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: meta.color,
                          letterSpacing: 0.8,
                        )),
                    const SizedBox(height: 3),
                    Text(titre.isNotEmpty ? titre : meta.label,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _C.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_subtitleForType(type),
                        style: GoogleFonts.outfit(fontSize: 12, color: _C.muted)),
                  ],
                ),
              ),

              // ── Bouton ──
              const SizedBox(width: 12),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: meta.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(_actionIconForType(type),
                    size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleForType(String type) {
    switch (type) {
      case 'VIDEO':    return 'Regarder dans le lecteur intégré';
      case 'DOCUMENT': return 'Ouvrir le document PDF';
      case 'TEXTE':    return 'Lire le contenu texte';
      case 'IMAGE':    return 'Voir les images';
      default:         return 'Ouvrir';
    }
  }

  IconData _actionIconForType(String type) {
    switch (type) {
      case 'VIDEO':    return Icons.play_arrow_rounded;
      case 'DOCUMENT': return Icons.open_in_new_rounded;
      case 'TEXTE':    return Icons.remove_red_eye_rounded;
      case 'IMAGE':    return Icons.image_rounded;
      default:         return Icons.open_in_new_rounded;
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  WIDGETS UTILITAIRES
// ══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _C.ink),
        ),
        Text('Contenu du module',
            style: GoogleFonts.outfit(
              fontSize: 14, fontWeight: FontWeight.w600, color: _C.muted,
            )),
      ],
    ),
  );
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onTerminer;
  const _BottomBar({required this.onTerminer});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    decoration: const BoxDecoration(
      
      border: Border(top: BorderSide(color: _C.border)),
    ),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTerminer,
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: Text('Marquer comme terminé',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 27, 99, 58),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyView({required this.onBack});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text('Aucun contenu disponible',
          style: GoogleFonts.outfit(fontSize: 15, color: _C.muted)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: onBack, child: const Text('Retour')),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(message.replaceAll('Exception: ', ''),
            style: GoogleFonts.outfit(color: _C.muted), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: onBack, child: const Text('Retour')),
      ]),
    ),
  );
}