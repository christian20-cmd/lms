import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
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
}

const String _kBaseUrl = 'http://localhost:3000';

class DetailCoursApprenantScreen extends ConsumerStatefulWidget {
  final String idCours;
  const DetailCoursApprenantScreen({super.key, required this.idCours});

  @override
  ConsumerState<DetailCoursApprenantScreen> createState() => _DetailCoursApprenantScreenState();
}

class _DetailCoursApprenantScreenState extends ConsumerState<DetailCoursApprenantScreen> {
  bool _inscriptionEnCours = false;

  Future<void> _confirmerInscription(Map<String, dynamic> cours) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("S'inscrire à ce cours ?", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        content: Text(
          cours['estGratuitCours'] == true
              ? 'Ce cours est gratuit. Vous y aurez accès immédiatement après inscription.'
              : 'Ce cours est payant (${cours['prixCours'] ?? 0} Ar). Votre inscription sera en attente de paiement.',
          style: GoogleFonts.outfit(fontSize: 13, color: _AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.outfit(color: _AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("S'inscrire", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: _AppColors.statBlueAccent)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _inscriptionEnCours = true);
    try {
      await ref.read(apprenantActionsProvider.notifier).sInscrire(widget.idCours);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie !', style: GoogleFonts.outfit())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.outfit())),
        );
      }
    } finally {
      if (mounted) setState(() => _inscriptionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursAsync = ref.watch(detailCoursApprenantProvider(widget.idCours));
    final estInscritAsync = ref.watch(estInscritProvider(widget.idCours));

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: coursAsync.when(
        data: (cours) => CustomScrollView(
          slivers: [
            _buildHeader(cours),
            SliverToBoxAdapter(
              child: estInscritAsync.when(
                data: (estInscrit) => estInscrit
                    ? _buildProgressionSection()
                    : _buildInscriptionPrompt(cours),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Contenu du cours',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
              ),
            ),
            SliverToBoxAdapter(
              child: estInscritAsync.maybeWhen(
                data: (estInscrit) => estInscrit
                    ? _buildModulesList()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Text('Inscrivez-vous pour accéder au contenu',
                            style: GoogleFonts.outfit(fontSize: 13, color: _AppColors.textTertiary)),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
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

  Widget _buildHeader(Map<String, dynamic> cours) {
    final imageUrl = cours['imageCouvertureCours'] as String?;
    final enseignant = cours['enseignant'] as Map<String, dynamic>?;
    final nomEns = '${enseignant?['user']?['prenomUser'] ?? ''} ${enseignant?['user']?['nomUser'] ?? 'Enseignant'}'.trim();

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      expandedHeight: 220,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: '$_kBaseUrl$imageUrl',
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: _AppColors.statBlueAccent),
                  )
                : Container(color: _AppColors.statBlueAccent),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cours['titreCours'] ?? 'Sans titre',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Par $nomEns', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: _AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
    );
  }

  Widget _buildInscriptionPrompt(Map<String, dynamic> cours) {
    final estGratuit = cours['estGratuitCours'] == true;
    final prix = cours['prixCours'];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Vous n'êtes pas encore inscrit", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
              Text(estGratuit ? 'Gratuit' : '${prix ?? 0} Ar',
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.statBlueAccent)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _inscriptionEnCours ? null : () => _confirmerInscription(cours),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.statBlueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _inscriptionEnCours
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text("S'inscrire au cours", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionSection() {
    final progressionAsync = ref.watch(progressionCoursProvider(widget.idCours));

    return progressionAsync.when(
      data: (progression) {
        final pourcentage = (progression['pourcentage'] as num?)?.toInt() ?? 0;
        final modulesTermines = progression['modulesTermines'] ?? 0;
        final totalModules = progression['totalModules'] ?? 0;

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Votre progression', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
                  Text('$pourcentage%', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.statBlueAccent)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pourcentage / 100,
                  minHeight: 8,
                  backgroundColor: _AppColors.border,
                  valueColor: AlwaysStoppedAnimation(pourcentage >= 100 ? _AppColors.statGreenAccent : _AppColors.statBlueAccent),
                ),
              ),
              const SizedBox(height: 12),
              Text('$modulesTermines/$totalModules modules terminés',
                  style: GoogleFonts.outfit(fontSize: 12, color: _AppColors.textSecondary)),
            ],
          ),
        );
      },
      loading: () => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 120,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildModulesList() {
    final modulesAsync = ref.watch(modulesCourProvider(widget.idCours));

    return modulesAsync.when(
      data: (modules) {
        if (modules.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text('Aucun module disponible', style: GoogleFonts.outfit(color: _AppColors.textSecondary)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(modules.length, (i) => _ModuleListItem(
              module: modules[i],
              idCours: widget.idCours,
              index: i + 1,
            )),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: List.generate(3, (i) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
            )),
          ),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Text(err.toString().replaceAll('Exception: ', ''), style: GoogleFonts.outfit(color: _AppColors.textSecondary)),
      ),
    );
  }
}

class _ModuleListItem extends StatelessWidget {
  final Map<String, dynamic> module;
  final String idCours;
  final int index;
  const _ModuleListItem({required this.module, required this.idCours, required this.index});

  @override
  Widget build(BuildContext context) {
    // Modules en BROUILLON ne sont pas accessibles à l'apprenant
    final estPublie = module['statutModule'] == 'PUBLIE';
    final nombreContenus = module['_count']?['contenus'] ?? 0;

    return Opacity(
      opacity: estPublie ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: estPublie
            ? () => context.go('/apprenant/cours/$idCours/module/${module['idModule']}')
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AppColors.statBlueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('M$index', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.statBlueAccent)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module['titreModule'] ?? 'Sans titre',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      estPublie ? '$nombreContenus contenus' : 'Non disponible',
                      style: GoogleFonts.outfit(fontSize: 12, color: _AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              if (estPublie) Icon(Icons.arrow_forward_ios, size: 16, color: _AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}