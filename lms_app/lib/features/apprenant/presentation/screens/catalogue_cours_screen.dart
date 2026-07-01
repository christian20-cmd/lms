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
  static const statPurple = Color(0xFFEEEDFE);
  static const statPurpleText = Color(0xFF4A3FB5);
}

const String _kBaseUrl = 'http://192.168.43.137:3000';

class CatalogueCoursScreen extends ConsumerStatefulWidget {
  const CatalogueCoursScreen({super.key});

  @override
  ConsumerState<CatalogueCoursScreen> createState() => _CatalogueCoursScreenState();
}

class _CatalogueCoursScreenState extends ConsumerState<CatalogueCoursScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(rechercheCatalogueProvider.notifier).state = value;
    ref.read(pageCatalogueProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final catalogueAsync = ref.watch(catalogueCoursProvider);
    final categoriesAsync = ref.watch(categoriesApprenantProvider);
    final niveau = ref.watch(filtreNiveauCatalogueProvider);
    final idCategorie = ref.watch(filtreCategorieCatalogueProvider);

    return Scaffold(
      backgroundColor: _AppColors.bg,
      appBar: AppBar(
        backgroundColor: _AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Explorer les cours',
            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600, color: _AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher un cours...',
                  hintStyle: GoogleFonts.outfit(color: const Color.fromARGB(255, 168, 162, 162)),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 185, 185, 182)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _NiveauChip(label: 'Tous niveaux', selected: niveau == null,
                      onTap: () { ref.read(filtreNiveauCatalogueProvider.notifier).state = null; ref.read(pageCatalogueProvider.notifier).state = 1; }),
                  const SizedBox(width: 8),
                  _NiveauChip(label: 'Débutant', selected: niveau == 'DEBUTANT',
                      onTap: () { ref.read(filtreNiveauCatalogueProvider.notifier).state = 'DEBUTANT'; ref.read(pageCatalogueProvider.notifier).state = 1; }),
                  const SizedBox(width: 8),
                  _NiveauChip(label: 'Intermédiaire', selected: niveau == 'INTERMEDIAIRE',
                      onTap: () { ref.read(filtreNiveauCatalogueProvider.notifier).state = 'INTERMEDIAIRE'; ref.read(pageCatalogueProvider.notifier).state = 1; }),
                  const SizedBox(width: 8),
                  _NiveauChip(label: 'Avancé', selected: niveau == 'AVANCE',
                      onTap: () { ref.read(filtreNiveauCatalogueProvider.notifier).state = 'AVANCE'; ref.read(pageCatalogueProvider.notifier).state = 1; }),
                  const SizedBox(width: 12),
                  categoriesAsync.maybeWhen(
                    data: (cats) => Row(
                      children: cats.map<Widget>((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _NiveauChip(
                          label: c['nomCategorie'] ?? '',
                          selected: idCategorie == c['idCategorie'],
                          onTap: () {
                            final current = ref.read(filtreCategorieCatalogueProvider);
                            ref.read(filtreCategorieCatalogueProvider.notifier).state =
                                current == c['idCategorie'] ? null : c['idCategorie'];
                            ref.read(pageCatalogueProvider.notifier).state = 1;
                          },
                        ),
                      )).toList(),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: catalogueAsync.when(
                data: (result) {
                  final cours = (result['cours'] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ??
                      <Map<String, dynamic>>[];
                  final totalPages = (result['totalPages'] as int?) ?? 1;
                  final page = (result['page'] as int?) ?? 1;

                  if (cours.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 56, color: _AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text('Aucun cours trouvé', style: GoogleFonts.outfit(fontSize: 15, color: _AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(catalogueCoursProvider);
                      await ref.read(catalogueCoursProvider.future);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        ...cours.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CatalogueCard(cours: c),
                        )),
                        if (totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: page > 1
                                      ? () => ref.read(pageCatalogueProvider.notifier).state = page - 1
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text('Page $page / $totalPages', style: GoogleFonts.outfit(fontSize: 13, color: _AppColors.textSecondary)),
                                IconButton(
                                  onPressed: page < totalPages
                                      ? () => ref.read(pageCatalogueProvider.notifier).state = page + 1
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Column(
                      children: List.generate(4, (i) => Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(999)),
                      )),
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(err.toString().replaceAll('Exception: ', ''),
                      style: GoogleFonts.outfit(color: _AppColors.textSecondary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NiveauChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NiveauChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _AppColors.statPurple : _AppColors.card,
          border: Border.all(color: selected ? const Color.fromARGB(255, 107, 104, 104) : _AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500,
              color: selected ? const Color.fromARGB(255, 0, 0, 0) : _AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _CatalogueCard extends StatelessWidget {
  final Map<String, dynamic> cours;
  const _CatalogueCard({required this.cours});

  @override
  Widget build(BuildContext context) {
    final imageUrl = cours['imageCouvertureCours'] as String?;
    final titre = cours['titreCours'] as String? ?? 'Sans titre';
    final description = cours['descriptionCours'] as String? ?? '';
    final estGratuit = cours['estGratuitCours'] == true;
    final prix = cours['prixCours'];
    final enseignant = cours['enseignant'] as Map<String, dynamic>?;
    final nomEns = '${enseignant?['user']?['prenomUser'] ?? ''} ${enseignant?['user']?['nomUser'] ?? ''}'.trim();

    return GestureDetector(
      onTap: () => context.go('/apprenant/cours/${cours['idCours']}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                width: 72, height: 72,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '$_kBaseUrl$imageUrl',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: const Color.fromARGB(255, 124, 126, 128).withOpacity(0.1),
                          child: Icon(Icons.school_outlined, color: const Color.fromARGB(255, 0, 0, 0)),
                        ),
                      )
                    : Container(
                        color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
                        child: Icon(Icons.school_outlined, color: const Color.fromARGB(255, 0, 0, 0)),
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
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 11, color: _AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (nomEns.isNotEmpty) ...[
                        Icon(Icons.person_outline, size: 12, color: _AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(nomEns, style: GoogleFonts.outfit(fontSize: 11, color: _AppColors.textTertiary)),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: estGratuit ? _AppColors.statPurple : _AppColors.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          estGratuit ? 'Gratuit' : '${prix ?? 0} Ar',
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                              color: estGratuit ? _AppColors.statPurpleText : _AppColors.textSecondary),
                        ),
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
}