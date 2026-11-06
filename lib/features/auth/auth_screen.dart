import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile_selection/profile_selection_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _handleAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showError('Completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      // Si llega aquí, Firebase ya guardó la sesión. 
      // El SessionChecker de main.dart se activará automáticamente, 
      // pero forzamos la navegación por fluidez.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Ocurrió un error';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Correo o contraseña incorrectos';
      } else if (e.code == 'email-already-in-use') {
        message = 'Este correo ya está registrado';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña debe tener al menos 6 caracteres';
      }
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A18),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.psychology_outlined, size: 72, color: Color(0xFF7568FF)),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Inicia sesión para acceder a tus perfiles' : 'Regístrate para comenzar a usar PsyCase',
                style: const TextStyle(color: Color(0xFF9AA8C3), fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(color: Color(0xFF71809D)),
                  filled: true,
                  fillColor: Color(0xFF101C31),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF25365B))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF7568FF), width: 2)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: Color(0xFF71809D)),
                  filled: true,
                  fillColor: Color(0xFF101C31),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF25365B))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF7568FF), width: 2)),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7568FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? '¿No tienes cuenta? Regístrate aquí' : '¿Ya tienes cuenta? Inicia sesión',
                  style: const TextStyle(color: Color(0xFF7568FF), fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}