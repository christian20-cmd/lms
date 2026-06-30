import 'package:dio/dio.dart';

class ApprenantRepository {
  final Dio dio;
  final String? token;

  ApprenantRepository({required this.dio, required this.token});

  Map<String, dynamic> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Exception _erreur(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return Exception(data['message'].toString());
    }
    return Exception(fallback);
  }

  // ── Dashboard / statistiques ──
  Future<Map<String, dynamic>> getStatistiques() async {
    try {
      final response = await dio.get(
        '/dashboard/apprenant/statistiques',
        options: Options(headers: _headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération des statistiques');
    }
  }

  // ── Mes cours (liste des inscriptions) ──
  Future<List<Map<String, dynamic>>> getMesCours() async {
    try {
      final response = await dio.get(
        '/cours/mes-inscriptions',
        options: Options(headers: _headers),
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération des cours');
    }
  }

  // ── Catalogue — tous les cours publiés, paginé ──
  Future<Map<String, dynamic>> getCoursPublies({
    String? search,
    String? niveau,
    String? idCategorie,
    bool? gratuit,
    int page = 1,
    int limite = 10,
  }) async {
    try {
      final response = await dio.get(
        '/cours',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (niveau != null) 'niveau': niveau,
          if (idCategorie != null) 'idCategorie': idCategorie,
          if (gratuit != null) 'gratuit': gratuit.toString(),
          'page': page.toString(),
          'limite': limite.toString(),
        },
        options: Options(headers: _headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération du catalogue');
    }
  }

  // ── Catégories (pour les filtres du catalogue) ──
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await dio.get(
        '/cours/categories',
        options: Options(headers: _headers),
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération des catégories');
    }
  }

  // ── Détail d'un cours ──
  Future<Map<String, dynamic>> getDetailCours(String idCours) async {
    try {
      final response = await dio.get(
        '/cours/$idCours',
        options: Options(headers: _headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération du cours');
    }
  }

  // ── Vérifier si déjà inscrit ──
  Future<bool> verifierInscription(String idCours) async {
    try {
      final response = await dio.get(
        '/cours/$idCours/inscription',
        options: Options(headers: _headers),
      );
      return (response.data as Map<String, dynamic>)['estInscrit'] == true;
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la vérification de l\'inscription');
    }
  }

  // ── S'inscrire à un cours ──
  Future<void> sInscrire(String idCours) async {
    try {
      await dio.post(
        '/cours/$idCours/inscrire',
        options: Options(headers: _headers),
      );
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de l\'inscription');
    }
  }

  // ── Se désinscrire ──
  Future<void> seDesinscrire(String idCours) async {
    try {
      await dio.delete(
        '/cours/$idCours/desinscrire',
        options: Options(headers: _headers),
      );
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la désinscription');
    }
  }

  // ── Progression d'un cours ──
  Future<Map<String, dynamic>> getProgressionCours(String idCours) async {
    try {
      final response = await dio.get(
        '/cours/$idCours/progression',
        options: Options(headers: _headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération de la progression');
    }
  }

  // ── Modules d'un cours ──
  Future<List<Map<String, dynamic>>> getModulesCours(String idCours) async {
    try {
      final response = await dio.get(
        '/cours/$idCours/modules',
        options: Options(headers: _headers),
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération des modules');
    }
  }

  // ── Contenus d'un module ──
  Future<List<Map<String, dynamic>>> getContenuModule(String idCours, String idModule) async {
    try {
      final response = await dio.get(
        '/cours/$idCours/modules/$idModule/contenus',
        options: Options(headers: _headers),
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération du contenu');
    }
  }

  // ── Marquer un module comme terminé ──
  Future<Map<String, dynamic>> marquerModuleTermine(String idCours, String idModule) async {
    try {
      final response = await dio.post(
        '/cours/$idCours/modules/$idModule/terminer',
        options: Options(headers: _headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la mise à jour de la progression');
    }
  }

  // ── Notifications ──
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await dio.get(
        '/notifications',
        options: Options(headers: _headers),
      );
      final data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération des notifications');
    }
  }

  // ── Profil — lecture ──
  Future<Map<String, dynamic>> getMonProfil() async {
    try {
      final response = await dio.get(
        '/profil',
        options: Options(headers: _headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la récupération du profil');
    }
  }

  // ── Profil — infos générales (nom, prénom, bio, téléphone) ──
  Future<void> modifierProfil({
    String? nomUser,
    String? prenomUser,
    String? bioUser,
    String? numeroTelUser,
    String? idVille,
    String? idOperateur,
  }) async {
    try {
      await dio.put(
        '/profil',
        data: {
          if (nomUser != null) 'nomUser': nomUser,
          if (prenomUser != null) 'prenomUser': prenomUser,
          if (bioUser != null) 'bioUser': bioUser,
          if (numeroTelUser != null) 'numeroTelUser': numeroTelUser,
          if (idVille != null) 'idVille': idVille,
          if (idOperateur != null) 'idOperateur': idOperateur,
        },
        options: Options(headers: _headers),
      );
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la mise à jour du profil');
    }
  }

  // ── Profil — infos spécifiques apprenant (niveau, établissement) ──
  Future<void> modifierProfilApprenant({
    String? niveauApprenant,
    String? idEtablissement,
  }) async {
    try {
      await dio.put(
        '/profil/apprenant',
        data: {
          if (niveauApprenant != null) 'niveauApprenant': niveauApprenant,
          if (idEtablissement != null) 'idEtablissement': idEtablissement,
        },
        options: Options(headers: _headers),
      );
    } on DioException catch (e) {
      throw _erreur(e, 'Erreur lors de la mise à jour du profil apprenant');
    }
  }
}