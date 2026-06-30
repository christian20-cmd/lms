// lib/core/permissions/file_permissions.dart

import 'dart:io';
import 'package:flutter/material.dart';

/// Gestionnaire des permissions d'accès aux fichiers
/// Simplifié pour Android et iOS
class FilePermissionsManager {
  /// Demander les permissions d'accès aux fichiers
  /// Retourne true si les permissions sont accordées
  static Future<bool> requestFileAccess() async {
	if (Platform.isAndroid) {
	  // Sur Android 6.0+, les permissions runtime sont gérées automatiquement
	  // par file_picker. Cependant, pour plus de contrôle:
	  return true; // file_picker gère les permissions
	} else if (Platform.isIOS) {
	  // Sur iOS, les permissions sont déclarées dans Info.plist
	  // et gérées automatiquement
	  return true;
	}
	return false;
  }

  /// Vérifier si le chemin du fichier est valide
  static bool isValidFilePath(String? path) {
	if (path == null || path.isEmpty) return false;

	final file = File(path);
	return file.existsSync();
  }

  /// Vérifier les permissions et afficher un snackbar si nécessaire
  static Future<void> checkAndRequestPermissions(
	BuildContext context, {
	required Function() onGranted,
	required Function() onDenied,
  }) async {
	try {
	  final hasPermission = await requestFileAccess();

	  if (hasPermission) {
		onGranted();
	  } else {
		onDenied();
		if (context.mounted) {
		  ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(
			  content: Text(
				'Les permissions d\'accès aux fichiers sont nécessaires',
			  ),
			  duration: Duration(seconds: 3),
			),
		  );
		}
	  }
	} catch (e) {
	  onDenied();
	  if (context.mounted) {
		ScaffoldMessenger.of(context).showSnackBar(
		  SnackBar(
			content: Text('Erreur : $e'),
			duration: const Duration(seconds: 3),
		  ),
		);
	  }
	}
  }
}
