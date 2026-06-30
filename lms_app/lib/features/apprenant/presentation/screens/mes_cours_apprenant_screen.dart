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

class MesCoursApprenantScreen extends ConsumerStatefulWidget {
  const MesCoursApprenantScreen({super.key});

  @override
  ConsumerState<MesCoursApprenantScreen> createState() =>
      _MesCoursApprenantScreenState();
}

class _MesCoursApprenantScreenState
    extends ConsumerState<MesCoursApprenantScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _entryFade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _entryController.forward();
    });

    _searchController.addListener(() {
      ref.read(rechercheCoursApprenantProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── getMesCoursList renvoie des Inscription avec un Cours imbriqué.
  // dateCompletionCours non-null = cours terminé.
  bool _estTermine(Map<String, dynamic> inscription) =>
      inscription['dateCompletionCours'] != null;

  @override
  Widget build(BuildContext context) {
    final recherche = ref.watch(rechercheCoursApprenantProvider).toLowerCase();
    final filtre = ref.watch(filtreEtatCoursProvider);
    final viewMode = ref.watch(viewModeApprenantProvider);
    final coursAsync = ref.watch(mesCoursApprenantProvider);

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: FadeTransition(
        opacity: _entryFade,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(mesCoursApprenantProvider);
              await ref.read(mesCoursApprenantProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mes cours',
                            style: GoogleFonts.outfit(
                                fontSize: 26, fontWeight: FontWeight.w700, color: _AppColors.textPrimary)),
                        GestureDetector(
                          onTap: () => context.go('/apprenant/catalogue'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.add, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Explorer', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un cours...',
                            hintStyle: GoogleFonts.outfit(color: _AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _AppColors.border),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _FilterChip(label: 'Tous', selected: filtre == 'tous',
                                onTap: () => ref.read(filtreEtatCoursProvider.notifier).state = 'tous'),
                            const SizedBox(width: 8),
                            _FilterChip(label: 'En cours', selected: filtre == 'en_cours',
                                onTap: () => ref.read(filtreEtatCoursProvider.notifier).state = 'en_cours'),
                            const SizedBox(width: 8),
                            _FilterChip(label: 'Terminés', selected: filtre == 'termines',
                                onTap: () => ref.read(filtreEtatCoursProvider.notifier).state = 'termines'),
                            const Spacer(),
                            _ViewModeButton(icon: Icons.grid_view, isSelected: viewMode == 'grid',
                                onTap: () => ref.read(viewModeApprenantProvider.notifier).state = 'grid'),
                            _ViewModeButton(icon: Icons.view_list, isSelected: viewMode == 'list',
                                onTap: () => ref.read(viewModeApprenantProvider.notifier).state = 'list'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: coursAsync.when(
                    data: (inscriptions) {
                      var filtered = inscriptions.where((i) {
                        final cours = i['cours'] as Map<String, dynamic>? ?? {};
                        final titre = (cours['titreCours'] as String? ?? '').toLowerCase();
                        if (recherche.isNotEmpty && !titre.contains(recherche)) return false;
                        if (filtre == 'en_cours') return !_estTermine(i);
                        if (filtre == 'termines') return _estTermine(i);
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.school_outlined, size: 56, color: _AppColors.textTertiary),
                                const SizedBox(height: 16),
                                Text('Aucun cours trouvé', style: GoogleFonts.outfit(fontSize: 15, color: _AppColors.textSecondary)),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () => context.go('/apprenant/catalogue'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(color: _AppColors.textPrimary, borderRadius: BorderRadius.circular(12)),
                                    child: Text('Explorer le catalogue', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: viewMode == 'grid'
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, i) => _CoursCardGrid(
                                  inscription: filtered[i],
                                  estTermine: _estTermine(filtered[i]),
                                ),
                              )
                            : Column(
                                children: filtered.map((i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CoursCardList(inscription: i, estTermine: _estTermine(i)),
                                )).toList(),
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
                            height: 110,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                          )),
                        ),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      child: Center(child: Text(err.toString().replaceAll('Exception: ', ''),
                          style: GoogleFonts.outfit(color: _AppColors.textSecondary))),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _AppColors.statBlueAccent : Colors.transparent,
          border: Border.all(color: selected ? _AppColors.statBlueAccent : _AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _AppColors.textSecondary)),
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ViewModeButton({required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: isSelected ? _AppColors.statBlueAccent : _AppColors.textTertiary),
      ),
    );
  }
}

class _CoursCardGrid extends StatelessWidget {
  final Map<String, dynamic> inscription;
  final bool estTermine;
  const _CoursCardGrid({required this.inscription, required this.estTermine});

  @override
  Widget build(BuildContext context) {
    final cours = inscription['cours'] as Map<String, dynamic>? ?? {};
    final imageUrl = cours['imageCouvertureCours'] as String?;
    final titre = cours['titreCours'] as String? ?? 'Sans titre';

    return GestureDetector(
      onTap: () => context.go('/apprenant/cours/${cours['idCours']}'),
      child: Container(
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '$_kBaseUrl$imageUrl',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: _AppColors.statBlueAccent.withOpacity(0.1)),
                        errorWidget: (_, __, ___) => Container(
                          color: _AppColors.statBlueAccent.withOpacity(0.1),
                          child: Icon(Icons.school_outlined, color: _AppColors.statBlueAccent),
                        ),
                      )
                    : Container(
                        color: _AppColors.statBlueAccent.withOpacity(0.1),
                        child: Icon(Icons.school_outlined, color: _AppColors.statBlueAccent),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(estTermine ? Icons.check_circle : Icons.play_circle_outline,
                          size: 12, color: estTermine ? _AppColors.statGreenAccent : _AppColors.statBlueAccent),
                      const SizedBox(width: 4),
                      Text(estTermine ? 'Terminé' : 'En cours',
                          style: GoogleFonts.outfit(fontSize: 10,
                              color: estTermine ? _AppColors.statGreenAccent : _AppColors.statBlueAccent)),
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
}

class _CoursCardList extends StatelessWidget {
  final Map<String, dynamic> inscription;
  final bool estTermine;
  const _CoursCardList({required this.inscription, required this.estTermine});

  @override
  Widget build(BuildContext context) {
    final cours = inscription['cours'] as Map<String, dynamic>? ?? {};
    final imageUrl = cours['imageCouvertureCours'] as String?;
    final titre = cours['titreCours'] as String? ?? 'Sans titre';
    final totalModules = cours['_count']?['modules'] ?? 0;

    return GestureDetector(
      onTap: () => context.go('/apprenant/cours/${cours['idCours']}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64, height: 64,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '$_kBaseUrl$imageUrl',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: _AppColors.statBlueAccent.withOpacity(0.1),
                          child: Icon(Icons.school_outlined, color: _AppColors.statBlueAccent),
                        ),
                      )
                    : Container(
                        color: _AppColors.statBlueAccent.withOpacity(0.1),
                        child: Icon(Icons.school_outlined, color: _AppColors.statBlueAccent),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('$totalModules modules', style: GoogleFonts.outfit(fontSize: 12, color: _AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(estTermine ? Icons.check_circle : Icons.play_circle_outline,
                          size: 13, color: estTermine ? _AppColors.statGreenAccent : _AppColors.statBlueAccent),
                      const SizedBox(width: 4),
                      Text(estTermine ? 'Terminé' : 'En cours',
                          style: GoogleFonts.outfit(fontSize: 11,
                              color: estTermine ? _AppColors.statGreenAccent : _AppColors.statBlueAccent)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: _AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}