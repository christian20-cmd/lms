import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/enseignant_remote_datasource.dart';
import 'package:LMS/features/auth/presentation/providers/auth_provider.dart';

final enseignantDatasourceProvider = Provider((ref) {
  return EnseignantRemoteDatasource(ref.read(dioProvider));
});


// ── Notifications non lues ──
final notificationsNonLuesProvider = FutureProvider<int>((ref) async {
  final datasource = ref.read(enseignantDatasourceProvider);
  final data = await datasource.compterNonLues();
  return data['nonLues'] ?? 0;
});

// ── Profil ──
final profilEnseignantProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.read(enseignantDatasourceProvider);
  return datasource.getMonProfil();
});