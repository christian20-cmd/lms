# Refactorisation du Détail du Cours - Affichage Unifié

## Objectif
Consolider l'affichage des détails d'un cours, des modules et du contenu en une **seule page** avec expansion dynamique, au lieu de naviguer entre plusieurs écrans.

## Changements Principaux

### Avant (Ancienne Architecture)
- **CoursDetailScreen** → Affiche la liste des modules
- Clic sur un module → **ModuleDetailScreen** → Affiche la liste des contenus
- Navigation entre écrans (stack navigation)

### Après (Nouvelle Architecture)
- **CoursDetailScreen** → Affiche tous les modules avec contenus intégrés
- Clic sur un module → **Expansion dans la même page**
- Les contenus s'affichent en accordéon dans chaque card de module
- **Aucune navigation d'écran** - tout est sur une seule page

## Composants

### 1. CoursDetailScreen (Modifié)
**Localisation:** `lms_app/lib/features/enseignant/presentation/screens/cours_detail_screen.dart` (lignes 23-331)

**Changements:**
- ✅ Ajout de `initState()` avec gestion d'état local `_expandedModules`
- ✅ Remplacement de la liste simple par `_ModuleExpansionCard`
- ✅ Suppression de `_navigateToModuleDetails()` (plus de navigation)
- ✅ Les modules sont maintenant des cartes expansibles

**État Local:**
```dart
late Map<String, bool> _expandedModules;  // Suivi de l'état d'expansion par idModule
```

### 2. Nouveau Widget: _ModuleExpansionCard
**Localisation:** `lms_app/lib/features/enseignant/presentation/screens/cours_detail_screen.dart` (lignes 333-666)

**Responsabilités:**
- ✅ Affichage de l'en-tête du module (titre, description, statut)
- ✅ Icône d'expansion animée (rotation 0° → 180°)
- ✅ Chargement dynamique du contenu lors de l'expansion
- ✅ Affichage de la liste des contenus avec:
  - **Icône du type** (Vidéo, Document, Texte, Image)
  - **Titre et type du contenu**
  - **Actions:**
	- 📹 Lancer la vidéo (avec `_launchVideo()`)
	- 👁️ Voir le texte (avec `_showTextContent()`)
	- ⋮ Menu contextuel (Modifier, Supprimer)

**Features:**
- Animation d'expansion fluide (200ms)
- Chargement asynchrone des contenus
- Gestion d'erreur et état vide

### 3. Ancien ModuleDetailScreen
**Status:** ⚠️ **DÉPRÉCIÉ** 
- Conservé pour compatibilité descendante
- Marqué avec `@Deprecated('Use CoursDetailScreenUnified instead')`
- À supprimer une fois que d'autres parties du code utilisant `ModuleDetailScreen` sont migrées

## Structure de l'Affichage

```
┌─ CoursDetailScreen (une page)
│
├─ Infos du cours
│  └─ [Titre, Description]
│
├─ Statistiques
│  ├─ Nombre de modules
│  └─ Nombre de contenus
│
└─ Liste des Modules (dynamique)
   │
   ├─ _ModuleExpansionCard (Module 1) [Expandable]
   │  ├─ En-tête (titre, statut) 
   │  └─ Contenu (si expanded)
   │     └─ Liste des contenus
   │        ├─ Contenu 1 (Vidéo)
   │        │  ├─ Titre & Type
   │        │  ├─ Bouton Lancer
   │        │  └─ Menu (Modifier, Supprimer)
   │        │
   │        ├─ Contenu 2 (Texte)
   │        │  ├─ Titre & Type
   │        │  ├─ Bouton Voir
   │        │  └─ Menu (Modifier, Supprimer)
   │        │
   │        └─ Contenu 3 (Document)
   │           ├─ Titre & Type
   │           └─ Menu (Modifier, Supprimer)
   │
   ├─ _ModuleExpansionCard (Module 2) [Expandable]
   │  └─ ...
   │
   └─ _ModuleExpansionCard (Module N) [Expandable]
	  └─ ...
```

## Fonctionnalités

### ✅ Expansion Dynamique
```dart
GestureDetector(
  onTap: onExpand,  // Toggle expansion state
  child: // Module header
)
```

### ✅ Affichage des Contenus
- Basé sur `contenusProvider` (avec paramètres idCours et idModule)
- Affichage conditionnel selon le type:
  - **VIDEO**: Bouton "Lancer" si `lienExterne` existe
  - **TEXTE**: Bouton "Voir" si `texteContenu` existe
  - **DOCUMENT/IMAGE**: Affichage du type avec menu

### ✅ Aperçu du Contenu
```dart
String _getContentPreview(String type, Map<String, dynamic> contenu)
```
- Affiche les 50 premiers caractères du texte
- Affiche le type de contenu pour les autres types

### ✅ Actions sur les Contenus
1. **_launchVideo()** - Lancer une vidéo
   - Actuellement: Affiche un SnackBar
   - À implémenter: Utiliser `url_launcher` ou `video_player`

2. **_showTextContent()** - Afficher le texte en dialogue
   - Ouvre un AlertDialog avec le contenu complet
   - Fermeture avec bouton "Fermer"

3. **_editContenu()** - Éditer un contenu
   - TODO: Implémenter la modification

4. **_deleteContenu()** - Supprimer un contenu
   - Confirmation avec AlertDialog
   - TODO: Implémenter la suppression API

## Providers Utilisés

### 1. `modulesProvider(String idCours)`
- Charge la liste des modules d'un cours
- Utilisé par CoursDetailScreen

### 2. `contenusProvider((String idCours, String idModule))`
- Charge la liste des contenus d'un module
- Utilisé par _ModuleExpansionCard (rechargé à chaque expansion)

## Avantages

✅ **UX Amélioré**
- Pas de changement de page brusque
- Visualisation complète en une page
- Navigation plus fluide

✅ **Performance**
- Contenus chargés seulement lors de l'expansion
- Moins de transitions d'écran

✅ **Maintenance**
- Logique centralisée dans un seul écran
- Moins de code dupliqué

✅ **Accessibilité**
- Gestion d'état simple et intuitive
- Animations claires

## Points à Implémenter

⚠️ **TODO:**
1. `_launchVideo()` - Intégrer `url_launcher` ou `video_player`
2. `_editContenu()` - Afficher un formulaire de modification
3. `_deleteContenu()` - Appeler l'API de suppression
4. Gestion des fichiers PDF/Documents
5. Gestion des images (affichage galerie)

## Tests Recommandés

```dart
// Test: Expansion/Collapse de modules
void testModuleExpansion() {
  // Vérifier que l'état change au tap
  // Vérifier que les contenus se chargent
}

// Test: Navigation vers contenu
void testContentActions() {
  // Vérifier que les boutons d'action fonctionnent
  // Vérifier que les dialogs s'ouvrent correctement
}
```

## Backward Compatibility

L'ancien `ModuleDetailScreen` est conservé mais déprécié. 
Il permettra une migration progressive des autres parties du code.

Migration path:
```
// Avant
Navigator.push(..., ModuleDetailScreen(...));

// Après
// Supprimer l'appel Navigator.push
// Le module est accessible directement en expandant dans CoursDetailScreen
```

## Fichiers Modifiés

- `cours_detail_screen.dart` ✅
  - CoursDetailScreen (modifié)
  - _ModuleExpansionCard (nouveau)
  - ModuleDetailScreen (déprécié)
  - _ModuleFormSheet (inchangé)
  - _ContenuFormSheet (inchangé)
  - Helpers (inchangés)
