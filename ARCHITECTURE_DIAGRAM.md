# 🏗️ Architecture du Module Apprenant - Vue complète

## Diagramme de flux utilisateur

```
┌─────────────────────────────────────────────────────────────────┐
│                      UTILISATEUR                                │
└──────────────────────────┬──────────────────────────────────────┘
						   │
					AUTHENTIFICATION
						   │
		┌──────────────────┴──────────────────┐
		│                                     │
   ┌────▼────┐                          ┌────▼────┐
   │ENSEIGNANT│                         │APPRENANT │
   └────┬────┘                          └────┬────┘
		│                                     │
  ┌─────▼──────────────┐           ┌─────────▼───────────┐
  │EnseignantMainScreen│           │ApprenantMainScreen  │
  │  (Bottom Nav)      │           │   (Bottom Nav)      │
  └─────┬──────────────┘           └─────────┬───────────┘
		│                                     │
   ┌────┼────────────┐              ┌────────┼──────────┐
   │                 │              │                   │
┌──▼──────────┐  ┌──▼──────────┐  ┌▼──────────────┐  ┌▼───────────────┐
│  Dashboard  │  │  Mes Cours  │  │  Dashboard    │  │  Mes Cours     │
│  (Stats)    │  │  (Manager)  │  │  (Stats pers) │  │  (Consulter)   │
└──┬──────────┘  └──┬──────────┘  └┬──────────────┘  └┬───────────────┘
   │                │              │                 │
   │                └──────┬───────┘                 │
   │                       │                         │
   │              ┌────────▼────────┐                │
   │              │ Clic sur Cours  │◄───────────────┘
   │              └────────┬────────┘
   │                       │
   │              ┌────────▼────────────────────┐
   │              │DetailCoursApprenantScreen   │
   │              │ - Titre                     │
   │              │ - Progression               │
   │              │ - Modules                   │
   │              └────────┬────────────────────┘
   │                       │
   │              ┌────────▼────────────────────┐
   │              │ Clic sur Module             │
   │              └────────┬────────────────────┘
   │                       │
   │              ┌────────▼────────────────────┐
   │              │ContenuModuleScreen          │
   │              │ - PageView (Swipe)          │
   │              │ - Texte/Vidéo/Doc/Quiz     │
   │              │ - Navigation Next/Prev      │
   │              └────────┬────────────────────┘
   │                       │
   │                  [Fin Module]
   │
   └────────► [Statistiques mises à jour]
```

---

## Architecture en couches

```
┌───────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                         │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │          Screens & Widgets                               │  │
│ │                                                          │  │
│ │ • ApprenantMainScreen                                  │  │
│ │ • DashboardApprenantScreen                            │  │
│ │ • MesCoursApprenantScreen                             │  │
│ │ • DetailCoursApprenantScreen                          │  │
│ │ • ContenuModuleScreen                                 │  │
│ │                                                          │  │
│ │ + Sub-widgets (_StatCard, _CoursCard, etc)            │  │
│ └──────────────────────────────────────────────────────────┘  │
└────────────────┬──────────────────────────────────────────────┘
				 │ Écoute l'état
				 │
┌────────────────▼──────────────────────────────────────────────┐
│              PROVIDERS LAYER (Riverpod)                        │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ FutureProviders:                                          │  │
│ │ • mesCoursApprenantProvider                            │  │
│ │ • detailCoursApprenantProvider(idCours)                │  │
│ │ • progressionCoursProvider(idCours)                    │  │
│ │ • modulesCourProvider(idCours)                         │  │
│ │ • contenuModuleProvider(params)                        │  │
│ │ • statistiquesApprenantProvider                        │  │
│ │ • notificationsApprenantProvider                       │  │
│ │                                                          │  │
│ │ StateProviders (UI locale):                             │  │
│ │ • rechercheCoursApprenantProvider                      │  │
│ │ • viewModeApprenantProvider                            │  │
│ │ • filtreEtatCoursProvider                              │  │
│ └──────────────────────────────────────────────────────────┘  │
└────────────────┬──────────────────────────────────────────────┘
				 │ Appelle le repository
				 │
┌────────────────▼──────────────────────────────────────────────┐
│              REPOSITORY LAYER (Data)                           │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ ApprenantRepository                                       │  │
│ │                                                          │  │
│ │ • getMesCours()                                         │  │
│ │ • getDetailCours(idCours)                              │  │
│ │ • getProgressionCours(idCours)                         │  │
│ │ • getModulesCours(idCours)                             │  │
│ │ • getContenuModule(idCours, idModule)                  │  │
│ │ • marquerContenuComplete(...)                          │  │
│ │ • getStatistiques()                                     │  │
│ │ • getNotifications()                                    │  │
│ │ • soumettreQuiz(...)                                   │  │
│ └──────────────────────────────────────────────────────────┘  │
└────────────────┬──────────────────────────────────────────────┘
				 │ Utilise Dio
				 │
┌────────────────▼──────────────────────────────────────────────┐
│                   HTTP CLIENT (Dio)                            │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ DioClient (Centralisé dans core/network)               │  │
│ │                                                          │  │
│ │ Headers:                                                 │  │
│ │ • Authorization: Bearer {token}                        │  │
│ │ • Content-Type: application/json                       │  │
│ │                                                          │  │
│ │ Interceptors:                                            │  │
│ │ • ErrorHandler                                          │  │
│ │ • Retry Logic                                           │  │
│ └──────────────────────────────────────────────────────────┘  │
└────────────────┬──────────────────────────────────────────────┘
				 │ HTTP Requests
				 │
┌────────────────▼──────────────────────────────────────────────┐
│                    BACKEND (Express.js)                        │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ API Endpoints                                            │  │
│ │                                                          │  │
│ │ GET  /api/cours/mes-inscriptions                        │  │
│ │ GET  /api/cours/:id                                     │  │
│ │ GET  /api/cours/:id/progression                        │  │
│ │ GET  /api/cours/:id/modules                            │  │
│ │ GET  /api/cours/:id/modules/:id/contenus               │  │
│ │ POST /api/cours/:id/modules/:id/contenus/:id/complete │  │
│ │ GET  /api/dashboard/apprenant/statistiques             │  │
│ │ GET  /api/notifications                                 │  │
│ │ POST /api/cours/:id/modules/:id/quiz/:id/reponses     │  │
│ └──────────────────────────────────────────────────────────┘  │
└────────────────┬──────────────────────────────────────────────┘
				 │
┌────────────────▼──────────────────────────────────────────────┐
│              DATABASE (Prisma)                                 │
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ Models:                                                   │  │
│ │ • User (avec roleUser: APPRENANT/ENSEIGNANT)          │  │
│ │ • Course                                                 │  │
│ │ • Inscription (lien User ↔ Course)                     │  │
│ │ • Module                                                 │  │
│ │ • Content                                                │  │
│ │ • CourseProgress                                         │  │
│ │ • Notification                                           │  │
│ │ • Quiz                                                   │  │
│ └──────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

---

## Flux de données - Exemple détaillé

### Cas : Charger les cours de l'apprenant

```
1. USER ACTION
   └─ ApprenantMainScreen.initState()
	  └─ ref.watch(mesCoursApprenantProvider)

2. PROVIDER EXECUTED
   └─ mesCoursApprenantProvider (FutureProvider)
	  └─ repository.getMesCours()

3. REPOSITORY MAKES API CALL
   └─ ApprenantRepository.getMesCours()
	  ├─ dio.get('/api/cours/mes-inscriptions')
	  ├─ Headers: {Authorization: Bearer {token}}
	  └─ Retourne: List<Map<String, dynamic>>

4. HTTP REQUEST
   └─ POST vers backend
	  ├─ Headers avec JWT token
	  ├─ Middleware auth valide le token
	  └─ Controller récupère les données

5. BACKEND PROCESSING
   └─ Controller: /api/cours/mes-inscriptions
	  ├─ Récupère userId du token
	  ├─ Query: inscriptions WHERE userId = current
	  ├─ Joins: courses + progression
	  └─ Retourne: JSON

6. DATA RETURNS
   └─ HTTP Response (200 OK)
	  ├─ Status: AsyncData
	  ├─ Data: List<Map<String, dynamic>>
	  └─ Stocker dans Riverpod cache

7. UI REBUILDS
   └─ MesCoursApprenantScreen rebuilds
	  ├─ Shimmer disparaît
	  ├─ GridView/ListView affiche les cours
	  ├─ Barre de progression pour chaque
	  └─ Prêt pour interactions

8. USER INTERACTION
   └─ Clic sur un cours
	  ├─ context.go('/apprenant/cours/{id}')
	  ├─ Charge DetailCoursApprenantScreen
	  └─ Nouveau FutureProvider:
		 detailCoursApprenantProvider(id)
```

---

## State Management Flow

```
┌──────────────────┐
│  User Action     │
│  (Tap, Scroll)   │
└────────┬─────────┘
		 │
		 ▼
┌──────────────────────────────┐
│  StateProvider/FutureProvider│ ◄─── Riverpod (en mémoire)
│  State: AsyncValue<T>        │
├──────────────────────────────┤
│ • AsyncData (Données chargées)   │
│ • AsyncLoading (Chargement)      │
│ • AsyncError (Erreur)            │
└────────┬────────────────────┘
		 │
		 ▼
┌──────────────────────────────┐
│  Widget.when()               │
│  (Pattern matching)          │
├──────────────────────────────┤
│ .data(data) → Afficher       │
│ .loading() → Shimmer         │
│ .error(err) → Message erreur │
└────────┬────────────────────┘
		 │
		 ▼
┌──────────────────────────────┐
│  UI Update                   │
│  (Flutter rebuild)           │
└──────────────────────────────┘
```

---

## Hiérarchie des fichiers avec dépendances

```
apprenant/
│
├── providers/
│   └── apprenant_provider.dart
│       ├─ Dépend de: Dio, AuthProvider, Repository
│       ├─ Utilisé par: Tous les screens
│       └─ Gère: Tous les FutureProviders et StateProviders
│
├── data/
│   └── apprenant_repository.dart
│       ├─ Dépend de: Dio
│       ├─ Utilisé par: Providers
│       └─ Gère: Tous les appels API
│
└── presentation/
	└── screens/
		├── apprenant_main_screen.dart
		│   ├─ Dépend de: Providers, Auth
		│   └─ Enfants: Dashboard + Mes Cours
		│
		├── dashboard_apprenant_screen.dart
		│   ├─ Dépend de: statistiquesApprenantProvider
		│   └─ Affiche: Stats cards + Cours populaires
		│
		├── mes_cours_apprenant_screen.dart
		│   ├─ Dépend de: mesCoursApprenantProvider
		│   └─ Fonctionnalités: Recherche, Filtres, Grid/List
		│
		├── detail_cours_apprenant_screen.dart
		│   ├─ Dépend de: detailCoursApprenantProvider, progressionCoursProvider
		│   ├─ Params: idCours
		│   └─ Affiche: Infos cours + Modules
		│
		└── contenu_module_screen.dart
			├─ Dépend de: contenuModuleProvider
			├─ Params: idCours, idModule
			└─ Fonctionnalité: PageView reader
```

---

## Navigation Routes

```
GoRouter Configuration:
│
├─ / (Splash)
│  ├─ /login (Authentication)
│  ├─ /register
│  ├─ /oauth
│  └─ /complete-profile
│
└─ /home (Redirect selon rôle)
   ├─ ENSEIGNANT → EnseignantMainScreen
   └─ APPRENANT → ApprenantMainScreen
	  │
	  └─ /apprenant
		 ├─ / (Main avec Bottom Nav)
		 │
		 ├─ /cours/:idCours
		 │  ├─ DetailCoursApprenantScreen
		 │  │
		 │  └─ /module/:idModule
		 │     └─ ContenuModuleScreen
		 │        ├─ Type: video
		 │        ├─ Type: document
		 │        ├─ Type: quiz
		 │        └─ Type: text
		 │
		 ├─ /profil
		 │  └─ ProfilApprenantScreen (À implémenter)
		 │
		 └─ /notifications
			└─ NotificationsScreen (À implémenter)
```

---

## Modèle de données attendu

```
Apprenant (User avec roleUser = 'APPRENANT')
│
├─ Inscriptions
│  └─ Courses (1:N)
│     ├─ id
│     ├─ titre
│     ├─ description
│     ├─ imageCouverture
│     ├─ enseignant
│     │  ├─ id
│     │  ├─ name
│     │  └─ email
│     │
│     ├─ Modules (1:N)
│     │  ├─ id
│     │  ├─ titre
│     │  ├─ description
│     │  ├─ order
│     │  │
│     │  └─ Contents (1:N)
│     │     ├─ id
│     │     ├─ titre
│     │     ├─ type (video|document|quiz|text)
│     │     ├─ contenu
│     │     ├─ urlMedia
│     │     ├─ order
│     │     │
│     │     └─ Completions (User:N)
│     │        └─ completedAt
│     │
│     └─ CourseProgress (1:1 User)
│        ├─ pourcentageComplete
│        ├─ totalContenu
│        ├─ contenuComplete
│        └─ lastAccessedAt
│
└─ Notifications
   ├─ type (course_update|new_content|reminder)
   ├─ message
   ├─ courseId
   └─ read
```

---

## Points d'intégration backend

Le backend doit fournir:

1. **Authentification** : JWT tokens valides
2. **Autorisation** : Vérifier l'accès aux cours inscrits
3. **Endpoints** : Tous les 9 endpoints listés
4. **Format de données** : JSON avec structure correcte
5. **Pagination** : (Optionnel) Supporter skip/limit
6. **Timestamps** : createdAt, updatedAt pour sync offline

---

**Conclusion**: Cette architecture garantit une maintenance facile,
une évolutivité optimale et une expérience utilisateur fluide.
