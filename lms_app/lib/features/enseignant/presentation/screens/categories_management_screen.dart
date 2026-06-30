import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LMS/features/enseignant/presentation/providers/cours_provider.dart';
import 'package:LMS/features/enseignant/presentation/widgets/create_categorie_sheet.dart';

class CategoriesManagementScreen extends ConsumerWidget {
  const CategoriesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
	final catsAsync = ref.watch(categoriesProvider);

	return Scaffold(
	  appBar: AppBar(
		title: Text('Catégories', style: GoogleFonts.dmSans()),
		backgroundColor: Colors.white,
		foregroundColor: Colors.black,
		elevation: 0,
	  ),
	  body: catsAsync.when(
		loading: () => const Center(child: CircularProgressIndicator()),
		error: (e, _) => Center(child: Text('Erreur chargement', style: GoogleFonts.dmSans())),
		data: (cats) {
		  return ListView.builder(
			padding: const EdgeInsets.all(16),
			itemCount: cats.length,
			itemBuilder: (context, i) {
			  final c = cats[i];
			  return ListTile(
				title: Text(c['nomCategorie'] ?? ''),
				subtitle: c['iconeCategorie'] != null ? Text(c['iconeCategorie']) : null,
			  );
			},
		  );
		},
	  ),
		  floatingActionButton: FloatingActionButton(
			onPressed: () async {
			  final res = await showModalBottomSheet<Map<String, dynamic>>(
				context: context,
				isScrollControlled: true,
				backgroundColor: Colors.transparent,
				builder: (_) => const CreateCategorieSheet(),
			  );
			  if (res != null) ref.invalidate(categoriesProvider);
			},
			child: const Icon(Icons.add),
		  ),
		  );
		}
		}
