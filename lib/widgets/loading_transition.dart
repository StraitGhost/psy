// lib/widgets/loading_transition.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LoadingTransition extends StatefulWidget {
  final Widget child;
  final String message;

  const LoadingTransition({
    super.key,
    required this.child,
    this.message = 'Cargando...',
  });

  @override
  State<LoadingTransition> createState() => _LoadingTransitionState();
}

class _LoadingTransitionState extends State<LoadingTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack)),
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => widget.child,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic, 
              );
              
              return FadeTransition(
                opacity: curvedAnimation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      // ✅ MEJORADO: Fondo dinámico del agente
      backgroundColor: AppColors.background,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            // ✅ MEJORADO: Fondo con gradiente del agente
            Container(
              width: screenWidth,
              height: screenHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.surface,
                    AppColors.background,
                  ],
                ),
              ),
            ),
            
            // ✅ MEJORADO: Efectos de brillo con colores del agente
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),

            // Contenido centrado
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ MEJORADO: Logo con gradiente del agente
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: AppColors.textOnPrimary,
                            size: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Texto PsyCase
                      Text(
                        'PsyCase',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Simulador de Psicopatología',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 60),
                      
                      // ✅ MEJORADO: Loading spinner con color del agente
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ✅ MEJORADO: Mensaje con fondo del agente
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}