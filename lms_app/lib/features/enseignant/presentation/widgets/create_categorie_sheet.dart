import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LMS/features/enseignant/presentation/providers/cours_provider.dart';

// ── Design tokens ──
class _AppColors {
  static const bg = Color(0xFFF8F8F6);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFFB8B8B8);
  static const border = Color(0xFFF0F0EE);
  static const danger = Color(0xFFE24B4A);
  static const dangerBg = Color(0xFFFCEBEB);
}

class CreateCategorieSheet extends ConsumerStatefulWidget {
  const CreateCategorieSheet({super.key});

  @override
  ConsumerState<CreateCategorieSheet> createState() => _CreateCategorieSheetState();
}

class _CreateCategorieSheetState extends ConsumerState<CreateCategorieSheet> {
  final _nomCtrl = TextEditingController();
  bool _loading = false;
  String? _erreur;

  @override
  void dispose() {
	_nomCtrl.dispose();
	super.dispose();
  }

  Future<void> _submit() async {
	final nom = _nomCtrl.text.trim();
	if (nom.isEmpty) {
	  setState(() => _erreur = 'Le nom est obligatoire');
	  return;
	}
	setState(() {
	  _loading = true;
	  _erreur = null;
	});
	try {
	  final res = await ref.read(coursNotifierProvider.notifier).creerCategorie(nom);
	  // Le backend renvoie { message, categorie }
	  if (mounted) Navigator.pop(context, res);
	} catch (e) {
	  setState(() => _erreur = 'Erreur lors de la création');
	} finally {
	  if (mounted) setState(() => _loading = false);
	}
  }

  @override
  Widget build(BuildContext context) {
	final bottomInset = MediaQuery.of(context).viewInsets.bottom;
	return Container(
	  decoration: const BoxDecoration(
		color: Colors.white,
		borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
	  ),
	  padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
	  child: SingleChildScrollView(
		child: Column(
		  crossAxisAlignment: CrossAxisAlignment.start,
		  mainAxisSize: MainAxisSize.min,
		  children: [
			Center(
			  child: Padding(
				padding: const EdgeInsets.only(top: 12, bottom: 16),
				child: Container(
				  width: 36,
				  height: 4,
				  decoration: BoxDecoration(
					color: _AppColors.border,
					borderRadius: BorderRadius.circular(2),
				  ),
				),
			  ),
			),
			Text('Nouvelle catégorie',
				style: GoogleFonts.dmSans(
					fontSize: 16,
					fontWeight: FontWeight.w600,
					color: _AppColors.textPrimary)),
			const SizedBox(height: 12),
			if (_erreur != null) ...[
			  Container(
				padding: const EdgeInsets.all(12),
				decoration: BoxDecoration(
				  color: _AppColors.dangerBg,
				  borderRadius: BorderRadius.circular(12),
				),
				child: Row(
				  children: [
					const Icon(Icons.error_outline,
						size: 16, color: _AppColors.danger),
					const SizedBox(width: 8),
					Expanded(
					  child: Text(_erreur!,
						  style: GoogleFonts.dmSans(
							  fontSize: 12,
							  color: _AppColors.danger)),
					),
				  ],
				),
			  ),
			  const SizedBox(height: 12),
			],
			_FormLabel('Nom de la catégorie'),
			_FormField(controller: _nomCtrl, hint: 'Ex: Développement'),
			const SizedBox(height: 18),
			GestureDetector(
			  onTap: _loading ? null : _submit,
			  child: Container(
				width: double.infinity,
				padding: const EdgeInsets.symmetric(vertical: 14),
				decoration: BoxDecoration(
				  color: _loading
					  ? _AppColors.textPrimary.withOpacity(0.6)
					  : _AppColors.textPrimary,
				  borderRadius: BorderRadius.circular(12),
				),
				child: _loading
					? const Center(
						child: SizedBox(
						  width: 18,
						  height: 18,
						  child: CircularProgressIndicator(
							  strokeWidth: 2, color: Colors.white),
						),
					  )
					: Text('Créer la catégorie',
						textAlign: TextAlign.center,
						style: GoogleFonts.dmSans(
							fontSize: 14,
							fontWeight: FontWeight.w600,
							color: Colors.white)),
			  ),
			),
		  ],
		),
	  ),
	);
  }
}

// ── Helpers formulaire ──
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
	return Padding(
	  padding: const EdgeInsets.only(bottom: 6),
	  child: Text(text,
		  style: GoogleFonts.dmSans(
			  fontSize: 12,
			  fontWeight: FontWeight.w600,
			  color: _AppColors.textSecondary)),
	);
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _FormField({
	required this.controller,
	required this.hint,
	this.maxLines = 1,
	this.keyboardType,
	this.suffix,
  });

  @override
  Widget build(BuildContext context) {
	return Container(
	  decoration: BoxDecoration(
		color: _AppColors.bg,
		borderRadius: BorderRadius.circular(12),
		border: Border.all(color: _AppColors.border),
	  ),
	  child: TextField(
		controller: controller,
		maxLines: maxLines,
		keyboardType: keyboardType,
		style: GoogleFonts.dmSans(
			fontSize: 13, color: _AppColors.textPrimary),
		decoration: InputDecoration(
		  hintText: hint,
		  hintStyle: GoogleFonts.dmSans(
			  fontSize: 13, color: _AppColors.textTertiary),
		  border: InputBorder.none,
		  contentPadding:
			  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
		  suffixIcon: suffix != null
			  ? Padding(
				  padding: const EdgeInsets.only(right: 12),
				  child: suffix,
				)
			  : null,
		  suffixIconConstraints:
			  const BoxConstraints(minWidth: 0, minHeight: 0),
		),
	  ),
	);
  }
}
