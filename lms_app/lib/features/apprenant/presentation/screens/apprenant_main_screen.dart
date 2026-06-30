import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LMS/features/auth/presentation/providers/auth_provider.dart';
import 'package:LMS/features/apprenant/providers/apprenant_provider.dart';
import 'dashboard_apprenant_screen.dart';
import 'mes_cours_apprenant_screen.dart';
import 'catalogue_cours_screen.dart';
import 'profil_apprenant_screen.dart';

const String _kBaseUrl = 'http://localhost:3000';

class ApprenantMainScreen extends ConsumerStatefulWidget {
  const ApprenantMainScreen({super.key});

  @override
  ConsumerState<ApprenantMainScreen> createState() => _ApprenantMainScreenState();
}

class _ApprenantMainScreenState extends ConsumerState<ApprenantMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardApprenantScreen(),
    MesCoursApprenantScreen(),
    CatalogueCoursScreen(),
    ProfilApprenantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profilAsync = ref.watch(profilApprenantProvider);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Mes cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explorer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      drawer: SafeArea(
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  '${authState.user?.prenomUser ?? ''} ${authState.user?.nomUser ?? ''}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                accountEmail: Text(
                  authState.user?.emailUser ?? 'email@example.com',
                  style: GoogleFonts.outfit(),
                ),
                currentAccountPicture: profilAsync.maybeWhen(
                  data: (profil) {
                    final photo = profil['photoProfilUser'] as String?;
                    final nom = profil['nomUser'] as String? ?? 'A';
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: photo != null
                          ? NetworkImage('$_kBaseUrl$photo') as ImageProvider
                          : null,
                      child: photo == null
                          ? Text(
                              nom.isNotEmpty ? nom[0].toUpperCase() : 'A',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            )
                          : null,
                    );
                  },
                  orElse: () => CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      (authState.user?.nomUser ?? 'A').isNotEmpty
                          ? (authState.user?.nomUser ?? 'A')[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                decoration: const BoxDecoration(color: Color(0xFF3B8DDD)),
              ),
              _DrawerItem(
                icon: Icons.dashboard,
                label: 'Tableau de bord',
                isActive: _selectedIndex == 0,
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.school,
                label: 'Mes cours',
                isActive: _selectedIndex == 1,
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.explore,
                label: 'Explorer',
                isActive: _selectedIndex == 2,
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.person,
                label: 'Profil',
                isActive: _selectedIndex == 3,
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              _DrawerItem(
                icon: Icons.notifications,
                label: 'Notifications',
                isActive: false,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/apprenant/notifications');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text('Déconnexion', style: GoogleFonts.outfit(color: Colors.red)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Déconnexion', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      content: Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: GoogleFonts.outfit()),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Déconnecter', style: GoogleFonts.outfit(color: Colors.red))),
                      ],
                    ),
                  ) ?? false;

                  if (confirm && context.mounted) {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item de drawer avec état actif visuel ──
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B8DDD).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? const Color(0xFF3B8DDD) : null),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            color: isActive ? const Color(0xFF3B8DDD) : null,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}