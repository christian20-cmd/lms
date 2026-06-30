# 🔄 Comparaison Architecture : Enseignant vs Apprenant

## Vue d'ensemble

L'architecture du module **Apprenant** suit exactement la même structure que le module **Enseignant** pour maintenir la cohérence du projet.

---

## 📂 Structure parallèle

```
features/
├── enseignant/                          features/
│   ├── providers/                       ├── apprenant/
│   │   ├── cours_provider.dart          │   ├── providers/
│   │   └── enseignant_provider.dart     │   │   └── apprenant_provider.dart ✨
│   ├── data/                            │   ├── data/
│   │   └── [sources API]                │   │   └── apprenant_repository.dart ✨
│   ├── presentation/                    │   └── presentation/
│   │   ├── screens/                     │       └── screens/
│   │   │   ├── enseignant_main_screen   │           ├── apprenant_main_screen ✨
│   │   │   ├── dashboard_screen         │           ├── dashboard_apprenant_screen ✨
│   │   │   ├── mes_cours_screen         │           ├── mes_cours_apprenant_screen ✨
│   │   │   ├── cours_detail_screen      │           ├── detail_cours_apprenant_screen ✨
│   │   │   └── ...                      │           └── contenu_module_screen ✨
│   │   ├── widgets/                     │
│   │   └── services/                    │
│   └── services/                        │
```

---

## 🎯 Écrans : Comparaison

### Main Screen

| Aspect | Enseignant | Apprenant |
|--------|-----------|-----------|
| **Chemin** | `/home` → détecte rôle | `/apprenant` |
| **Navigation** | BottomNav + Drawer | BottomNav + Drawer |
| **Onglets** | Dashboard, Mes cours | Dashboard, Mes cours |
| **État** | Manage courses | View courses |

### Dashboard

| Aspect | Enseignant | Apprenant |
|--------|-----------|-----------|
| **Stats 1** | Cours créés | Cours inscrits |
| **Stats 2** | Étudiants totaux | Cours terminés |
| **Stats 3** | Inscriptions (mois) | Progression moyenne |
| **Stats 4** | Revenus | Temps d'apprentissage |
| **Grille** | Mes cours → Éditer | Mes cours → Consulter |

### Mes Cours

| Aspect | Enseignant | Apprenant |
|--------|-----------|-----------|
| **Affichage** | Grid/List | Grid/List |
| **Actions** | Créer, Éditer, Supprimer | Consulter, Progresser |
| **Filtres** | Catégories, États | État (en cours, terminés) |
| **Infos** | Nbre étudiants, revenus | Progression personnelle |

### Détail Cours

| Aspect | Enseignant | Apprenant |
|--------|-----------|-----------|
| **Fonctionnalité** | Manager le cours | Consulter & apprendre |
| **Modules** | Créer/Éditer/Supprimer | Consulter & naviguer |
| **Contenus** | Ajouter/Modifier | Consulter & marquer complet |
| **Actions** | Gestion avancée | Apprentissage simple |

### Contenu Module

| Aspect | Enseignant | Apprenant |
|--------|-----------|-----------|
| **Status** | À créer | ✅ Implémenté |
| **Affichage** | Editeur | Lecteur (PageView) |
| **Types** | Créer/Modifier | Lire (texte, vidéo, doc, quiz) |

---

## 🔌 Providers : Parallèle

### Enseignant

```dart
final mesCoursEnseignantProvider = FutureProvider((ref) async {
  return repository.getMyCoursesAsTeacher(); // Mes cours créés
});

final detailCoursProvider = FutureProvider.family((ref, idCours) async {
  return repository.getDetailForEditing(idCours); // Édition
});
```

### Apprenant (Nouveau)

```dart
final mesCoursApprenantProvider = FutureProvider((ref) async {
  return repository.getMesCours(); // Mes inscriptions
});

final detailCoursApprenantProvider = FutureProvider.family((ref, idCours) async {
  return repository.getDetailCours(idCours); // Consultation
});
```

---

## 📡 API Endpoints : Comparaison

### Pour Enseignant

```
GET  /api/cours                     # Mes cours (créés)
POST /api/cours                     # Créer un cours
PUT  /api/cours/:id                 # Modifier un cours
DEL  /api/cours/:id                 # Supprimer un cours
```

### Pour Apprenant (Nouveau)

```
GET  /api/cours/mes-inscriptions    # Mes cours (inscrits)
GET  /api/cours/:id                 # Détail (view-only)
GET  /api/cours/:id/progression     # Ma progression
```

### Shared Endpoints

```
GET  /api/cours/:id/modules                    # Modules
GET  /api/cours/:id/modules/:id/contenus       # Contenus
POST /api/cours/:id/modules/:id/contenus/:id/complete  # Mark done
```

---

## 🎨 UI/UX : Différences

### Enseignant
- Boutons d'action : Créer, Éditer, Supprimer
- Modals/Drawers pour formulaires complexes
- Dashboard riche avec analytics
- Gestion de modules avancée

### Apprenant
- Boutons simples : Consulter, Progresser
- Navigation fluide dans le contenu
- Dashboard basé sur la progression personnelle
- Lecteur de contenu interactif (PageView)

---

## 🔐 Authentification & Autorisation

### Détection du rôle

```dart
// Dans app_router.dart
GoRoute(
  path: '/home',
  builder: (context, state) {
	final authState = ref.read(authProvider);

	if (authState.user?.roleUser == 'ENSEIGNANT') {
	  return const EnseignantMainScreen();  // Panneau enseignant
	}
	return const ApprenantMainScreen();      // Panneau apprenant
  },
),
```

### Headers API

**Enseignant & Apprenant** utilisent les mêmes headers :
```dart
Map<String, dynamic> get _headers => {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
};
```

---

## 📊 Comparison Matrix

| Critère | Enseignant | Apprenant |
|---------|-----------|-----------|
| **Rôle** | Créer & gérer cours | S'inscrire & apprendre |
| **Écrans** | 5+ | 5 |
| **Fichiers** | 20+ | 5 principaux |
| **Routes** | `/enseignant/*` | `/apprenant/*` |
| **Providers** | 5+ | 7 |
| **Complexité UI** | Haute | Moyenne |
| **Complexité API** | Haute (CRUD) | Moyenne (Read + Progress) |
| **State** | Gestion complexe | Simple (read-only) |

---

## 🔄 Flux de données

### Enseignant
```
Auth → EnseignantMainScreen
  → Dashboard (Stats création)
	→ Mes Cours (List)
	  → Detail (Editor)
		→ Modules (CRUD)
		  → Contenus (CRUD)
```

### Apprenant
```
Auth → ApprenantMainScreen
  → Dashboard (Stats apprentissage)
	→ Mes Cours (List with progress)
	  → Detail (View)
		→ Modules (Consult)
		  → Contenus (PageView reader)
```

---

## 💾 Data Models

### Course (Partagé)

```dart
class CourseModel {
  final String id;
  final String titre;
  final String description;
  final String imageCouverture;
  final User enseignant;
  final List<Module> modules;
}
```

### Enseignant needs:
- `createdAt`, `updatedAt`, `status`, `pricing`

### Apprenant needs:
- `progression`, `inscriptionDate`, `completionDate`

---

## 🎯 Points clés de conception

1. **Même Design System** : Tokens, couleurs, typographie identiques
2. **Même Pattern d'Architecture** : Clean arch avec Riverpod
3. **Même Framework Navigation** : GoRouter pour les deux
4. **API RESTful Partagée** : Endpoints adaptés à chaque rôle
5. **Code réutilisable** : UI components peuvent être partagés

---

## 📈 Évolution future

### Phase 1 (Actuelle)
✅ Apprenant read-only
✅ Dashboard statistiques
✅ Lecteur de contenu simple

### Phase 2 (Court terme)
⏳ Interactions (quiz, forums)
⏳ Notes et certificats
⏳ Recommendations

### Phase 3 (Moyen terme)
⏳ Analytics apprenant avancées
⏳ Gamification
⏳ Parcours personnalisés

---

## 📚 Documentation

- **Enseignant** : Voir `lms_app/lib/features/enseignant/`
- **Apprenant** : Voir `lms_app/lib/features/apprenant/` (nouveau)
- **Implementation** : Voir `IMPLEMENTATION_APPRENANT.md`
- **Quick Start** : Voir `QUICK_START_APPRENANT.md`

---

**Conclusion** : La structure apprenant suit fidèlement le pattern enseignant,
ce qui garantit une maintenabilité et une évolutivité optimales pour l'application.
