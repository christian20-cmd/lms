import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    // Fade in général
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Scale logo — zoom depuis 0.3 avec rebond
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    // Slide up du texte
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Pulse continu sur le logo après apparition
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _startSequence() async {
    // Délai initial
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Fade + scale du logo simultanément
    _fadeController.forward();
    _scaleController.forward();

    // Slide du texte après le logo
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _slideController.forward();

    // Pulse infini après l'apparition
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _pulseController.repeat(reverse: true);

    // Attendre puis naviguer
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    _naviguer();
  }

  Future<void> _naviguer() async {
    // Fade out avant navigation
    _pulseController.stop();
    await _fadeController.reverse();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ── Logo avec scale + pulse ──
              ScaleTransition(
                scale: _scaleAnim,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/bgt.png',
                    width: 130,
                    height: 130,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Texte slide up ──
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _slideController.view,
                  
                ),
              ),

              const Spacer(),

              // ── Loader en bas ──
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _slideController.view,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}