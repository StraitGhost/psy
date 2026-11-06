import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_preferences.dart'; // ✅ NUEVO: Importar el cerebro de los temas
import 'features/profile_selection/profile_selection_screen.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';
import 'services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ NUEVO: Cargar preferencias de tema ANTES de ejecutar la app
  await ThemePreferences.instance.load();

  runApp(const PsyCaseApp());
}

class PsyCaseApp extends StatelessWidget {
  const PsyCaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ NUEVO: Escuchar cambios en el modo de tema y la paleta de colores
    // Esto reconstruye el MaterialApp al instante cuando el usuario cambia la configuración
    return ValueListenableBuilder<String>(
      valueListenable: ThemePreferences.instance.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: ThemePreferences.instance.colorPalette,
          builder: (context, palette, _) {
            return MaterialApp(
              title: 'PsyCase',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.current, // ✅ NUEVO: Usar el tema dinámico (ya no AppTheme.light())
              home: const SessionChecker(),
            );
          },
        );
      },
    );
  }
}

class SessionChecker extends StatefulWidget {
  const SessionChecker({super.key});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  bool _isLoading = true;
  Widget _nextScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // 1. PRIMERO: Verificamos si hay una CUENTA logueada en Firebase
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _nextScreen = const LoginScreen();
          _isLoading = false;
        });
      }
      return;
    }

    // 2. SEGUNDO: Si hay cuenta, verificamos si hay un PERFIL seleccionado
    final profile = await ProfileService.getCurrentProfile();
    
    if (mounted) {
      setState(() {
        if (profile != null) {
          _nextScreen = HomeScreen(profile: profile);
        } else {
          _nextScreen = const ProfileSelectionScreen();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050A18),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7568FF)),
        ),
      );
    }
    return _nextScreen;
  }
}