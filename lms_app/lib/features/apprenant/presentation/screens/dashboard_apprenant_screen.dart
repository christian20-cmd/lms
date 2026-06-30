import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:LMS/features/apprenant/providers/apprenant_provider.dart';
import 'package:LMS/features/auth/presentation/providers/auth_provider.dart';

class _AppColors {
  static const bg = Color(0xFFF8F8F6);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFFB8B8B8);
  static const border = Color(0xFFF0F0EE);

  static const statBlue = Color(0xFFE8F1FB);
  static const statBlueText = Color(0xFF1A5FA8);
  static const statBlueAccent = Color(0xFF3B8DDD);

  static const statGreen = Color(0xFFE8F5EE);
  static const statGreenText = Color(0xFF1A6B3C);
  static const statGreenAccent = Color(0xFF2EA862);

  static const statAmber = Color(0xFFFAF0DC);
  static const statAmberText = Color(0xFF8A5A0A);
  static const statAmberAccent = Color(0xFFEA9F25);
}

const String _kBaseUrl = 'http://localhost:3000';

class DashboardApprenantScreen extends ConsumerStatefulWidget {
  const DashboardApprenantScreen({super.key});

  @override
  ConsumerState<DashboardApprenantScreen> createState() =>
      _DashboardApprenantScreenState();
}

class _DashboardApprenantScreenState
    extends ConsumerState<DashboardApprenantScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _entryFade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(statistiquesApprenantProvider);

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(statistiquesApprenantProvider);
                await ref.read(statistiquesApprenantProvider.future);
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: false,
                    expandedHeight: 100,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenue, ${authState.user?.prenomUser ?? 'Apprenant'}',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Continuez votre apprentissage',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: _AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: statsAsync.when(
                      data: (stats) => _buildStatsSection(stats),
                      loading: () => _buildStatsShimmer(),
                      error: (err, stack) => SizedBox(
                        height: 100,
                        child: Center(
                          child: Text(
                            err.toString().replaceAll('Exception: ', ''),
                            style: GoogleFonts.outfit(color: _AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                      child: Text(
                        'Continuer un cours',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: statsAsync.when(
                      data: (stats) => _buildCoursEnCours(stats),
                      loading: () => _buildListShimmer(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final globales = stats['statsGlobales'] as Map<String, dynamic>? ?? {};
    final totalCours = globales['totalCours'] ?? 0;
    final coursTermines = globales['coursTermines'] ?? 0;
    final progressionMoyenne = globales['progressionMoyenne'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Cours inscrits',
              value: totalCours.toString(),
              bgColor: _AppColors.statBlue,
              textColor: _AppColors.statBlueText,
              accentColor: _AppColors.statBlueAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Terminés',
              value: coursTermines.toString(),
              bgColor: _AppColors.statGreen,
              textColor: _AppColors.statGreenText,
              accentColor: _AppColors.statGreenAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Progression',
              value: '$progressionMoyenne%',
              bgColor: _AppColors.statAmber,
              textColor: _AppColors.statAmberText,
              accentColor: _AppColors.statAmberAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: List.generate(3, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(2, (i) => Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildCoursEnCours(Map<String, dynamic> stats) {
    final coursEnCours = (stats['coursEnCours'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (coursEnCours.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.school_outlined, size: 48, color: _AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(
                'Aucun cours en cours',
                style: GoogleFonts.outfit(color: _AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: coursEnCours.map((c) => _CoursEnCoursTile(cours: c)).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color textColor;
  final Color accentColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _CoursEnCoursTile extends StatelessWidget {
  final Map<String, dynamic> cours;
  const _CoursEnCoursTile({required this.cours});

  @override
  Widget build(BuildContext context) {
    final progression = (cours['progression'] as num?)?.toInt() ?? 0;
    final imageUrl = cours['imageCouvertureCours'] as String?;
    final titre = cours['titreCours'] as String? ?? 'Sans titre';

    return GestureDetector(
      onTap: () => context.go('/apprenant/cours/${cours['idCours']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '$_kBaseUrl$imageUrl',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: _AppColors.statBlue),
                        errorWidget: (_, __, ___) => Container(
                          color: _AppColors.statBlue,
                          child: Icon(Icons.school_outlined, color: _AppColors.statBlueAccent),
                        ),
                      )
                    : Container(
                        color: _AppColors.statBlue,
                        child: Icon(Icons.school_outlined, color: _AppColors.statBlueAccent),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progression / 100,
                      minHeight: 4,
                      backgroundColor: _AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(_AppColors.statBlueAccent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$progression% complété', style: GoogleFonts.outfit(fontSize: 11, color: _AppColors.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: _AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}