import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:LMS/features/apprenant/providers/apprenant_provider.dart';

class _AppColors {
  static const bg = Color(0xFFF8F8F6);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFFB8B8B8);
  static const border = Color(0xFFF0F0EE);

  static const statBlueAccent = Color(0xFF3B8DDD);
  static const statGreenAccent = Color(0xFF2EA862);
  static const statAmberAccent = Color(0xFFEA9F25);
  static const statPurpleAccent = Color(0xFF7F77DD);
}

const String _kBaseUrl = 'http://localhost:3000';

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
  late PageController _pageController;
  int _currentIndex = 0;
  bool _dejaMarqueTermine = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _marquerModuleTermineSiBesoin() async {
    if (_dejaMarqueTermine) return;
    _dejaMarqueTermine = true;
    try {
      final result = await ref.read(apprenantActionsProvider.notifier)
          .marquerModuleTermine(widget.idCours, widget.idModule);
      if (mounted && result['coursComplete'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Félicitations, vous avez terminé ce cours !', style: GoogleFonts.outfit())),
        );
      }
    } catch (_) {
      // Échec silencieux — on ne bloque pas la navigation de l'apprenant pour ça
      _dejaMarqueTermine = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = '${widget.idCours}|${widget.idModule}';
    final contenuAsync = ref.watch(contenuModuleProvider(params));

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: contenuAsync.when(
        data: (contenus) => _buildContent(contenus),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(err.toString().replaceAll('Exception: ', ''), style: GoogleFonts.outfit()),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Retour')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> contenus) {
    if (contenus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: _AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Aucun contenu', style: GoogleFonts.outfit(color: _AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.pop(), child: const Text('Retour')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            // Dernier item atteint → on considère le module vu en entier
            if (index == contenus.length - 1) {
              _marquerModuleTermineSiBesoin();
            }
          },
          itemCount: contenus.length,
          itemBuilder: (context, index) => _buildContentItem(contenus[index]),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildControls(contenus.length)),
      ],
    );
  }

  Widget _buildContentItem(Map<String, dynamic> item) {
    final type = item['typeContenu'] as String? ?? 'TEXTE';
    final titre = item['titreContenu'] as String? ?? '';
    final texteContenu = item['texteContenu'] as String?;
    final fichierUrl = item['fichierUrl'] as String?;
    final lienExterne = item['lienExterne'] as String?;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: _AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _getColorForType(type), borderRadius: BorderRadius.circular(20)),
              child: Text(_getLabelForType(type),
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            if (type == 'VIDEO')
              _buildVideoPreview(fichierUrl, lienExterne)
            else if (type == 'DOCUMENT')
              _buildDocumentPreview(fichierUrl)
            else if (type == 'IMAGE')
              _buildImagePreview(fichierUrl)
            else
              _buildTextContent(texteContenu ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(String? fichierUrl, String? lienExterne) {
    final url = lienExterne ?? (fichierUrl != null ? '$_kBaseUrl$fichierUrl' : null);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _AppColors.border)),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: _AppColors.statBlueAccent),
          const SizedBox(height: 12),
          Text('Vidéo', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: url != null ? () => _ouvrirUrl(url) : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Regarder'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(String? fichierUrl) {
    final url = fichierUrl != null ? '$_kBaseUrl$fichierUrl' : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _AppColors.border)),
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 64, color: _AppColors.statAmberAccent),
          const SizedBox(height: 12),
          Text('Document', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: url != null ? () => _ouvrirUrl(url) : null,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String? fichierUrl) {
    if (fichierUrl == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _AppColors.border)),
        child: Center(child: Icon(Icons.image_outlined, size: 64, color: _AppColors.statPurpleAccent)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        '$_kBaseUrl$fichierUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          decoration: BoxDecoration(color: _AppColors.card, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Icon(Icons.broken_image_outlined, color: _AppColors.textTertiary)),
        ),
      ),
    );
  }

  Widget _buildTextContent(String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: _AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _AppColors.border)),
      child: Text(content, style: GoogleFonts.outfit(fontSize: 14, color: _AppColors.textPrimary, height: 1.6)),
    );
  }

  Future<void> _ouvrirUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir ce fichier', style: GoogleFonts.outfit())),
      );
    }
  }

  Widget _buildControls(int totalItems) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _AppColors.card, border: Border(top: BorderSide(color: _AppColors.border))),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / totalItems,
                      minHeight: 4,
                      backgroundColor: _AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(_AppColors.statBlueAccent),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_currentIndex + 1}/$totalItems',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Précédent'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
                    ),
                  ),
                const SizedBox(width: 12),
                if (_currentIndex < totalItems - 1)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Suivant'),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Terminer'),
                      style: ElevatedButton.styleFrom(backgroundColor: _AppColors.statGreenAccent),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'VIDEO': return _AppColors.statBlueAccent;
      case 'DOCUMENT': return _AppColors.statAmberAccent;
      case 'IMAGE': return _AppColors.statPurpleAccent;
      default: return _AppColors.statGreenAccent;
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'VIDEO': return 'Vidéo';
      case 'DOCUMENT': return 'Document';
      case 'IMAGE': return 'Image';
      default: return 'Texte';
    }
  }
}