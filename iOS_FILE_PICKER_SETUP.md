# Configuration iOS pour File Picker (Optionnel)

Si vous ciblez iOS 11+, vous devez ajouter des clés à `ios/Runner/Info.plist`:

```xml
<!-- Accès aux fichiers (Photos Library, Documents) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>L'application a besoin d'accéder à votre bibliothèque de photos pour sélectionner des images.</string>

<key>NSDocumentsFolderAccessDescription</key>
<string>L'application a besoin d'accéder à vos documents pour importer des fichiers.</string>

<key>UIFileSharingEnabled</key>
<true/>
```

## Emplacement du fichier:
`lms_app/ios/Runner/Info.plist`

## Exemple complet pour file_picker sur iOS:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- ... autres clés ... -->

	<!-- File Picker Permissions -->
	<key>NSPhotoLibraryUsageDescription</key>
	<string>L'application a besoin d'accéder à votre bibliothèque de photos pour sélectionner des images.</string>

	<key>NSDocumentsFolderAccessDescription</key>
	<string>L'application a besoin d'accéder à vos documents pour importer des fichiers.</string>

	<key>UIFileSharingEnabled</key>
	<true/>
	<key>LSSupportsOpeningDocumentsInPlace</key>
	<true/>

	<!-- ... reste du fichier ... -->
</dict>
</plist>
```

## Vérification:
```bash
flutter run  # Testera automatiquement iOS si vous êtes sur un Mac
```
