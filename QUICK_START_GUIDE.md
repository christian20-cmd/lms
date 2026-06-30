# 🚀 Guide Rapide - Détails Cours Unifié

## TL;DR (Version Courte)

**Changement:** L'affichage des détails d'un cours passe d'une **navigation multi-page** à une **page unique avec expansion**.

```
❌ Avant: Click module → Navigate to new page
✅ Après: Click module → Expand in same page
```

---

## 📝 Fichier Principal

**`lms_app/lib/features/enseignant/presentation/screens/cours_detail_screen.dart`**

### Changements:
1. ✅ `CoursDetailScreen` - Affiche maintenant tout (modules + contenus)
2. ✅ `_ModuleExpansionCard` - Nouveau widget pour expansion
3. ⚠️ `ModuleDetailScreen` - Déprécié (conservé pour compatibilité)

---

## 💻 Comment Ça Marche

### 1. État Local
```dart
class _CoursDetailScreenState extends ConsumerState<CoursDetailScreen> {
  late Map<String, bool> _expandedModules;  // Suivi de quel module est ouvert

  @override
  void initState() {
	_expandedModules = {};
  }
}
```

### 2. Rendering des Modules
```dart
// Au lieu de:
// GestureDetector(onTap: () => Navigator.push(ModuleDetailScreen))

// On fait:
GestureDetector(
  onTap: () => setState(() {
	_expandedModules[idModule] = !isExpanded;
  }),
  child: _ModuleExpansionCard(isExpanded: isExpanded)
)
```

### 3. Affichage Conditionnel des Contenus
```dart
// Dans _ModuleExpansionCard:
if (isExpanded) {
  // Affiche les contenus
  contenusAsync.when(
	loading: () => CircularProgressIndicator(),
	error: (err, _) => ErrorWidget(),
	data: (contenus) => ContenutListView(),
  )
}
```

---

## 🎨 Structure Visuelle

```
CoursDetailScreen
│
├─ Course Header (titre, description)
├─ Statistics (modules count, content count)
│
└─ Modules List
   ├─ _ModuleExpansionCard #1
   │  ├─ Header (clickable)
   │  └─ [If Expanded] Content List
   │
   ├─ _ModuleExpansionCard #2
   │
   └─ _ModuleExpansionCard #N
```

---

## 📲 Interactions Principales

| Action | Avant | Après |
|--------|-------|-------|
| Voir un module | Click → New Screen | Click → Expand |
| Voir contents | Navigate + Wait | Instant (on expand) |
| Voir plusieurs modules | Navigate back/forth | Multiple open |
| Actions sur contenus | Separate page menu | Inline menu |

---

## 🔧 To Do Items

```dart
// 1. Lancer vidéo
void _launchVideo(BuildContext context, String url) {
  // TODO: Implement with url_launcher or video_player
}

// 2. Éditer contenu
void _editContenu(...) {
  // TODO: Show edit form
}

// 3. Supprimer contenu
void _deleteContenu(...) {
  // TODO: Call API + refresh
}
```

---

## 🧪 Test de Base

```dart
// 1. Vérifier l'expansion
void testModuleExpansion() {
  // Tap sur module → doit se développer
  // Tap à nouveau → doit se réduire
}

// 2. Vérifier le chargement des contenus
void testContentLoading() {
  // Expand un module → doit montrer loader
  // Puis les contenus
}

// 3. Vérifier les actions
void testContentActions() {
  // Click "Lancer" → doit lancer vidéo
  // Click "Voir" → doit montrer dialog
}
```

---

## 🔍 Debugging Tips

### 1. Vérifier l'état d'expansion
```dart
print(_expandedModules);  // {mod1: true, mod2: false}
```

### 2. Vérifier le chargement des contenus
```dart
// Dans ConsumerWidget:
final contenusAsync = ref.watch(contenusProvider(...));
contenusAsync.when(
  loading: () => print('Loading...'),
  error: (err, st) => print('Error: $err'),
  data: (data) => print('Loaded: ${data.length} items'),
);
```

### 3. Vérifier les animations
```dart
// AnimatedRotation devrait tourner quand on expand/collapse
// Si ça ne tourne pas, check la Duration et turns parameter
```

---

## 📦 Providers Utilisés

```dart
// Pour charger les modules
ref.watch(modulesProvider(idCours))

// Pour charger les contenus d'un module
ref.watch(contenusProvider((idCours: idCours, idModule: idModule)))

// Pour les mutations (créer, supprimer)
ref.read(coursNotifierProvider.notifier)
```

---

## ⚠️ Breaking Changes

### Code Utilisant ModuleDetailScreen

**AVANT:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
	builder: (_) => ModuleDetailScreen(idCours, idModule, titre),
  ),
);
```

**APRÈS:**
```dart
// Le module est directement visible et cliquable dans CoursDetailScreen
// Pas besoin de NavigatorPush
// L'utilisateur voit juste l'expansion en lieu et place
```

---

## 🎯 Migration Checklist

- [ ] Test expansion/collapse
- [ ] Test contenus affichés
- [ ] Test actions sur contenus
- [ ] Test avec plusieurs modules
- [ ] Test scroll performance
- [ ] Test sur différents écrans
- [ ] Compléter les TODO items
- [ ] Supprimer ModuleDetailScreen quand plus utilisé

---

## 📚 Ressources

| Document | Contenu |
|----------|---------|
| `REFACTORISATION_DETAILCOURS.md` | Vue d'ensemble complète |
| `COURS_DETAIL_REFACTOR.md` | Documentation technique |
| `COURS_DETAIL_USAGE_EXAMPLE.dart` | Exemples de code |
| `COMPARAISON_VISUELLE.txt` | Avant/Après visuel |

---

## 💬 Questions Fréquentes

**Q: Pourquoi pas de navigation?**
A: Parce qu'on peut avoir plusieurs modules ouverts simultanément et c'est plus fluide

**Q: Comment persister l'état?**
A: L'état `_expandedModules` est conservé tant que l'utilisateur est sur la page

**Q: Ça va ralentir?**
A: Non, les contenus se chargent on-demand (au click sur le module)

**Q: Que faire si je dois ajouter une page pour un module?**
A: Créer une nouvelle page spécialisée, mais pas remplacer cette architecture

---

## 🚀 Déploiement

1. **Tester** localement l'expansion/collapse
2. **Compiler** en release mode
3. **Vérifier** les performances
4. **Déployer** progressivement
5. **Monitor** les crashes/errors

---

**Status:** ✅ Ready to Use
**Version:** 1.0
**Last Updated:** 2024
