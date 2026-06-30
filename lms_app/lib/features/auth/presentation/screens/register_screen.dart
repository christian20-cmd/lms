import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../../data/localisation_remote_datasource.dart';

final nomStatusProvider = StateProvider<String>((ref) => 'idle');
final prenomStatusProvider = StateProvider<String>((ref) => 'idle');
final emailInscriptionStatusProvider = StateProvider<String>((ref) => 'idle');

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 1;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telController = TextEditingController();
  final _bioController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _titreController = TextEditingController();

  String _role = '';
  String _niveau = '';
  String _idEtablissement = '';
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  String _error = '';
  String _codeError = '';
  String _codeStatus = 'idle'; // idle | verifying | verified | invalid
  Timer? _emailDebounce;
  File? _photoFile;

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
    _emailDebounce?.cancel();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    for (final c in _codeControllers) c.dispose();
    for (final f in _codeFocusNodes) f.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telController.dispose();
    _bioController.dispose();
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
    setState(() { _loadingVilles = true; _villes = []; _villeSelectionnee = null; });
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
    setState(() { _loadingOperateurs = true; _operateurs = []; _operateurSelectionne = null; });
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

  // ── Validations ──

  Future<void> _validerNomPrenom() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      await ref.read(authProvider.notifier).validerNomPrenom(
        nomUser: _nomController.text.trim(),
        prenomUser: _prenomController.text.trim(),
      );
      setState(() => _step = 3);
    } catch (e) {
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifierEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    ref.read(emailInscriptionStatusProvider.notifier).state = 'checking';
    try {
      await ref.read(authProvider.notifier).verifierEmailInscription(email);
      if (mounted) ref.read(emailInscriptionStatusProvider.notifier).state = 'available';
    } catch (e) {
      if (mounted) ref.read(emailInscriptionStatusProvider.notifier).state = 'taken';
    }
  }

  Future<void> _envoyerCode() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      await ref.read(authProvider.notifier).envoyerCode(_emailController.text.trim());
      setState(() => _step = 4);
    } catch (e) {
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifierCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 6) return;

    setState(() { _codeStatus = 'verifying'; _codeError = ''; });
    try {
      await ref.read(authProvider.notifier).verifierCode(
        emailUser: _emailController.text.trim(),
        code: code,
      );
      setState(() { _codeStatus = 'verified'; });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _step = 5);
    } catch (e) {
      setState(() {
        _codeStatus = 'invalid';
        _codeError = _cleanError(e);
      });
      for (final c in _codeControllers) c.clear();
      _codeFocusNodes[0].requestFocus();
    }
  }

  Future<void> _validerPassword() async {
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    try {
      await ref.read(authProvider.notifier).validerPassword(_passwordController.text.trim());
      setState(() => _step = 6);
    } catch (e) {
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photoFile = File(picked.path));
  }

  Future<void> _register() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      await ref.read(authProvider.notifier).register(
        nomUser: _nomController.text.trim(),
        prenomUser: _prenomController.text.trim(),
        emailUser: _emailController.text.trim(),
        passwordUser: _passwordController.text.trim(),
        roleUser: _role,
        numeroTelUser: _telController.text.trim().isNotEmpty ? _telController.text.trim() : null,
        idVille: _villeSelectionnee?['idVille'],
        idOperateur: _operateurSelectionne?['idOperateur'],
        bioUser: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        specialiteEnseignant: _role == 'ENSEIGNANT' ? _specialiteController.text.trim() : null,
        titreProfessionnelEnseignant: _role == 'ENSEIGNANT' ? _titreController.text.trim() : null,
        niveauApprenant: _role == 'APPRENANT' && _niveau.isNotEmpty ? _niveau : null,
        idEtablissement: _role == 'APPRENANT' && _idEtablissement.isNotEmpty ? _idEtablissement : null,
      );
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    } catch (e) {
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (_step == 1) context.go('/login');
    else setState(() { _error = ''; _codeError = ''; _step--; });
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
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('Sélectionner un pays',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    // Recherche
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 18),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              filtered = _pays.where((p) =>
                                p['nomPays'].toString().toLowerCase().contains(val.toLowerCase())
                              ).toList();
                            });
                          },
                        ),
                      ),
                    ),
                    // Liste
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final pays = filtered[index];
                          final isSelected = _paysSelectionne?['idPays'] == pays['idPays'];
                          return ListTile(
                            leading: _buildFlag(pays['codeIso']),
                            title: Text(pays['nomPays'],
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                            trailing: Text(pays['indicatif'],
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
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

  // ── BottomSheet Ville ──
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('Sélectionner une ville',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 18),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              filtered = _villes.where((v) =>
                                v['nomVille'].toString().toLowerCase().contains(val.toLowerCase())
                              ).toList();
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
                          final isSelected = _villeSelectionnee?['idVille'] == ville['idVille'];
                          return ListTile(
                            leading: Icon(Icons.location_city_outlined,
                                color: Colors.grey[400], size: 20),
                            title: Text(ville['nomVille'],
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
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

  // ── BottomSheet Opérateur ──
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Sélectionner un opérateur',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ..._operateurs.map((op) {
                final isSelected = _operateurSelectionne?['idOperateur'] == op['idOperateur'];
                return ListTile(
                  leading: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        op['nomOperateur'][0],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  title: Text(op['nomOperateur'],
                      style: GoogleFonts.poppins(fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  subtitle: Text(
                    'Préfixes: ${(op['prefixes'] as List).join(', ')} — ${op['longueurNumero']} chiffres',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.black, size: 18)
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
              GestureDetector(
                onTap: _goBack,
                child: const Icon(Icons.chevron_left, size: 32, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              _buildProgressBar(),
              const SizedBox(height: 28),
              Text(_stepTitle(),
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 30, fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic, color: Colors.black)),
              const SizedBox(height: 4),
              Text(_stepSubtitle(),
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400])),
              const SizedBox(height: 32),
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
              if (_step == 4) _buildStep4(),
              if (_step == 5) _buildStep5(),
              if (_step == 6) _buildStep6(),
              if (_step == 7) _buildStep7(),
              if (_step == 8) _buildStep8(),
              const SizedBox(height: 32),
              Divider(color: Colors.grey[200]),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà un compte ? ",
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text("Se connecter",
                          style: GoogleFonts.poppins(fontSize: 13,
                              fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 1: return 'Qui êtes-vous ?';
      case 2: return 'Votre identité';
      case 3: return 'Votre email';
      case 4: return 'Vérification';
      case 5: return 'Mot de passe';
      case 6: return 'Localisation';
      case 7: return 'Votre profil';
      case 8: return 'Dernière étape';
      default: return '';
    }
  }

  String _stepSubtitle() {
    switch (_step) {
      case 1: return 'Choisissez votre rôle sur la plateforme';
      case 2: return 'Entrez votre nom et prénom';
      case 3: return 'Entrez votre adresse email';
      case 4: return 'Entrez le code reçu par email';
      case 5: return 'Créez un mot de passe sécurisé';
      case 6: return 'Où êtes-vous situé ?';
      case 7: return 'Photo de profil et bio';
      case 8: return 'Complétez votre profil';
      default: return '';
    }
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(8, (index) {
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
        _buildRoleCard(role: 'APPRENANT', title: 'Apprenant',
            subtitle: 'Je veux accéder à des cours', icon: Icons.school_outlined),
        const SizedBox(height: 12),
        _buildRoleCard(role: 'ENSEIGNANT', title: 'Enseignant',
            subtitle: 'Je veux créer et partager des cours',
            icon: Icons.cast_for_education_outlined),
        const SizedBox(height: 24),
        _buildPrimaryButton(label: 'Continuer', icon: Icons.chevron_right,
            disabled: _role.isEmpty, onTap: () => setState(() => _step = 2)),
      ],
    );
  }

  Widget _buildRoleCard({required String role, required String title,
      required String subtitle, required IconData icon}) {
    final isSelected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.black : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 24),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black)),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12,
                  color: isSelected ? Colors.white70 : Colors.grey[500])),
            ]),
          ],
        ),
      ),
    );
  }

  // ── STEP 2 — Nom/Prénom ──
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nom'),
        const SizedBox(height: 6),
        _buildTextInput(controller: _nomController, hint: 'Votre nom',
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 16),
        _buildLabel('Prénom'),
        const SizedBox(height: 6),
        _buildTextInput(controller: _prenomController, hint: 'Votre prénom',
            onChanged: (_) => setState(() {})),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildErrorBox(_error),
        ],
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: _isLoading ? 'Validation...' : 'Continuer',
          icon: Icons.chevron_right,
          disabled: _nomController.text.trim().length < 2 ||
              _prenomController.text.trim().length < 2 || _isLoading,
          isLoading: _isLoading,
          onTap: _validerNomPrenom,
        ),
      ],
    );
  }

  // ── STEP 3 — Email ──
  Widget _buildStep3() {
    final emailStatus = ref.watch(emailInscriptionStatusProvider);
    Color borderColor = Colors.grey[200]!;
    if (emailStatus == 'available') borderColor = Colors.green;
    if (emailStatus == 'taken') borderColor = Colors.red[300]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Email'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) {
              _emailDebounce?.cancel();
              if (val.contains('@') && val.contains('.') && val.trim().length >= 5) {
                ref.read(emailInscriptionStatusProvider.notifier).state = 'checking';
                _emailDebounce = Timer(const Duration(milliseconds: 700), () {
                  if (mounted) _verifierEmail();
                });
              } else {
                ref.read(emailInscriptionStatusProvider.notifier).state = 'idle';
              }
            },
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Entrer votre email',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _buildEmailSuffixIcon(emailStatus),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildEmailInscriptionIndicator(emailStatus),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: _isLoading ? 'Envoi...' : 'Envoyer le code',
          icon: Icons.send_outlined,
          disabled: emailStatus != 'available' || _isLoading,
          isLoading: _isLoading,
          onTap: _envoyerCode,
        ),
      ],
    );
  }

  // ── STEP 4 — Code 6 cases ──
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(children: [
            Icon(Icons.email_outlined, color: Colors.grey[500], size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Code envoyé à ${_emailController.text.trim()}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]))),
          ]),
        ),
        const SizedBox(height: 24),
        _buildLabel('Code de vérification'),
        const SizedBox(height: 12),

        // ── 6 cases ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            final isFilled = _codeControllers[index].text.isNotEmpty;
            Color borderColor = Colors.grey[200]!;
            Color bgColor = Colors.grey[100]!;
            Color textColor = Colors.black;

            if (_codeStatus == 'verified') {
              borderColor = Colors.green;
              bgColor = Colors.green.withOpacity(0.1);
              textColor = Colors.green;
            } else if (_codeStatus == 'invalid') {
              borderColor = Colors.red[300]!;
              bgColor = Colors.red[50]!;
              textColor = Colors.red;
            } else if (isFilled) {
              borderColor = Colors.black;
              bgColor = Colors.black;
              textColor = Colors.white;
            }

            return SizedBox(
              width: 44, height: 52,
              child: TextField(
                controller: _codeControllers[index],
                focusNode: _codeFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && index < 5) {
                    _codeFocusNodes[index + 1].requestFocus();
                  }
                  if (val.isEmpty && index > 0) {
                    _codeFocusNodes[index - 1].requestFocus();
                  }
                  setState(() { _codeStatus = 'idle'; _codeError = ''; });

                  // Auto-vérifier quand les 6 cases sont remplies
                  final code = _codeControllers.map((c) => c.text).join();
                  if (code.length == 6) {
                    _verifierCode();
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        if (_codeStatus == 'verifying')
          Row(children: [
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
            const SizedBox(width: 8),
            Text('Vérification...', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
          ]),

        if (_codeStatus == 'verified')
          Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
            const SizedBox(width: 6),
            Text('Email vérifié avec succès !',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[600])),
          ]),

        if (_codeStatus == 'invalid')
          Row(children: [
            Icon(Icons.cancel_outlined, color: Colors.red[400], size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(_codeError.isNotEmpty ? _codeError : 'Code invalide ou expiré',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[500]))),
          ]),

        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isLoading ? null : _envoyerCode,
          child: Text('Renvoyer le code', style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.grey[400],
              decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  // ── STEP 5 — Mot de passe ──
  Widget _buildStep5() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final passwordsMatch = password.isNotEmpty && confirm.isNotEmpty && password == confirm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Mot de passe'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[300]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _showPassword = !_showPassword),
                child: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18, color: Colors.grey[400]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPasswordRules(),
        const SizedBox(height: 16),
        _buildLabel('Confirmer le mot de passe'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: confirm.isEmpty ? Colors.grey[200]!
                  : passwordsMatch ? Colors.green : Colors.red[300]!,
            ),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[300]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                child: Icon(_showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18, color: Colors.grey[400]),
              ),
            ),
          ),
        ),
        if (confirm.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(
              passwordsMatch ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 13,
              color: passwordsMatch ? Colors.green : Colors.red[400],
            ),
            const SizedBox(width: 4),
            Text(
              passwordsMatch ? 'Les mots de passe correspondent'
                  : 'Les mots de passe ne correspondent pas',
              style: GoogleFonts.poppins(fontSize: 11,
                  color: passwordsMatch ? Colors.green[600] : Colors.red[500]),
            ),
          ]),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildErrorBox(_error),
        ],
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: _isLoading ? 'Validation...' : 'Continuer',
          icon: Icons.chevron_right,
          disabled: !passwordsMatch || _isLoading,
          isLoading: _isLoading,
          onTap: _validerPassword,
        ),
      ],
    );
  }

  Widget _buildPasswordRules() {
    final password = _passwordController.text;
    return Column(children: [
      _buildRule('Minimum 8 caractères', password.length >= 8),
      _buildRule('Au moins une majuscule', password.contains(RegExp(r'[A-Z]'))),
      _buildRule('Au moins une minuscule', password.contains(RegExp(r'[a-z]'))),
      _buildRule('Au moins un caractère spécial',
          password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]'))),
    ]);
  }

  Widget _buildRule(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(isValid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 13, color: isValid ? Colors.green : Colors.grey[400]),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 11,
            color: isValid ? Colors.green[600] : Colors.grey[400])),
      ]),
    );
  }

  // ── STEP 6 — Localisation ──
  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pays
        _buildLabel('Pays'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _loadingPays ? null : _showPaysBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  Expanded(child: Text(_paysSelectionne!['nomPays'],
                      style: GoogleFonts.poppins(fontSize: 13))),
                  Text(_paysSelectionne!['indicatif'],
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400])),
                ] else ...[
                  Expanded(child: Text(
                    _loadingPays ? 'Chargement...' : 'Sélectionner un pays',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                  )),
                ],
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Ville
        _buildLabel('Ville (optionnel)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: (_paysSelectionne == null || _loadingVilles) ? null : _showVilleBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _paysSelectionne == null ? Colors.grey[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(children: [
              Expanded(child: Text(
                _loadingVilles ? 'Chargement...'
                    : _villeSelectionnee != null ? _villeSelectionnee!['nomVille']
                    : _paysSelectionne == null ? 'Sélectionnez d\'abord un pays'
                    : 'Sélectionner une ville',
                style: GoogleFonts.poppins(fontSize: 13,
                    color: _villeSelectionnee != null ? Colors.black : Colors.grey[400]),
              )),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 20),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Opérateur
        _buildLabel('Opérateur téléphonique (optionnel)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: (_paysSelectionne == null || _loadingOperateurs) ? null : _showOperateurBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _paysSelectionne == null ? Colors.grey[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(children: [
              Expanded(child: Text(
                _loadingOperateurs ? 'Chargement...'
                    : _operateurSelectionne != null ? _operateurSelectionne!['nomOperateur']
                    : _paysSelectionne == null ? 'Sélectionnez d\'abord un pays'
                    : 'Sélectionner un opérateur',
                style: GoogleFonts.poppins(fontSize: 13,
                    color: _operateurSelectionne != null ? Colors.black : Colors.grey[400]),
              )),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[400], size: 20),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Numéro de téléphone
        if (_operateurSelectionne != null) ...[
          _buildLabel('Numéro de téléphone (optionnel)'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(children: [
              // Indicatif + drapeau
              GestureDetector(
                onTap: _showPaysBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(children: [
                    _buildFlag(_paysSelectionne!['codeIso']),
                    const SizedBox(width: 6),
                    Text(_paysSelectionne!['indicatif'],
                        style: GoogleFonts.poppins(fontSize: 13,
                            fontWeight: FontWeight.w500, color: Colors.grey[700])),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey[400]),
                  ]),
                ),
              ),
              // Input numéro
              Expanded(
                child: TextField(
                  controller: _telController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: _operateurSelectionne!['longueurNumero'],
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '${_operateurSelectionne!['longueurNumero']} chiffres',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
              // Compteur
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${_telController.text.length}/${_operateurSelectionne!['longueurNumero']}',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          // Badges préfixes opérateurs
          Wrap(
            spacing: 6,
            children: (_operateurs as List).map((op) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  '${op['nomOperateur']} (${(op['prefixes'] as List).join(', ')})',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Continuer', icon: Icons.chevron_right,
          disabled: false, onTap: () => setState(() => _step = 7),
        ),
      ],
    );
  }

  // ── STEP 7 — Profil (photo + bio) ──
  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo de profil
        _buildLabel('Photo de profil (optionnel)'),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!, width: 2),
                    image: _photoFile != null
                        ? DecorationImage(image: FileImage(_photoFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photoFile == null
                      ? Icon(Icons.person_outline, size: 40, color: Colors.grey[400])
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.black, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Bio
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
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: 'Continuer', icon: Icons.chevron_right,
          disabled: false, onTap: () => setState(() => _step = 8),
        ),
      ],
    );
  }

  // ── STEP 8 — Champs spécifiques rôle ──
  Widget _buildStep8() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_role == 'ENSEIGNANT') ...[
          _buildLabel('Spécialité (optionnel)'),
          const SizedBox(height: 6),
          _buildTextInput(controller: _specialiteController,
              hint: 'Ex: Mathématiques, Informatique...', onChanged: (_) => setState(() {})),
          const SizedBox(height: 16),
          _buildLabel('Titre professionnel (optionnel)'),
          const SizedBox(height: 6),
          _buildTextInput(controller: _titreController,
              hint: 'Ex: Professeur, Ingénieur...', onChanged: (_) => setState(() {})),
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
          label: _isLoading ? 'Inscription...' : "S'inscrire",
          icon: Icons.check,
          disabled: _isLoading,
          isLoading: _isLoading,
          onTap: _register,
        ),
      ],
    );
  }

  Widget _buildNiveauSelector() {
    final niveaux = ['DEBUTANT', 'INTERMEDIAIRE', 'AVANCE'];
    final labels = {'DEBUTANT': 'Débutant', 'INTERMEDIAIRE': 'Intermédiaire', 'AVANCE': 'Avancé'};
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
                border: Border.all(color: isSelected ? Colors.black : Colors.grey[200]!),
              ),
              child: Center(child: Text(labels[n]!,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600]))),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Shared widgets ──

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]));
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
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
        maxLength: maxLength,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget? _buildEmailSuffixIcon(String emailStatus) {
    if (emailStatus == 'checking') {
      return const Padding(padding: EdgeInsets.all(12),
          child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)));
    }
    if (emailStatus == 'available') {
      return const Icon(Icons.check_circle_outline, color: Colors.green, size: 18);
    }
    if (emailStatus == 'taken') {
      return Icon(Icons.cancel_outlined, color: Colors.red[400], size: 18);
    }
    return null;
  }

  Widget _buildEmailInscriptionIndicator(String emailStatus) {
    if (emailStatus == 'checking') {
      return Row(children: [
        const SizedBox(width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
        const SizedBox(width: 6),
        Text('Vérification...', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
      ]);
    }
    if (emailStatus == 'available') {
      return Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 13),
        const SizedBox(width: 4),
        Text('Email disponible', style: GoogleFonts.poppins(fontSize: 11, color: Colors.green[600])),
      ]);
    }
    if (emailStatus == 'taken') {
      return Row(children: [
        Icon(Icons.cancel_outlined, color: Colors.red[400], size: 13),
        const SizedBox(width: 4),
        Text('Cet email est déjà utilisé',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.red[500])),
      ]);
    }
    return const SizedBox.shrink();
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
        Expanded(child: Text(message,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]))),
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
                const SizedBox(width: 15, height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else
                Text(label, style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
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