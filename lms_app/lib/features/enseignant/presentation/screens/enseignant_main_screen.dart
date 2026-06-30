import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';
import 'mes_cours_screen.dart';
import 'profil_enseignant_screen.dart';

final enseignantTabProvider = StateProvider<int>((ref) => 0);

class EnseignantMainScreen extends ConsumerWidget {
  const EnseignantMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(enseignantTabProvider);

    final screens = const [
      DashboardScreen(),
      MesCoursScreen(),
      ProfilEnseignantScreen(),
    ];

    return Scaffold(
      // ❌ plus de blanc
      body: screens[currentTab],

      bottomNavigationBar: SafeArea(
        child: Container(
          
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                ref: ref,
                index: 0,
                currentIndex: currentTab,
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Dashboard',
              ),
              _buildNavItem(
                ref: ref,
                index: 1,
                currentIndex: currentTab,
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Mes Cours',
              ),
              _buildNavItem(
                ref: ref,
                index: 2,
                currentIndex: currentTab,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required WidgetRef ref,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => ref.read(enseignantTabProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? Colors.white : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}