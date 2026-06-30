# 📖 Exemples d'Utilisation - Détails Cours Unifié

## Navigation vers le CoursDetailScreen

### Exemple 1: Depuis une Card de Cours

```dart
GestureDetector(
  onTap: () => _navigateToCoursDetail(),
  child: Container(
	padding: const EdgeInsets.all(16),
	child: Column(
	  crossAxisAlignment: CrossAxisAlignment.start,
	  children: [
		Text(titre),
		Text(description),
		ElevatedButton(
		  onPressed: () => _navigateToCoursDetail(),
		  child: const Text('Voir le cours'),
		),
	  ],
	),
  ),
)

void _navigateToCoursDetail() {
  Navigator.push(
	context,  // BuildContext nécessaire
	MaterialPageRoute(
	  builder: (context) => CoursDetailScreen(
		idCours: idCours,
		titreCours: titre,
		descriptionCours: description,
	  ),
	),
  );
}
```

---

## Interaction avec les Modules

### Expansion/Collapse d'un Module

**Action Utilisateur:** Tap sur l'en-tête du module

```dart
// Dans _CoursDetailScreenState:
_expandedModules[idModule] = !(_expandedModules[idModule] ?? false);
```

**Résultat:**
```
Avant: ▶ Module 1
Après: ▼ Module 1
	   ├─ 📹 Contenu 1
	   ├─ 📝 Contenu 2
	   └─ 📄 Contenu 3
```

---

## Actions sur les Contenus

### 1. Lancer une Vidéo

**Code:**
```dart
void _launchVideo(BuildContext context, String url) {
  print('📹 Lancement vidéo: $url');
  // TODO: Intégrer url_launcher ou video_player
  ScaffoldMessenger.of(context).showSnackBar(
	SnackBar(content: Text('Vidéo: $url')),
  );
}
```

**Flux:**
```
1. Utilisateur clique sur le bouton [Lancer]
2. _launchVideo() est appelé avec l'URL
3. Vidéo s'ouvre (TODO: implémentation)
4. Utilisateur revient à la liste des contenus
```

---

### 2. Voir le Texte

**Code:**
```dart
void _showTextContent(
	BuildContext context, 
	String titre, 
	String contenu) {
  showDialog(
	context: context,
	builder: (context) => AlertDialog(
	  title: Text(titre),
	  content: SingleChildScrollView(
		child: Text(contenu,
			style: GoogleFonts.dmSans(
				fontSize: 13, 
				color: _AppColors.textPrimary)),
		),
	  ),
	  actions: [
		TextButton(
		  onPressed: () => Navigator.pop(context),
		  child: const Text('Fermer'),
		),
	  ],
	),
  );
}
```

**UI Résultante:**
```
┌──────────────────────────────┐
│ Notes de cours               │
├──────────────────────────────┤
│ Lorem ipsum dolor sit amet   │
│ consectetur adipiscing elit. │
│ Sed do eiusmod tempor...     │
│ (scrollable)                 │
├──────────────────────────────┤
│ [Fermer]                     │
└──────────────────────────────┘
```

---

### 3. Éditer un Contenu

**Code (TODO):**
```dart
void _editContenu(
	BuildContext context, 
	String idContenu,
	Map<String, dynamic> contenu) {
  print('✏️ Éditer contenu: $idContenu');

  // TODO: Implémenter l'écran/formulaire d'édition
  showModalBottomSheet(
	context: context,
	isScrollControlled: true,
	builder: (_) => _ContenuEditSheet(
	  idCours: widget.idCours,
	  idModule: widget.idModule,
	  idContenu: idContenu,
	  contenu: contenu,
	),
  );
}
```

---

### 4. Supprimer un Contenu

**Code (TODO):**
```dart
void _deleteContenu(
	BuildContext context, 
	String idContenu) {
  showDialog(
	context: context,
	builder: (context) => AlertDialog(
	  title: const Text('Supprimer ce contenu ?'),
	  content: const Text('Cette action est irréversible'),
	  actions: [
		TextButton(
		  onPressed: () => Navigator.pop(context),
		  child: const Text('Annuler'),
		),
		TextButton(
		  onPressed: () async {
			Navigator.pop(context);

			try {
			  // TODO: Appeler l'API de suppression
			  await ref.read(coursNotifierProvider.notifier)
				  .supprimerContenu(
					idCours: widget.idCours,
					idModule: widget.idModule,
					idContenu: idContenu,
				  );

			  // Refresh automatique via Riverpod
			  if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
				  const SnackBar(content: Text('Contenu supprimé')),
				);
			  }
			} catch (e) {
			  if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
				  SnackBar(content: Text('Erreur: $e')),
				);
			  }
			}
		  },
		  child: const Text('Supprimer',
			  style: TextStyle(color: _AppColors.danger)),
		),
	  ],
	),
  );
}
```

---

## Structure Complète d'une Session Utilisateur

```
1️⃣  Utilisateur ouvre l'app
	├─ Liste des cours affichée
	└─ Chaque cours a un card "Voir le cours"

2️⃣  Utilisateur clique "Voir le cours"
	├─ Navigator.push(CoursDetailScreen)
	├─ Page unique affichée avec:
	│  ├─ Titre + Description du cours
	│  ├─ Statistiques (3 modules, 8 contenus)
	│  └─ Liste des modules (tous fermés initialement)
	│
	└─ État: _expandedModules = {}

3️⃣  Utilisateur clique sur "Module 1"
	├─ Animation ▶ → ▼
	├─ Chargement des contenus du module 1
	├─ Affichage de 3 contenus:
	│  ├─ 📹 Vidéo (avec bouton [Lancer])
	│  ├─ 📝 Texte (avec bouton [Voir])
	│  └─ 📄 Document (avec menu ⋮)
	│
	└─ État: _expandedModules = {"mod1": true}

4️⃣  Utilisateur clique "Voir" sur le texte
	├─ DialogBox s'ouvre
	├─ Affichage du texte complet
	├─ Utilisateur ferme le dialog
	└─ Retour à la liste des contenus

5️⃣  Utilisateur clique sur "Module 2"
	├─ "Module 1" reste ouvert (possible!)
	├─ "Module 2" s'ouvre aussi
	├─ Les deux affichent leurs contenus
	│
	└─ État: _expandedModules = {"mod1": true, "mod2": true}

6️⃣  Utilisateur scroll pour voir "Module 3"
	├─ Scroll fluide (pas de changement de page)
	├─ Voit Module 3 fermé (▶)
	└─ Peut le cliquer pour l'ouvrir

7️⃣  Utilisateur quitte la page
	├─ Navigator.pop()
	└─ Retour à la liste des cours
```

---

## Gestion des États de Chargement

### Loading State

```dart
// Quand contenusProvider charge les données:
contenusAsync.when(
  loading: () => Container(
	padding: const EdgeInsets.all(20),
	child: const CircularProgressIndicator(strokeWidth: 2),
  ),
  // ...
)
```

**UI Affichée:**
```
▼ Module 1
  [Loading spinner...]
```

---

### Error State

```dart
contenusAsync.when(
  error: (err, _) => Container(
	padding: const EdgeInsets.all(16),
	child: Text(
	  'Erreur: $err',
	  style: GoogleFonts.dmSans(
		fontSize: 11,
		color: _AppColors.danger,
	  ),
	),
  ),
  // ...
)
```

**UI Affichée:**
```
▼ Module 1
  ❌ Erreur: Network timeout
```

---

### Empty State

```dart
if (contenus.isEmpty) {
  return Center(
	child: Column(
	  children: [
		Container(
		  width: 48,
		  height: 48,
		  decoration: BoxDecoration(
			color: _AppColors.statBlue,
			borderRadius: BorderRadius.circular(12),
		  ),
		  child: const Icon(
			Icons.description_outlined,
			size: 24,
			color: _AppColors.statBlueText,
		  ),
		),
		const SizedBox(height: 8),
		Text('Aucun contenu'),
		Text('Ajoutez du contenu à ce module'),
	  ],
	),
  );
}
```

**UI Affichée:**
```
▼ Module 1
  📋
  Aucun contenu
  Ajoutez du contenu à ce module
```

---

## Providers Riverpod Utilisés

### 1. modulesProvider

```dart
// Charge les modules d'un cours
final modulesAsync = ref.watch(modulesProvider(widget.idCours));

modulesAsync.when(
  data: (modules) => ListView.builder(
	itemCount: modules.length,
	itemBuilder: (context, index) {
	  final module = modules[index];
	  return _ModuleExpansionCard(...);
	},
  ),
  loading: () => CircularProgressIndicator(),
  error: (err, _) => ErrorWidget(),
)
```

---

### 2. contenusProvider

```dart
// Charge les contenus d'un module
final contenusAsync = ref.watch(
  contenusProvider((
	idCours: widget.idCours,
	idModule: idModule,
  )),
);

contenusAsync.when(
  data: (contenus) => ListView.builder(...),
  loading: () => CircularProgressIndicator(),
  error: (err, _) => ErrorWidget(),
)
```

---

### 3. coursNotifierProvider

```dart
// Pour les mutations
await ref.read(coursNotifierProvider.notifier).creerModule(
  idCours: widget.idCours,
  titreModule: titre,
  descriptionModule: desc,
);

// Après la mutation, modulesProvider est invalidé automatiquement
// et recharge les données
```

---

## Tests Recommandés

### Test 1: Expansion/Collapse
```dart
testWidgets('Module should expand and collapse', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());

  // Trouver le module
  final module1 = find.text('Module 1');
  expect(module1, findsOneWidget);

  // Tap pour étendre
  await tester.tap(module1);
  await tester.pumpAndSettle();

  // Vérifier que les contenus sont affichés
  expect(find.text('📹 Vidéo 1'), findsWidgets);
});
```

---

### Test 2: Affichage des Contenus
```dart
testWidgets('Contents should load on module expand', 
	(WidgetTester tester) async {
  // Expand un module
  // Vérifier que le provider est appelé
  // Vérifier que les contenus s'affichent
});
```

---

### Test 3: Actions sur Contenus
```dart
testWidgets('Video button should launch video', 
	(WidgetTester tester) async {
  // Tap sur le bouton [Lancer]
  // Vérifier que _launchVideo() est appelé
});
```

---

## Architecture Riverpod

```
┌─────────────────────────────────────┐
│   CoursDetailScreen                 │
│   ├─ modulesProvider(idCours)       │
│   │  └─ Liste des modules           │
│   │                                 │
│   └─ Pour chaque module:            │
│      └─ _ModuleExpansionCard        │
│         └─ contenusProvider(...)    │
│            └─ Liste des contenus    │
│                                     │
└─────────────────────────────────────┘
		↓ Mutations
┌─────────────────────────────────────┐
│ coursNotifierProvider               │
├─ creerModule()                      │
├─ ajouterContenu()                   │
└─ supprimerContenu()                 │
		↓ Invalidate
  Refresh des providers
```

---

## Troubleshooting

### Problème: Module ne s'étend pas

**Vérifier:**
1. `_expandedModules` est bien initialisé dans `initState()`
2. `setState()` est appelé au tap
3. Le `onExpand` callback est connecté

---

### Problème: Contenus ne s'affichent pas

**Vérifier:**
1. `contenusProvider` retourne bien les données
2. L'état `isExpanded` est `true`
3. Le provider n'est pas en erreur

---

### Problème: Animations saccadées

**Vérifier:**
1. La `Duration` de `AnimatedRotation` n'est pas trop courte
2. Pas de calculs lourds dans le build
3. Pas de rebuild inutiles

---

## Performance Tips

1. **Utiliser `shrinkWrap: true`** sur les ListView imbriquées
2. **Utiliser `physics: NeverScrollableScrollPhysics()`** quand imbriqué
3. **Lazy load** les contenus au click (déjà implémenté)
4. **Limiter** le nombre de modules visibles à la fois
5. **Cache** les contenus chargés

---

**Prêt à coder!** 🚀
