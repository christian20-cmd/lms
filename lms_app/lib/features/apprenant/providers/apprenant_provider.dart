import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:LMS/core/network/dio_client.dart';
import 'package:LMS/features/auth/presentation/providers/auth_provider.dart';
import '../data/apprenant_repository.dart';

// ── Providers de base ──
final apprenantRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final token = ref.watch(authProvider).token;
  return ApprenantRepository(dio: dio, token: token);
});

// ── Statistiques dashboard ──
final statistiquesApprenantProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getStatistiques();
});

// ── Mes cours (inscriptions) ──
final mesCoursApprenantProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getMesCours();
});

// ── Catalogue — filtres locaux ──
final rechercheCatalogueProvider = StateProvider<String>((ref) => '');
final filtreNiveauCatalogueProvider = StateProvider<String?>((ref) => null);
final filtreCategorieCatalogueProvider = StateProvider<String?>((ref) => null);
final filtreGratuitCatalogueProvider = StateProvider<bool?>((ref) => null);
final pageCatalogueProvider = StateProvider<int>((ref) => 1);

// ── Catalogue — résultat paginé ──
final catalogueCoursProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getCoursPublies(
    search: ref.watch(rechercheCatalogueProvider),
    niveau: ref.watch(filtreNiveauCatalogueProvider),
    idCategorie: ref.watch(filtreCategorieCatalogueProvider),
    gratuit: ref.watch(filtreGratuitCatalogueProvider),
    page: ref.watch(pageCatalogueProvider),
  );
});

// ── Catégories disponibles ──
final categoriesApprenantProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getCategories();
});

// ── Détail d'un cours ──
final detailCoursApprenantProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, idCours) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getDetailCours(idCours);
});

// ── Vérifier inscription à un cours ──
final estInscritProvider =
    FutureProvider.family<bool, String>((ref, idCours) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.verifierInscription(idCours);
});

// ── Progression d'un cours ──
final progressionCoursProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, idCours) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getProgressionCours(idCours);
});

// ── Modules d'un cours ──
final modulesCourProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, idCours) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getModulesCours(idCours);
});

// ── Contenus d'un module — clé composite idCours|idModule ──
final contenuModuleProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, params) async {
  final parts = params.split('|');
  final idCours = parts[0];
  final idModule = parts[1];
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getContenuModule(idCours, idModule);
});

// ── Notifications ──
final notificationsApprenantProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getNotifications();
});

// ── Profil ──
final profilApprenantProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(apprenantRepositoryProvider);
  return repository.getMonProfil();
});

// ── Actions (StateNotifier pour mutations) ──
class ApprenantActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ApprenantRepository _repository;
  final Ref _ref;

  ApprenantActionsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> sInscrire(String idCours) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sInscrire(idCours);
      _ref.invalidate(mesCoursApprenantProvider);
      _ref.invalidate(estInscritProvider(idCours));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> seDesinscrire(String idCours) async {
    state = const AsyncValue.loading();
    try {
      await _repository.seDesinscrire(idCours);
      _ref.invalidate(mesCoursApprenantProvider);
      _ref.invalidate(estInscritProvider(idCours));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> marquerModuleTermine(String idCours, String idModule) async {
    try {
      final result = await _repository.marquerModuleTermine(idCours, idModule);
      _ref.invalidate(progressionCoursProvider(idCours));
      _ref.invalidate(mesCoursApprenantProvider);
      _ref.invalidate(statistiquesApprenantProvider);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> modifierProfil({
    String? nomUser,
    String? prenomUser,
    String? bioUser,
    String? numeroTelUser,
    String? idVille,
    String? idOperateur,
  }) async {
    try {
      await _repository.modifierProfil(
        nomUser: nomUser,
        prenomUser: prenomUser,
        bioUser: bioUser,
        numeroTelUser: numeroTelUser,
        idVille: idVille,
        idOperateur: idOperateur,
      );
      _ref.invalidate(profilApprenantProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> modifierProfilApprenant({
    String? niveauApprenant,
    String? idEtablissement,
  }) async {
    try {
      await _repository.modifierProfilApprenant(
        niveauApprenant: niveauApprenant,
        idEtablissement: idEtablissement,
      );
      _ref.invalidate(profilApprenantProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final apprenantActionsProvider =
    StateNotifierProvider<ApprenantActionsNotifier, AsyncValue<void>>((ref) {
  return ApprenantActionsNotifier(ref.watch(apprenantRepositoryProvider), ref);
});

// ── Providers locaux pour l'UI ──
final rechercheCoursApprenantProvider = StateProvider<String>((ref) => '');
final viewModeApprenantProvider = StateProvider<String>((ref) => 'grid');
final filtreEtatCoursProvider = StateProvider<String>((ref) => 'tous');