import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../data/localisation_remote_datasource.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final String nomUser;
  final String prenomUser;
  final String emailUser;
  final String? photoProfilUser;

  const CompleteProfileScreen({
    super.key,
    required this.nomUser,
    required this.prenomUser,
    required this.emailUser,
    this.photoProfilUser,
  });

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  int _step = 1;

  final _bioController = TextEditingController();
  final _telController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _titreController = TextEditingController();

  String _role = '';
  String _niveau = '';
  bool _isLoading = false;
  String _error = '';

  // Localisation
  List<dynamic> _pays = [];
  List<dynamic> _villes = [];
  List<dynamic> _operateurs = [];
  Map<String, dynamic>? _paysSelectionne;
  Map<String, dynamic>? _villeSelectionnee;
  Map<String, dynamic>? _operateurSelectionne;
  bool _loadingPays = false;
  bool _loadingVilles = false;
  bool _loadingOperateurs = false;

  @override
  void initState() {
    super.initState();
    _chargerPays();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _telController.dispose();
    _specialiteController.dispose();
    _titreController.dispose();
    super.dispose();
  }

  Future<void> _chargerPays() async {
    setState(() => _loadingPays = true);
    try {
      final datasource = LocalisationRemoteDatasource(ref.read(dioProvider));
      final pays = await datasource.getPays();
      setState(() => _pays = pays);
    } catch (e) {
      debugPrint('Erreur chargement pays: $e');
    } finally {
      setState(() => _loadingPays = false);
    }
  }

  Future<void> _chargerVilles(String idPays) async {
    setState(() {
      _loadingVilles = true;
      _villes = [];
      _villeSelectionnee = null;
    });
    try {
      final datasource = LocalisationRemoteDatasource(ref.read(dioProvider));
      final villes = await datasource.getVillesByPays(idPays);
      setState(() => _villes = villes);
    } catch (e) {
      debugPrint('Erreur chargement villes: $e');
    } finally {
      setState(() => _loadingVilles = false);
    }
  }

  Future<void> _chargerOperateurs(String idPays) async {
    setState(() {
      _loadingOperateurs = true;
      _operateurs = [];
      _operateurSelectionne = null;
    });
    try {
      final datasource = LocalisationRemoteDatasource(ref.read(dioProvider));
      final operateurs = await datasource.getOperateursByPays(idPays);
      setState(() => _operateurs = operateurs);
    } catch (e) {
      debugPrint('Erreur chargement opérateurs: $e');
    } finally {
      setState(() => _loadingOperateurs = false);
    }
  }

  String _cleanError(dynamic e) =>
      e.toString().replaceAll('Exception: ', '').replaceAll('Exception:', '');

  Future<void> _completerProfil() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await ref.read(authProvider.notifier).completerProfil(
        roleUser: _role,
        idVille: _villeSelectionnee?['idVille'],
        idOperateur: _operateurSelectionne?['idOperateur'],
        numeroTelUser: _telController.text.trim().isNotEmpty
            ? _telController.text.trim()
            : null,
        bioUser: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        niveauApprenant:
            _role == 'APPRENANT' && _niveau.isNotEmpty ? _niveau : null,
        specialiteEnseignant: _role == 'ENSEIGNANT'
            ? _specialiteController.text.trim()
            : null,
        titreProfessionnelEnseignant: _role == 'ENSEIGNANT'
            ? _titreController.text.trim()
            : null,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (_step == 1) return;
    setState(() {
      _error = '';
      _step--;
    });
  }

  // ── BottomSheet Pays ──
  void _showPaysBottomSheet() {
    final searchController = TextEditingController();
    List<dynamic> filtered = List.from(_pays);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text('Sélectionner un pays',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un pays...',
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey[400]),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey[400], size: 18),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              filtered = _pays
                                  .where((p) => p['nomPays']
                                      .toString()
                                      .toLowerCase()
                                      .contains(val.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final pays = filtered[index];
                          final isSelected =
                              _paysSelectionne?['idPays'] == pays['idPays'];
                          return ListTile(
                            leading: _buildFlag(pays['codeIso']),
                            title: Text(pays['nomPays'],
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                            trailing: Text(pays['indicatif'],
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.grey[400])),
                            selected: isSelected,
                            selectedTileColor: Colors.grey[50],
                            onTap: () {
                              setState(() {
                                _paysSelectionne = pays;
                                _villeSelectionnee = null;
                                _operateurSelectionne = null;
                                _villes = [];
                                _operateurs = [];
                                _telController.clear();
                              });
                              _chargerVilles(pays['idPays']);
                              _chargerOperateurs(pays['idPays']);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showVilleBottomSheet() {
    if (_villes.isEmpty) return;
    final searchController = TextEditingController();
    List<dynamic> filtered = List.from(_villes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text('Sélectionner une ville',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Rechercher une ville...',
                            hintStyle: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey[400]),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey[400], size: 18),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              filtered = _villes
                                  .where((v) => v['nomVille']
                                      .toString()
                                      .toLowerCase()
                                      .contains(val.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final ville = filtered[index];
                          final isSelected =
                              _villeSelectionnee?['idVille'] == ville['idVille'];
                          return ListTile(
                            leading: Icon(Icons.location_city_outlined,
                                color: Colors.grey[400], size: 20),
                            title: Text(ville['nomVille'],
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                            selected: isSelected,
                            selectedTileColor: Colors.grey[50],
                            onTap: () {
                              setState(() => _villeSelectionnee = ville);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showOperateurBottomSheet() {
    if (_operateurs.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Sélectionner un opérateur',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ..._operateurs.map((op) {
                final isSelected =
                    _operateurSelectionne?['idOperateur'] == op['idOperateur'];
                return ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(op['nomOperateur'][0],
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600])),
                    ),
                  ),
                  title: Text(op['nomOperateur'],
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  subtitle: Text(
                    'Préfixes: ${(op['prefixes'] as List).join(', ')} — ${op['longueurNumero']} chiffres',
                    style:
                        GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: Colors.black, size: 18)
                      : null,
                  onTap: () {
                    setState(() {
                      _operateurSelectionne = op;
                      _telController.clear();
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlag(String? codeIso) {
    if (codeIso == null) return const SizedBox(width: 24);
    return Image.network(
      'https://flagcdn.com/24x18/${codeIso.toLowerCase()}.png',
      width: 24, height: 18,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox(width: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step > 1)
                GestureDetector(
                  onTap: _goBack,
                  child: const Icon(Icons.chevron_left,
                      size: 32, color: Colors.black54),
                ),
              const SizedBox(height: 24),
              _buildProgressBar(),
              const SizedBox(height: 28),

              // Header avec photo Google/GitHub
              Row(
                children: [
                  if (widget.photoProfilUser != null &&
                      widget.photoProfilUser!.isNotEmpty)
                    CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          NetworkImage(widget.photoProfilUser!),
                    ),
                  if (widget.photoProfilUser != null &&
                      widget.photoProfilUser!.isNotEmpty)
                    const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_stepTitle(),
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.black)),
                      Text(_stepSubtitle(),
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.grey[400])),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
              if (_step == 4) _buildStep4(),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 1: return 'Votre rôle';
      case 2: return 'Localisation';
      case 3: return 'Votre profil';
      case 4: return 'Dernière étape';
      default: return '';
    }
  }

  String _stepSubtitle() {
    switch (_step) {
      case 1: return 'Choisissez votre rôle sur la plateforme';
      case 2: return 'Où êtes-vous situé ?';
      case 3: return 'Quelques infos supplémentaires';
      case 4: return 'Complétez votre profil';
      default: return '';
    }
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index < _step;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            height: 3,
            decoration: BoxDecoration(
              color: isActive ? Colors.black : Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // ── STEP 1 — Rôle ──
  Widget _buildStep1() {
    return Column(
      children: [
        _buildRoleCard(
            role: 'APPRENANT',
            title: 'Apprenant',
            subtitle: 'Je veux accéder à des cours',
            icon: Icons.school_outlined),
        const SizedBox(height: 12),
        _buildRoleCard(
            role: 'ENSEIGNANT',
            title: 'Enseignant',
            subtitle: 'Je veux créer et partager des cours',
            icon: Icons.cast_for_education_outlined),
        const SizedBox(height: 24),
        _buildPrimaryButton(
            label: 'Continuer',
            icon: Icons.chevron_right,
            disabled: _role.isEmpty,
            onTap: () => setState(() => _step = 2)),
      ],
    );
  }

  Widget _buildRoleCard(
      {required String role,
      required String title,
      required String subtitle,
      required IconData icon}) {
    final isSelected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: isSelected ? Colors.black : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.grey[600], size: 24),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color:
                            isSelected ? Colors.white70 : Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 2 — Localisation ──
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Pays'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _loadingPays ? null : _showPaysBottomSheet,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                if (_paysSelectionne != null) ...[
                  _buildFlag(_paysSelectionne!['codeIso']),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(_paysSelectionne!['nomPays'],
                          style: GoogleFonts.poppins(fontSize: 13))),
                  Text(_paysSelectionne!['indicatif'],
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[400])),
                ] else ...[
                  Expanded(
                      child: Text(
                    _loadingPays ? 'Chargement...' : 'Sélectionner un pays',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[400]),
                  )),
                ],
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Ville (optionnel)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: (_paysSelectionne == null || _loadingVilles)
              ? null
              : _showVilleBottomSheet,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _paysSelectionne == null
                  ? Colors.grey[50]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(children: [
              Expanded(
                  child: Text(
                _loadingVilles
                    ? 'Chargement...'
                    : _villeSelectionnee != null
                        ? _villeSelectionnee!['nomVille']
                        : _paysSelectionne == null
                            ? 'Sélectionnez d\'abord un pays'
                            : 'Sélectionner une ville',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _villeSelectionnee != null
                        ? Colors.black
                        : Colors.grey[400]),
              )),
              Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey[400], size: 20),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _buildLabel('Opérateur (optionnel)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: (_paysSelectionne == null || _loadingOperateurs)
              ? null
              : _showOperateurBottomSheet,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _paysSelectionne == null
                  ? Colors.grey[50]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(children: [
              Expanded(
                  child: Text(
                _loadingOperateurs
                    ? 'Chargement...'
                    : _operateurSelectionne != null
                        ? _operateurSelectionne!['nomOperateur']
                        : _paysSelectionne == null
                            ? 'Sélectionnez d\'abord un pays'
                            : 'Sélectionner un opérateur',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _operateurSelectionne != null
                        ? Colors.black
                        : Colors.grey[400]),
              )),
              Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey[400], size: 20),
            ]),
          ),
        ),
        if (_operateurSelectionne != null) ...[
          const SizedBox(height: 16),
          _buildLabel('Numéro de téléphone (optionnel)'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(children: [
                  _buildFlag(_paysSelectionne!['codeIso']),
                  const SizedBox(width: 6),
                  Text(_paysSelectionne!['indicatif'],
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700])),
                ]),
              ),
              Expanded(
                child: TextField(
                  controller: _telController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  maxLength: _operateurSelectionne!['longueurNumero'],
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        '${_operateurSelectionne!['longueurNumero']} chiffres',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[400]),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Continuer',
          icon: Icons.chevron_right,
          disabled: false,
          onTap: () => setState(() => _step = 3),
        ),
      ],
    );
  }

  // ── STEP 3 — Bio ──
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Bio (optionnel)'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: _bioController,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Parlez un peu de vous...',
              hintStyle:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Continuer',
          icon: Icons.chevron_right,
          disabled: false,
          onTap: () => setState(() => _step = 4),
        ),
      ],
    );
  }

  // ── STEP 4 — Champs spécifiques rôle ──
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_role == 'ENSEIGNANT') ...[
          _buildLabel('Spécialité (optionnel)'),
          const SizedBox(height: 6),
          _buildTextInput(
              controller: _specialiteController,
              hint: 'Ex: Mathématiques, Informatique...',
              onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          _buildLabel('Titre professionnel (optionnel)'),
          const SizedBox(height: 6),
          _buildTextInput(
              controller: _titreController,
              hint: 'Ex: Professeur, Ingénieur...',
              onChanged: (_) => setState(() {})),
        ],
        if (_role == 'APPRENANT') ...[
          _buildLabel('Niveau (optionnel)'),
          const SizedBox(height: 6),
          _buildNiveauSelector(),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildErrorBox(_error),
        ],
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: _isLoading ? 'Finalisation...' : 'Terminer',
          icon: Icons.check,
          disabled: _isLoading,
          isLoading: _isLoading,
          onTap: _completerProfil,
        ),
      ],
    );
  }

  Widget _buildNiveauSelector() {
    final niveaux = ['DEBUTANT', 'INTERMEDIAIRE', 'AVANCE'];
    final labels = {
      'DEBUTANT': 'Débutant',
      'INTERMEDIAIRE': 'Intermédiaire',
      'AVANCE': 'Avancé'
    };
    return Row(
      children: niveaux.map((n) {
        final isSelected = _niveau == n;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _niveau = n),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[200]!),
              ),
              child: Center(
                  child: Text(labels[n]!,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? Colors.white : Colors.grey[600]))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700]));
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.red[600]))),
      ]),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required bool disabled,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
              else
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              if (!isLoading) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}