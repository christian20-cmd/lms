# Résolution des Problèmes de File Picker et OpenGL

## Problèmes Détectés

Les erreurs suivantes ont été identifiées dans les journaux logcat:

```
D/FilePickerDelegate(32497): [MultiFilePick] File #0 - URI: /storage/emulated/0/Xender/other/COMMUNIQUÉ.pdf
E/BpSurfaceComposerClient(32497): Failed to transact (-1)
```

**Causes racine:**
1. ❌ Permissions d'accès aux fichiers manquantes dans `AndroidManifest.xml`
2. ❌ Utilisation de `withReadStream: true` sans gestion appropriée du flux
3. ❌ Pas de validation du chemin du fichier après sélection
4. ❌ Gestion incohérente des fichiers dans les deux implémentations

---

## Solutions Appliquées

### 1. **Ajout des Permissions Android** ✅
**Fichier:** `lms_app/android/app/src/main/AndroidManifest.xml`

Ajout des permissions essentielles:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

Ces permissions permettent à l'application d'accéder aux fichiers du système de fichiers externe.

---

### 2. **Optimisation du File Picker - cours_detail_screen.dart** ✅
**Fichier:** `lms_app/lib/features/enseignant/presentation/screens/cours_detail_screen.dart`

**Changements:**
- ✅ `withReadStream: true` → `withReadStream: false` (pas de besoin de flux)
- ✅ Ajout de validation du chemin du fichier
- ✅ Gestion explicite des cas d'erreur (fichier null ou vide)
- ✅ Vérification que `file.path` n'est pas null ou vide

**Raison:** Réduire les allocations de ressources et éviter les fuites mémoire.

---

### 3. **Optimisation du File Picker - module_management_drawer.dart** ✅
**Fichier:** `lms_app/lib/features/enseignant/presentation/widgets/module_management_drawer.dart`

**Changements:**
- ✅ Ajout de `withData: false` et `withReadStream: false`
- ✅ Validation des chemins récupérés (filtrage des chaînes vides)
- ✅ Vérification que `result.paths` n'est pas null et n'est pas vide
- ✅ Meilleure gestion des erreurs

**Raison:** Assurer que seuls des fichiers valides sont traités.

---

## Configuration Supplémentaire Recommandée (Android 6.0+)

Pour les appareils Android 6.0 (API 23) et supérieurs, vous devez implémenter le **Runtime Permissions** dans votre code Flutter:

### Option 1: Utiliser le plugin `permission_handler`

Ajoutez à `pubspec.yaml`:
```yaml
permission_handler: ^11.4.4
```

Implémentez dans vos écrans:
```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestFilePermissions() async {
  final status = await Permission.storage.request();
  return status.isGranted;
}

// Avant d'appeler FilePicker:
if (await requestFilePermissions()) {
  final result = await FilePicker.platform.pickFiles(...);
}
```

### Option 2: Configuration dans build.gradle.kts

Ajoutez à `lms_app/android/app/build.gradle.kts`:
```kotlin
android {
	// ... autres configurations ...

	defaultConfig {
		// ...
		targetSdk = 34  // Ou la version actuelle
	}
}
```

---

## Commandes de Vérification

### Vérifier la compilation Dart:
```bash
cd lms_app
flutter analyze
```

### Tester sur émulateur/appareil:
```bash
flutter run
```

### Voir les journaux détaillés:
```bash
flutter logs
```

---

## Notes Importantes

1. **Erreur OpenGL `Failed to transact (-1)`:**
   - Généralement causée par l'accès prématuré aux fichiers avant que le système de fichiers soit prêt
   - Résolu par l'utilisation de `withReadStream: false`

2. **Gestion des fichiers PDF:**
   - L'application utilise `flutter_pdfview` et `open_filex` pour afficher les fichiers
   - Assurez-vous que le chemin du fichier est valide avant de passer à ces widgets

3. **Chemins d'accès spéciaux:**
   - `/storage/emulated/0/Xender/` : Dossier secondaire (application de transfert de fichiers)
   - Les permissions doivent être accordées pour accéder à ces emplacements

---

## Checklist de Vérification

- [ ] AndroidManifest.xml mis à jour avec les permissions
- [ ] File picker en cours_detail_screen.dart optimisé
- [ ] File picker en module_management_drawer.dart optimisé
- [ ] `flutter pub get` exécuté sans erreurs
- [ ] Teste sur un appareil réel ou émulateur
- [ ] Aucune erreur OpenGL dans les journaux logcat

---

## Besoin d'Aide Supplémentaire?

Si les erreurs persistent:
1. Vérifiez la cible SDK Android (targetSdk doit être 31 ou plus)
2. Assurez-vous que les permissions sont accordées dans les paramètres de l'appareil
3. Nettoyez le cache: `flutter clean` puis `flutter pub get`
4. Reconstruisez: `flutter run --release`
