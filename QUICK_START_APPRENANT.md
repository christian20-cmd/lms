# 🚀 Guide de démarrage rapide - Module Apprenant

## 🎯 Objectif
Vous pouvez maintenant implémenter le côté **apprenant** de votre application LMS sans refaire les structures de base. Tout suit l'architecture de l'**enseignant**.

---

## 📋 Ce qui a été fait

### ✅ Structure complète
- 5 écrans principaux implémentés
- Providers Riverpod configurés
- API Repository complète
- Routes GoRouter intégrées
- Design system unifié

### 📱 Écrans créés

| Écran | Chemin | Description |
|-------|--------|-------------|
| Main | `/apprenant` | Navigation BottomNav + Drawer |
| Dashboard | Tab 1 | Statistiques & aperçu cours |
| Mes Cours | Tab 2 | Liste, recherche, filtrage |
| Détail Cours | `/apprenant/cours/:id` | Infos + modules |
| Contenu | `/apprenant/cours/:id/module/:id` | Lecteur (texte, vidéo, doc, quiz) |

---

## 🔧 Utilisation

### 1️⃣ Tester en local

```bash
cd lms_app
flutter run
```

Après login comme apprenant → `/apprenant` s'affiche automatiquement

### 2️⃣ Vérifier le flux

1. Login → Détection du rôle
2. Dashboard avec stats
3. Cliquer sur un cours → DetailCoursApprenantScreen
4. Cliquer sur un module → ContenuModuleScreen
5. Swipe/Navigation du contenu

### 3️⃣ Points clés du code

**Détection du rôle** (`app_router.dart`)
```dart
final authState = ref.read(authProvider);
if (authState.user?.roleUser == 'ENSEIGNANT') {
  return const EnseignantMainScreen();
}
return const ApprenantMainScreen(); // Apprenant
```

**Providers** (`apprenant_provider.dart`)
```dart
// Récupérer les cours
final coursAsync = ref.watch(mesCoursApprenantProvider);

// Détail d'un cours
final detailAsync = ref.watch(
  detailCoursApprenantProvider(idCours)
);
```

**Repository** (`apprenant_repository.dart`)
```dart
// Tous les appels API avec authentification JWT
Future<List<Map<String, dynamic>>> getMesCours() async {
  final response = await dio.get(
	'/api/cours/mes-inscriptions',
	options: Options(headers: _headers), // Token inclus
  );
  // ...
}
```

---

## 🎨 Architecture & Patterns

### Clean Architecture
```
features/apprenant/
├── presentation/     # UI (Screens, Widgets)
├── providers/        # State Management (Riverpod)
└── data/             # API (Repository)
```

### State Management
- **Riverpod** pour l'état global
- **StateProvider** pour l'UI locale (recherche, filtres)
- **FutureProvider** pour les appels async

### Navigation
- **GoRouter** avec routes imbriquées
- Deep linking support
- Type-safe parameters

---

## 📡 Backend Required

Assurez-vous que votre backend retourne le format attendu :

### Endpoint: `/api/cours/mes-inscriptions`
```json
[
  {
	"id": "cours-1",
	"titre": "Flutter Avancé",
	"description": "Apprenez Flutter...",
	"imageCouverture": "https://...",
	"progression": 0.6,
	"enseignant": {
	  "id": "ens-1",
	  "name": "Jean Dupont"
	}
  }
]
```

### Endpoint: `/api/cours/:id`
```json
{
  "id": "cours-1",
  "titre": "Flutter Avancé",
  "description": "...",
  "imageCouverture": "https://...",
  "enseignant": {...},
  "nombreModules": 5
}
```

### Endpoint: `/api/cours/:id/progression`
```json
{
  "pourcentageComplete": 0.6,
  "totalContenu": 50,
  "contenuComplete": 30
}
```

### Endpoint: `/api/cours/:id/modules`
```json
[
  {
	"id": "mod-1",
	"titre": "Widgets",
	"description": "Découvrez les widgets Flutter",
	"nombreContenus": 8
  }
]
```

### Endpoint: `/api/cours/:id/modules/:id/contenus`
```json
{
  "contenus": [
	{
	  "id": "cont-1",
	  "titre": "Introduction aux StatelessWidget",
	  "type": "video",
	  "urlMedia": "https://...",
	  "contenu": "..."
	}
  ]
}
```

---

## 🧪 Testing

### Tester la recherche
```dart
ref.read(rechercheCoursApprenantProvider.notifier).state = 'Flutter';
```

### Tester le filtrage
```dart
ref.read(filtreEtatCoursProvider.notifier).state = 'en_cours';
```

### Tester la vue
```dart
ref.read(viewModeApprenantProvider.notifier).state = 'list'; // ou 'grid'
```

---

## ⚠️ Points d'attention

1. **JWT Token** : Vérifier que `authProvider` fournit un token valide
2. **CORS** : Backend doit avoir CORS activé (déjà fait chez vous)
3. **Endpoints** : S'assurer que les routes du backend existent
4. **Images** : Gérer les URL cassées avec placeholder
5. **Performance** : Shimmer loaders masquent les appels lents

---

## 🐛 Dépannage courant

### Erreur: "Aucun cours trouvé"
- ✅ Vérifier que le backend retourne des données
- ✅ Vérifier le token JWT dans les headers
- ✅ Vérifier les CORS

### Les images ne s'affichent pas
- ✅ Les URLs doivent être valides
- ✅ `CachedNetworkImage` gère les erreurs automatiquement

### Refresh ne fonctionne pas
- ✅ Utiliser `ref.refresh(mesCoursApprenantProvider)`
- ✅ Ou implémenter un PullToRefresh widget

---

## 📚 Ressources

- Flutter Riverpod : https://riverpod.dev
- GoRouter : https://pub.dev/packages/go_router
- Clean Architecture : https://resocoder.com/clean-architecture-tdd

---

## ✨ Améliorations futures

**Court terme**
- [ ] Profil apprenant (lire/éditer)
- [ ] Notifications (push + liste)
- [ ] Quiz complet
- [ ] Lecteur vidéo Chewie

**Moyen terme**
- [ ] Notes et certificats
- [ ] Forums de discussion
- [ ] Mode offline
- [ ] Analytics

---

**Ready to go! 🚀**

Toute la structure est en place. Il suffit de vérifier que votre backend 
répond aux endpoints spécifiés et vous êtes prêt à tester le flux complet.

Si vous avez des questions sur une partie spécifique, consultez les commentaires 
dans les fichiers générés.
